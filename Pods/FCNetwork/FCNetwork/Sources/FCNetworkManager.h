//
//  FCNetworkManager.h
//  FCNetwork
//
//  Created by LeoLiu on 2019/12/23.
//  Copyright (c) 2019 ForestCocoon ltyfantasy@163.com. All rights reserved.

#import <Foundation/Foundation.h>
#import "FCNetworkDefines.h"

@class FCNetworkRequest, FCNetworkParser, FCNetworkTask, AFHTTPSessionManager;
@protocol AFMultipartFormData, FCNetworkInterceptor;

#pragma mark - Defines

typedef NS_ENUM(NSUInteger, FCNetworkLogLevel) {
    
    FCNetworkLogLevelVerbose,
    FCNetworkLogLevelWarning,
    FCNetworkLogLevelError,
    FCNetworkLogLevelNone,
};

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Main Class

@interface FCNetworkManager : NSObject

- (instancetype)init __attribute__((unavailable("use + manager instead")));
+ (instancetype)new __attribute__((unavailable("use + manager instead")));

/**
    单例获取
 */
+ (instancetype)manager;

// --------------- 基础设置 ---------------

/**
    设置日志等级，仅在DEBUG模式下启用
    只有高于且等于level的日志才会被打印
    None > Error > Warning > Verbose
 */
- (void)setLogLevel:(FCNetworkLogLevel)level;

/**
    设置一个错误处理类，必须继承自FCNetworkError
 */
- (void)setErrorClass:(Class)errorClass;

/**
    设置拦截器，具体业务需要实现拦截协议
 */
- (void)setInterceptor:(id<FCNetworkInterceptor>)interceptor;

// --------------- Session管理 ---------------

/**
    添加AFHTTPSessionManager
 */
- (void)addSessionManager:(AFHTTPSessionManager*)sessionManager withIdentifier:(NSString*)identifier;

/**
    移除AFHTTPSessionManager
 */
- (void)removeSessionManagerWithIdentifier:(NSString*)identifier;

/**
    获取指定identifier的AFHTTPSessionManager
 */
- (AFHTTPSessionManager*)sessionManagerWithIdentifier:(NSString*)identifier;

// --------------- 请求 ---------------

/**
    发起网络请求
 
    @param request 请求体对象，包含URL、请求类型、参数
    @param successBlock 请求成功回调
    @param failureBlock 请求失败回调
 
    @return task对象
 */
- (FCNetworkTask*)sendRequest:(nonnull FCNetworkRequest*)request
                 successBlock:(nonnull FCNetworkSuccessBlock)successBlock
                 failureBlock:(nonnull FCNetworkFailureBlock)failureBlock;

/**
    发起上传请求

    @param request 请求体
    @param progressBlock 进度回调
    @param constructingBodyBlock 数据构造回调
    @param successBlock 请求成功回调
    @param failureBlock 请求失败回调

    @return task对象
*/
- (FCNetworkTask*)sendUploadRequest:(nonnull FCNetworkRequest*)request
                       successBlock:(nonnull FCNetworkSuccessBlock)successBlock
                      progressBlock:(FCNetworkProgressBlock)progressBlock
          constructingBodyWithBlock:(nonnull void (^)(id <AFMultipartFormData> formData))constructingBodyBlock
                       failureBlock:(nonnull FCNetworkFailureBlock)failureBlock;

/**
    发起下载请求

    @param request 请求体
    @param progressBlock 进度回调
    @param destinationBlock 目的设置回调
    @param successBlock 请求成功回调
    @param failureBlock 请求失败回调

    @return task对象
*/
- (FCNetworkTask*)sendDownloadRequest:(nonnull FCNetworkRequest*)request
                         successBlock:(nonnull FCNetworkDownloadSuccessBlock)successBlock
                        progressBlock:(FCNetworkProgressBlock)progressBlock
                     destinationBlock:(nonnull NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destinationBlock
                         failureBlock:(nonnull FCNetworkFailureBlock)failureBlock;

/**
    发起批量网络请求
 
    该接口，主要是为了针对特定业务情况，如需要进行多次请求才能构建一个完整场景，任意一个接口失败则该场景需要重试、刷新
    特点：
        1，所有请求全部成功，才会执行成功回调，response个数等于请求个数
        2，任意请求失败，执行失败回调，response为第一个请求的失败回应，暂时还没碰到过非要等所有请求都失败了才返回的实际业务情况
 
    @param groupRequest 请求体数组
    @param successBlock 请求成功回调
    @param failureBlock 请求失败回调
 */
- (NSArray<FCNetworkTask*>*)sendGroupRequest:(nonnull NSArray<FCNetworkRequest*>*)groupRequest
                                successBlock:(nonnull FCNetworkGroupSuccessBlock)successBlock
                                failureBlock:(nonnull FCNetworkGroupFailureBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
