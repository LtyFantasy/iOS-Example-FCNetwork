//
//  FCNetworkCache.m
//  FCNetwork
//
//  Created by LeoLiu on 2019/12/23.
//  Copyright (c) 2019 ForestCocoon ltyfantasy@163.com. All rights reserved.

#import "FCNetworkCache.h"

#pragma mark - Defines

#define FCWeakSelf                          autoreleasepool{} __weak typeof(self) weakSelf = self
#define FCStrongSelf                        autoreleasepool{} __strong typeof(self) self = weakSelf

#define kCacheDirector                      @"FCNetworkCache"

#pragma mark - Sub Class

@implementation FCNetworkCacheData

- (void)encodeWithCoder:(NSCoder *)coder {
    
    if (_key) {
        [coder encodeObject:_key forKey:@"key"];
    }
    
    if (_responseObject) {
        [coder encodeObject:_responseObject forKey:@"responseObject"];
    }
    
    if (_expireTime) {
        [coder encodeObject:_expireTime forKey:@"expireTime"];
    }
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    
    if (self = [super init]) {
        _key = [coder decodeObjectForKey:@"key"];
        _responseObject = [coder decodeObjectForKey:@"responseObject"];
        _expireTime = [coder decodeObjectForKey:@"expireTime"];
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isInvalid {
    return _expireTime ? [_expireTime compare:[NSDate date]] == NSOrderedAscending : NO;
}

@end

#pragma mark - Main Class

@interface FCNetworkCache ()

@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) NSMutableDictionary *ramDict;
@property (nonatomic, copy) NSString *tmpPath;
@property (nonatomic, copy) NSString *cachePath;

@end

@implementation FCNetworkCache

#pragma mark - Init

+ (instancetype)defaultCache {
    
    static FCNetworkCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [FCNetworkCache new];
    });
    return instance;
}

