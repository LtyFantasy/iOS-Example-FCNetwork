//
//  FCNetworkManager.m
//  FCNetwork
//
//  Created by LeoLiu on 2019/12/23.
//  Copyright (c) 2019 ForestCocoon ltyfantasy@163.com. All rights reserved.

#import "FCNetworkManager.h"
#import "FCNetworkRequest.h"
#import "FCNetworkParser.h"
#import "FCNetworkError.h"
#import "FCNetworkInterceptor.h"
#import "FCNetworkCache.h"
#import "FCNetworkTask.h"
#import "FCNetworkResponse.h"

#import <AFNetworking/AFNetworking.h>

#pragma mark - Defines

#define FCWeakSelf                          autoreleasepool{} __weak typeof(self) weakSelf = self
#define FCStrongSelf                        autoreleasepool{} __strong typeof(self) self = weakSelf

// Log
#ifdef DEBUG

#define FCLog_Verbose(fmt, ...)             [FCNetworkLog logWithLevel:FCNetworkLogLevelVerbose filename:NULL method:NULL line:0 format:fmt, ##__VA_ARGS__]
#define FCLog_Warning(fmt, ...)             [FCNetworkLog logWithLevel:FCNetworkLogLevelWarning filename:NULL method:NULL line:0 format:fmt, ##__VA_ARGS__]
#define FCLog_Error(fmt, ...)               [FCNetworkLog logWithLevel:FCNetworkLogLevelError filename:__FILE__ method:__PRETTY_FUNCTION__ line:__LINE__ format:fmt, ##__VA_ARGS__]

#else

#define FCLog_Verbose(fmt, ...)
#define FCLog_Warning(fmt, ...)
#define FCLog_Error(fmt, ...)

#endif

typedef void (^FCNetworkTaskSuccessBlock) (NSURLSessionTask *task, id responseObject);
typedef void (^FCNetworkTaskFailureBlock) (NSURLSessionTask *task, NSError *error);



#pragma mark - Inner Class

static NSUInteger LogBlockLevel = FCNetworkLogLevelWarning;
@interface FCNetworkLog : NSObject

@end

@implementation FCNetworkLog

+ (void)logWithLevel:(FCNetworkLogLevel)level filename:(const char*)filename method:(const char*)method line:(int)line format:(NSString*)format,... {
 
    if (level < LogBlockLevel) {
        return;
    }
    
    NSString *formatString;
    va_list argList;
    va_start(argList, format);
    formatString = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    
    NSString *filenameString = nil;
    if (filename != NULL) {
        filenameString = [NSString stringWithCString:filename encoding:NSUTF8StringEncoding].lastPathComponent;
    }
    
    switch (level) {
        case FCNetworkLogLevelVerbose:
            NSLog(@"[FCNetwork Verbose] %@", formatString);
            break;
            
        case FCNetworkLogLevelWarning:
            NSLog(@"[- ! FCNetwork Warning ! -] %@", formatString);
            break;
            
        case FCNetworkLogLevelError:
            NSLog(@"[- !! FCNetwork Error !! -]\n\tfilename: %@(%d) %s\n\t%@", filenameString, line, method, formatString);
            break;
            
        default:
            break;
    }
}

@end

@interface FCNetworkSession : NSObject

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation FCNetworkSession

+ (instancetype)sessionWithSessionManager:(AFHTTPSessionManager*)sessionManager identifier:(NSString*)identifier {
    
    FCNetworkSession *obj = [FCNetworkSession new];
    obj.sessionManager = sessionManager;
    obj.identifier = identifier;
    obj.queue = dispatch_queue_create([[NSString stringWithFormat:@"com.ForestCocoon.FCNetwork.Session.%@", identifier] UTF8String], DISPATCH_QUEUE_SERIAL);
    return obj;
}

@end

@class FCNetworkGroupRequestTask;
@protocol FCNetworkGroupRequestTaskDelegate <NSObject>

@required
- (void)groupRequestTask:(FCNetworkGroupRequestTask*)task didCompleteWithSuccess:(BOOL)success;

@end

@interface FCNetworkGroupRequestTask : NSObject

@property (nonatomic, weak) id<FCNetworkGroupRequestTaskDelegate> delegate;

@property (nonatomic, strong) NSArray<FCNetworkRequest*> *requests;
@property (nonatomic, strong) NSMutableArray<FCNetworkSuccessResponse*> *successResponses;
@property (nonatomic, strong) FCNetworkErrorResponse *errorResponses;

@property (nonatomic, copy) FCNetworkGroupSuccessBlock successBlock;
@property (nonatomic, copy) FCNetworkGroupFailureBlock failureBlock;

@end

@implementation FCNetworkGroupRequestTask

- (instancetype)initWithRequests:(NSArray<FCNetworkRequest*>*)requests {
    
    if (self = [super init]) {
        _requests = requests;
        _successResponses = [NSMutableArray array];
    }
    return self;
}

- (void)addSuccessResponse:(FCNetworkSuccessResponse*)response forRequest:(FCNetworkRequest*)request {
    
    FCNetworkSuccessResponse *obj = [FCNetworkSuccessResponse new];
    obj.request = request;
    obj.responseObject = response;
    [_successResponses addObject:obj];
    
    if (_successResponses.count >= _requests.count && _successBlock) {
        
        _successBlock(_successResponses);
        if (_delegate && [_delegate respondsToSelector:@selector(groupRequestTask:didCompleteWithSuccess:)]) {
            [_delegate groupRequestTask:self didCompleteWithSuccess:YES];
        }
    }
}

- (void)addErrorResponse:(FCNetworkError*)error forRequest:(FCNetworkRequest*)request {
    
    FCNetworkErrorResponse *obj = [FCNetworkErrorResponse new];
    obj.request = request;
    obj.error = error;
    _errorResponses = obj;
    
    if (_failureBlock) {
        
        _failureBlock(obj);
        if (_delegate && [_delegate respondsToSelector:@selector(groupRequestTask:didCompleteWithSuccess:)]) {
            [_delegate groupRequestTask:self didCompleteWithSuccess:NO];
        }
    }
}

@end

#pragma mark - Main Class

@interface FCNetworkManager () <FCNetworkGroupRequestTaskDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString*, FCNetworkSession*> *sessionDict;
@property (nonatomic, strong) Class errorClass;
@property (nonatomic, strong) id<FCNetworkInterceptor> interceptor;
@property (nonatomic, strong) FCNetworkCache *cache;

@property (nonatomic, strong) NSMutableArray<FCNetworkGroupRequestTask*> *groupTasks;

@end

@implementation FCNetworkManager

#pragma mark - Init

+ (instancetype)manager {
    
    static FCNetworkManager *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [FCNetworkManager new];
    });
    return obj;
}

- (instancetype)init {
    
    if (self = [super init]) {
        [self dataInit];
    }
    
    return self;
}

- (void)dataInit {
    
    _sessionDict = [NSMutableDictionary dictionary];
    _cache = [FCNetworkCache defaultCache];
    _groupTasks = [NSMutableArray array];
}

#pragma mark - Data

- (void)setLogLevel:(FCNetworkLogLevel)level {
    LogBlockLevel = level;
}

- (void)setErrorClass:(Class)errorClass {
    if ([errorClass isSubclassOfClass:FCNetworkError.class]) {
        _errorClass = errorClass;
    }
}

- (void)setInterceptor:(id<FCNetworkInterceptor>)interceptor {
    if ([interceptor conformsToProtocol:@protocol(FCNetworkInterceptor)]) {
        _interceptor = interceptor;
    }
}

#pragma mark - Session

- (void)addSessionManager:(AFHTTPSessionManager*)sessionManager withIdentifier:(NSString*)identifier {
    
    if (!sessionManager || !identifier || identifier.length == 0) {
        return;
    }
    
    FCNetworkSession *session = _sessionDict[identifier];
    if (session) {
        session.sessionManager = sessionManager;
    }
    else {
        session = [FCNetworkSession sessionWithSessionManager:sessionManager identifier:identifier];
        _sessionDict[identifier] = session;
    }
}

- (void)removeSessionManagerWithIdentifier:(NSString*)identifier {
    
    if (!identifier) {
        return;
    }
    _sessionDict[identifier] = nil;
}

- (AFHTTPSessionManager*)sessionManagerWithIdentifier:(NSString*)identifier {
    
    if (!identifier) {
        return nil;
    }
    return _sessionDict[identifier].sessionManager;
}

- (FCNetworkSession*)sessionWithIdentifier:(NSString*)identifier {
    return _sessionDict[identifier];
}

#pragma mark - Request