- (instancetype)init {
    
    if (self = [super init]) {
        [self dataInit];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)dataInit {
    
    _queue = dispatch_queue_create("com.ForestCocoon.FCNetwork.Cache", DISPATCH_QUEUE_CONCURRENT);
    _fileManager = [NSFileManager defaultManager];
    _ramDict = [NSMutableDictionary dictionary];
    _tmpPath = [self tmpRootPath];
    _cachePath = [self cacheRootPath];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

#pragma mark - Notification

- (void)didReceiveMemoryWarning:(NSNotification*)notify {
    [self cleanDataWithType:FCNetworkCacheTypeRAM];
}

#pragma mark - Path

- (NSString*)tmpRootPath {
    
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:kCacheDirector];
    if (![_fileManager fileExistsAtPath:path]) {
        [_fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    return path;
}

- (NSString*)cacheRootPath {
    
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *path = [cachePath stringByAppendingPathComponent:kCacheDirector];
    if (![_fileManager fileExistsAtPath:path]) {
        [_fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    return path;
}

#pragma mark - Data

- (FCNetworkCacheData*)dataForKey:(NSString *)key {
    
    if (!key || ![key isKindOfClass:[NSString class]] || key.length == 0) {
        return nil;
    }
    
    @FCWeakSelf;
    __block FCNetworkCacheData *data = nil;
    dispatch_sync(_queue, ^{
        
        @FCStrongSelf;
        NSString *filePath = nil;
        // 优先内存中取
        data = self.ramDict[key];
        if (data) {
            return;
        }
            
        // tmp中查询
        filePath = [self.tmpPath stringByAppendingPathComponent:key];
        data = [self dataWithFilePath:filePath];
        if (data) {
            return;
        }
        
        // cache中查询
        filePath = [self.cachePath stringByAppendingPathComponent:key];
        data = [self dataWithFilePath:filePath];
    });
    
    return data.isInvalid ? nil : data;
}

- (FCNetworkCacheData*)dataForKey:(NSString *)key type:(FCNetworkCacheType)type {
    
    if (!key || ![key isKindOfClass:[NSString class]] || key.length == 0) {
        return nil;
    }
    
    @FCWeakSelf;
    __block FCNetworkCacheData *data = nil;
    dispatch_sync(_queue, ^{
    
        @FCStrongSelf;
        NSString *filePath = nil;
        if (type == FCNetworkCacheTypeRAM) {
            data = self.ramDict[key];
        }
        else {
            
            if (type == FCNetworkCacheTypeTemp) {
                filePath = [self.tmpPath stringByAppendingPathComponent:key];
            }
            else {
                filePath = [self.cachePath stringByAppendingPathComponent:key];
            }
            data = [self dataWithFilePath:filePath];
        }
    });
    
    return data.isInvalid ? nil : data;
}

- (void)saveData:(FCNetworkCacheData*)data forKey:(NSString *)key type:(FCNetworkCacheType)type {
    
    if (!data || !key || ![key isKindOfClass:[NSString class]] || key.length == 0) {
        return;
    }
    
    @FCWeakSelf;
    dispatch_barrier_async(_queue, ^{
       
        @FCStrongSelf;
        switch (type) {
                
            case FCNetworkCacheTypeRAM: {
                self.ramDict[key] = data;
            }
                break;
                
            case FCNetworkCacheTypeTemp:
            case FCNetworkCacheTypeCache: {
                
                NSString *filePath = type == FCNetworkCacheTypeTemp ? self.tmpPath : self.cachePath;
                filePath = [filePath stringByAppendingPathComponent:key];
                
                NSData *tmpData = nil;
                if (@available(iOS 11.0, *)) {
                    tmpData = [NSKeyedArchiver archivedDataWithRootObject:data requiringSecureCoding:YES error:nil];
                }
                else {
                    tmpData = [NSKeyedArchiver archivedDataWithRootObject:data];
                }
                [self.fileManager createFileAtPath:filePath contents:tmpData attributes:nil];
            }
                break;
        }
    });
}

- (void)deleteDataForKey:(NSString *)key {
    
    if (!key || ![key isKindOfClass:[NSString class]] || key.length == 0) {
        return;
    }
    
    @FCWeakSelf;
    dispatch_barrier_async(_queue, ^{
        
        @FCStrongSelf;
        self.ramDict[key] = nil;

        NSString *filePath = [self.tmpPath stringByAppendingPathComponent:key];
        [self.fileManager removeItemAtPath:filePath error:nil];
        
        filePath = [self.cachePath stringByAppendingPathComponent:key];
        [self.fileManager removeItemAtPath:filePath error:nil];
    });
}

- (void)cleanDataWithType:(FCNetworkCacheType)cacheType {
    
    @FCWeakSelf;
    dispatch_barrier_async(_queue, ^{
        
        @FCStrongSelf;
        switch (cacheType) {
                
            case FCNetworkCacheTypeRAM:
                [self.ramDict removeAllObjects];
                break;
                
            case FCNetworkCacheTypeTemp:
                [self.fileManager removeItemAtPath:self.tmpPath error:nil];
                break;
            
            case FCNetworkCacheTypeCache:
                [self.fileManager removeItemAtPath:self.cachePath error:nil];
                break;
        }
    });
}

- (void)cleanAllData {
    
    @FCWeakSelf;
    dispatch_barrier_async(_queue, ^{
       
        @FCStrongSelf;
        [self.ramDict removeAllObjects];
        [self.fileManager removeItemAtPath:self.tmpPath error:nil];
        [self.fileManager removeItemAtPath:self.cachePath error:nil];
    });
}

#pragma mark - Private

- (FCNetworkCacheData*)dataWithFilePath:(NSString*)filePath {
    
    NSData *tmpData = [NSData dataWithContentsOfFile:filePath];
    if (!tmpData) {
        return nil;
    }
      
    FCNetworkCacheData *data = nil;
    if (@available(iOS 11.0, *)) {
        NSSet *set = [NSSet setWithObjects:FCNetworkCacheData.class, NSString.class, NSDate.class, NSArray.class, NSDictionary.class, NSNumber.class, nil];
        data = [NSKeyedUnarchiver unarchivedObjectOfClasses:set fromData:tmpData error:nil];
    }
    else {
        data = [NSKeyedUnarchiver unarchiveObjectWithData:tmpData];
    }
    
    if (data.isInvalid) {
        [self.fileManager removeItemAtPath:filePath error:nil];
        return nil;
    }
    else {
        return data;
    }
}

@end