- (FCNetworkTask*)sendRequest:(FCNetworkRequest*)request successBlock:(FCNetworkSuccessBlock)successBlock failureBlock:(FCNetworkFailureBlock)failureBlock {
    
    return [self sendRequest:request
                successBlock:successBlock
         uploadProgressBlock:nil
   constructingBodyWithBlock:nil
       downloadProgressBlock:nil
            destinationBlock:nil
                failureBlock:failureBlock];
}

- (FCNetworkTask*)sendUploadRequest:(FCNetworkRequest*)request successBlock:(FCNetworkSuccessBlock)successBlock progressBlock:(FCNetworkProgressBlock)progressBlock constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))constructingBodyBlock failureBlock:(FCNetworkFailureBlock)failureBlock {
    
    request.requestMode = FCNetworkRequestModePOST;
    return [self sendRequest:request
                successBlock:successBlock
         uploadProgressBlock:progressBlock
   constructingBodyWithBlock:constructingBodyBlock
       downloadProgressBlock:nil
            destinationBlock:nil
                failureBlock:failureBlock];
}

- (FCNetworkTask*)sendDownloadRequest:(FCNetworkRequest*)request successBlock:(FCNetworkDownloadSuccessBlock)successBlock progressBlock:(FCNetworkProgressBlock)progressBlock destinationBlock:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destinationBlock failureBlock:(FCNetworkFailureBlock)failureBlock {
    
    request.requestMode = FCNetworkRequestModeGET;
    return [self sendRequest:request
                successBlock:successBlock
         uploadProgressBlock:nil
   constructingBodyWithBlock:nil
       downloadProgressBlock:progressBlock
            destinationBlock:destinationBlock
                failureBlock:failureBlock];
}

- (NSArray<FCNetworkTask *> *)sendGroupRequest:(NSArray<FCNetworkRequest *> *)groupRequest successBlock:(FCNetworkGroupSuccessBlock)successBlock failureBlock:(FCNetworkGroupFailureBlock)failureBlock {
    
    FCNetworkGroupRequestTask *groupTask = [[FCNetworkGroupRequestTask alloc] initWithRequests:groupRequest];
    groupTask.delegate = self;
    groupTask.successBlock = successBlock;
    groupTask.failureBlock = failureBlock;
    [_groupTasks addObject:groupTask];
    
    FCLog_Verbose(@"GroupTask[%p] Begin", groupTask);
    
    NSMutableArray *taskArray = [NSMutableArray arrayWithCapacity:groupRequest.count];
    for (FCNetworkRequest *request in groupRequest) {
        
        FCNetworkTask *task = [self sendRequest:request successBlock:^(id response) {
            [groupTask addSuccessResponse:response forRequest:request];
        } failureBlock:^(FCNetworkError *error) {
            [groupTask addErrorResponse:error forRequest:request];
        }];
        
        [taskArray addObject:task];
    }
    
    return taskArray;
}

- (FCNetworkTask*)sendRequest:(FCNetworkRequest*)request successBlock:(FCNetworkSuccessBlock)successBlock uploadProgressBlock:(FCNetworkProgressBlock)uploadProgressBlock constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))constructingBodyBlock downloadProgressBlock:(FCNetworkProgressBlock)downloadProgressBlock destinationBlock:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destinationBlock failureBlock:(FCNetworkFailureBlock)failureBlock {
    
    NSAssert(request != nil, @"request should not be nil");
    NSAssert(successBlock != nil || failureBlock != nil, @"successBlock or failureBlock should not be nil");
    
    FCNetworkSession *session = [self sessionWithIdentifier:request.sessionIdentifier];
    NSAssert(session.sessionManager != nil, @"can not find AFHTTPSessionManager with identifier %@", request.sessionIdentifier);
    
    @FCWeakSelf;
    FCNetworkTask *task = [FCNetworkTask new];
    task.request = request;
    
    /**
        requestTaskBlock 即本次请求所要做的全部事情
        1，判断本次请求是否读缓存
        2，组装参数，发起请求
        3，在task成功回调中，判断是否请求成功，如果成功，考虑保存缓存，若存在业务层的错误，判断是否需要拦截。
        4，在task失败回调中，判断是否存在网络层错误，如果有错误，判断是否需要拦截
     */
    void (^requestTaskBlock) (void) = ^{
        
        @FCStrongSelf;
        
        // 非上传、下载的POST、GET请求才走缓存
        BOOL enableCache = request.enableCache && (request.requestMode == FCNetworkRequestModeGET || request.requestMode == FCNetworkRequestModePOST) && !destinationBlock && !constructingBodyBlock;
        
        // 创建针对Task的成功、失败回调包裹
        FCNetworkTaskSuccessBlock taskSuccessBlock = [self createTaskSuccessBlockWithRequest:request enableCache:enableCache successBlock:successBlock failureBlock:failureBlock];
        FCNetworkTaskFailureBlock taskFailureBlock = [self createTaskFailureBlockWithRequest:request successBlock:successBlock failureBlock:failureBlock];
        
        // 读缓存，如果有，就直接调用成功返回
        if (enableCache && [self loadCacheWithRequest:request sucessBlock:taskSuccessBlock]) {
            return;
        }
        
        // 同一个session下的请求，参数组装和创建task期间为串行执行，task任务为异步执行
        dispatch_sync(session.queue, ^{
            task.task = [self createTaskWithSessionManager:session.sessionManager
                                                   request:request
                                       uploadProgressBlock:uploadProgressBlock
                                 constructingBodyWithBlock:constructingBodyBlock
                                     downloadProgressBlock:downloadProgressBlock
                                          destinationBlock:destinationBlock
                                               sucessBlock:taskSuccessBlock
                                              failureBlock:taskFailureBlock];
        });
    };
    
    // [--- 请求前拦截 ---]
    if (_interceptor) {
        // 如果拦截器会拦截这个请求，则后续交给拦截器去处理，在这里就到此位置
        BOOL b = [_interceptor interceptRequest:request originalHandler:requestTaskBlock successBlock:successBlock failureBlock:failureBlock];
        // 如果拦截器并不拦截这个请求，则继续请求任务
        if (!b) {
            requestTaskBlock();
        }
#ifdef DEBUG
        else {
            FCLog_Verbose(@"want to send request[%@], but it has been intercepted", NSStringFromClass([request class]));
        }
#endif
    }
    else {
        requestTaskBlock();
    }
    
    return task;
}

- (NSURLSessionTask*)createTaskWithSessionManager:(AFHTTPSessionManager*)sessionManager request:(FCNetworkRequest*)request uploadProgressBlock:(FCNetworkProgressBlock)uploadProgressBlock constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))constructingBodyBlock downloadProgressBlock:(FCNetworkProgressBlock)downloadProgressBlock destinationBlock:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destinationBlock sucessBlock:(void (^) (NSURLSessionTask *task, id responseObject))successBlock failureBlock:(void (^) (NSURLSessionTask *task, NSError *error))failureBlock {
    
    sessionManager.requestSerializer.timeoutInterval = request.timeoutInterval;
    
    // 参数组装
    NSDictionary *headerParams = [request headerParams];
    NSDictionary *bodyParams = [request bodyParams];
    for (NSString *key in headerParams.allKeys) {
        [sessionManager.requestSerializer setValue:headerParams[key] forHTTPHeaderField:key];
    }
    
    FCLog_Verbose(@"send request[%@] URL: %@", NSStringFromClass([request class]), request.url);
    
    // 请求分类
    NSURLSessionTask *task = nil;
    switch (request.requestMode) {
            
        case FCNetworkRequestModeGET: {
            
            // 是否是下载
            if (destinationBlock) {
            
                NSError *serializationError = nil;
                NSMutableURLRequest *URLRequest = [sessionManager.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:request.url relativeToURL:sessionManager.baseURL] absoluteString] parameters:bodyParams error:&serializationError];
                
                if (serializationError) {
    
                    FCLog_Error(@"request[%@] create URLRequest by requestSerializer failed, error %@", NSStringFromClass([request class]), serializationError);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        failureBlock(nil, serializationError);
                    });
                    return nil;
                }
                
                task = [sessionManager downloadTaskWithRequest:URLRequest progress:downloadProgressBlock destination:destinationBlock completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                    
                    if (error) {
                        failureBlock(task, error);
                    }
                    else {
                        successBlock(task, filePath);
                    }
                }];
                [task resume];
            }
            else {
                
                task = [sessionManager GET:request.url
                                parameters:bodyParams
                                  progress:nil
                                   success:successBlock
                                   failure:failureBlock];
            }
        }
            break;
            
        case FCNetworkRequestModeDELETE: {
            task = [sessionManager DELETE:request.url
                               parameters:bodyParams
                                  success:successBlock
                                  failure:failureBlock];
        }
            break;
            
        case FCNetworkRequestModePOST: {
            
            // 是否是上传
            if (constructingBodyBlock) {
                task = [sessionManager POST:request.url
                                 parameters:bodyParams
                  constructingBodyWithBlock:constructingBodyBlock
                                   progress:uploadProgressBlock
                                    success:successBlock
                                    failure:failureBlock];
            }
            else {
                task = [sessionManager POST:request.url
                                 parameters:bodyParams
                                   progress:nil
                                    success:successBlock
                                    failure:failureBlock];
            }
        }
            break;
            
        case FCNetworkRequestModePUT: {
            task = [sessionManager PUT:request.url
                            parameters:bodyParams
                               success:successBlock
                               failure:failureBlock];
        }
            break;
            
        default:
            FCLog_Error(@"bad request mode %tu", request.requestMode);
            break;
    }
    
    // requestSerializer是公用的，避免header参数滞留导致的污染
    for (NSString *key in headerParams.allKeys) {
        [sessionManager.requestSerializer setValue:nil forHTTPHeaderField:key];
    }
    
    return task;
}

#pragma mark - Task Block Create

- (FCNetworkTaskSuccessBlock)createTaskSuccessBlockWithRequest:(FCNetworkRequest*)request enableCache:(BOOL)enableCache successBlock:(FCNetworkSuccessBlock)successBlock failureBlock:(FCNetworkFailureBlock)failureBlock {
    
    @FCWeakSelf;
    FCNetworkTaskSuccessBlock block = ^(NSURLSessionTask *task, id responseObject) {
        
        /**
            如果是走网络请求，服务端返回回来的成功，那么task一定有值
            如果是走读缓存，成功读取到了缓存数据而来的成功回调，那么是没有task值的
         */
        BOOL needSaveCache = task && enableCache;
    
        @FCStrongSelf;
        // 如果没有传解析器，则直接返回原始数据，正常业务下不推荐这种操作
        FCNetworkParser *parser = request.parser;
        if (!parser) {
            FCLog_Warning(@"request[%@]'s parser is nil, so origin response object will be return", NSStringFromClass([request class]), responseObject);
            FCLog_Verbose(@"request[%@] succcess:\n"
                          "\t[URL] - %@\n"
                          "\t[Header Params] - %@\n"
                          "\t[Body Params] - %@\n"
                          "\t[Response] - %@",
                          NSStringFromClass([request class]),
                          request.url,
                          request.headerParams,
                          request.bodyParams,
                          responseObject);
            successBlock(responseObject);
            if (needSaveCache) {
                [self saveCacheWithRequest:request responseObject:responseObject];
            }
            return;
        }
        
        // 下载请求，会直接返回一个NSURL对象，代指文件存储路径
        if ([responseObject isKindOfClass:[NSURL class]] && request.requestMode == FCNetworkRequestModeGET) {
            FCLog_Verbose(@"request[%@] download succcess:\n"
                          "\t[URL] - %@\n"
                          "\t[Header Params] - %@\n"
                          "\t[Body Params] - %@\n"
                          "\t[Response] - %@", NSStringFromClass([request class]),
                          request.url,
                          request.headerParams,
                          request.bodyParams,
                          responseObject);
            successBlock(responseObject);
            return;
        }
        
        // 验证服务端返回数据
        // 这里产生的失败，是指服务端正常返回了信息内容，但是存在业务层的失败，如业务层错误码不为0（密码错误、权限认证失败等）、数据格式不正确等
        parser.originResponseData = responseObject;
        FCNetworkError *fcError = [parser verifyResponse:responseObject];
        if (!fcError) {
            FCLog_Verbose(@"request[%@] succcess:\n"
                          "\t[URL] - %@\n"
                          "\t[Header Params] - %@\n"
                          "\t[Body Params] - %@\n"
                          "\t[Response] - %@", NSStringFromClass([request class]),
                          request.url,
                          request.headerParams,
                          request.bodyParams,
                          responseObject);
            successBlock([parser parseResponse:responseObject]);
            if (needSaveCache) {
                [self saveCacheWithRequest:request responseObject:responseObject];
            }
            return;
        }
         
        FCLog_Warning(@"request[%@] received business error:\n"
                      "\t[URL] - %@\n"
                      "\t[Header Params] - %@\n"
                      "\t[Body Params] - %@\n"
                      "\t[Error] - %zd %@\n"
                      "\t[Response] - %@", NSStringFromClass([request class]),
                      request.url,
                      request.headerParams,
                      request.bodyParams,
                      fcError.errorCode, fcError.errorDescription,
                      responseObject);
        // [--- 业务层错误拦截 ---]
        if (self.interceptor) {
            // 如果拦截器会拦截错误，则后续流程交由拦截器处理
            BOOL b = [self.interceptor interceptError:fcError request:request successBlock:successBlock failureBlock:failureBlock];
            // 如果拦截器不拦截该错误，则把错误码传递给失败回调
            if (!b) {
                failureBlock(fcError);
            }
#ifdef DEBUG
            else {
                FCLog_Verbose(@"request[%@]'s business error (%zd, %@) has been intercepted", NSStringFromClass([request class]), fcError.errorCode, fcError.errorDescription);
            }
#endif
        }
        else {
            failureBlock(fcError);
        }
    };
    
    return block;
}

- (FCNetworkTaskFailureBlock)createTaskFailureBlockWithRequest:(FCNetworkRequest*)request successBlock:(FCNetworkSuccessBlock)successBlock failureBlock:(FCNetworkFailureBlock)failureBlock {
    
    @FCWeakSelf;
    FCNetworkTaskFailureBlock block = ^(NSURLSessionTask *task, NSError *error) {
                
        @FCStrongSelf;
        FCNetworkError *fcError = [self.errorClass errorWithSystemError:error];
        FCLog_Warning(@"request[%@] received network error:\n"
                      "\t[URL] - %@\n"
                      "\t[Header Params] - %@\n"
                      "\t[Body Params] - %@\n"
                      "\t[Error] - %zd %@", NSStringFromClass([request class]),
                      request.url,
                      request.headerParams,
                      request.bodyParams,
                      fcError.errorCode, fcError.errorDescription);
        
        // [--- 网络错误拦截 ---]
        if (self.interceptor) {
            BOOL b = [self.interceptor interceptError:fcError request:request successBlock:successBlock failureBlock:failureBlock];
            if (!b) {
                failureBlock(fcError);
            }
#ifdef DEBUG
            else {
                FCLog_Verbose(@"request[%@]'s network error (%zd, %@) has been intercepted", NSStringFromClass([request class]), fcError.errorCode, fcError.errorDescription);
            }
#endif
        }
        else {
            failureBlock(fcError);
        }
    };
    
    return block;
}

#pragma mark - Cache

- (BOOL)loadCacheWithRequest:(FCNetworkRequest*)request sucessBlock:(void (^) (NSURLSessionTask *task, id responseObject))successBlock {
    
    // 如果读取到了缓存，就走taskSuccessBlock成功返回，因为缓存的是服务端原始返回信息，因此需要走一遍parser解析
    // 如果直接缓存parser解析后生成的数据对象，那么需要所有数据对象都实现NSCoding协议，会增加复杂度
    FCNetworkCacheData *data = [self.cache dataForKey:request.cacheKey type:request.cacheType];
    if (data) {
        FCLog_Verbose(@"request[%@] load cache success", NSStringFromClass([request class]));
        successBlock(nil, data.responseObject);
        return YES;
    }
    
    return NO;
}

- (void)saveCacheWithRequest:(FCNetworkRequest*)request responseObject:(id)responseObject {
    
    FCLog_Verbose(@"request[%@] save cache success", NSStringFromClass([request class]));
    
    FCNetworkCacheData *data = [FCNetworkCacheData new];
    data.key = request.cacheKey;
    data.responseObject = responseObject;
    
    if (request.cacheExpireTime > 0) {
        data.expireTime = [NSDate dateWithTimeInterval:request.cacheExpireTime sinceDate:[NSDate date]];
    }
    else {
        data.expireTime = nil;
    }
    
    [_cache saveData:data forKey:data.key type:request.cacheType];
}

#pragma mark - FCNetworkGroupRequestTaskDelegate

- (void)groupRequestTask:(FCNetworkGroupRequestTask *)task didCompleteWithSuccess:(BOOL)success {
    
    [_groupTasks removeObject:task];
    FCLog_Verbose(@"GroupTask[%p] End with %@", task, success ? @"success" : @"error");
}

@end
