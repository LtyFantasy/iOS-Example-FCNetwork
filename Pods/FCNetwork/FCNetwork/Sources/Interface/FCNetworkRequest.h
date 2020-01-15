//
//  FCNetworkRequest.h
//  FCNetwork
//
//  Created by LeoLiu on 2019/12/23.
//  Copyright (c) 2019 ForestCocoon ltyfantasy@163.com. All rights reserved.

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "FCNetworkDefines.h"

NS_ASSUME_NONNULL_BEGIN

@class FCNetworkParser;
@interface FCNetworkRequest : NSObject

/// 该请求所对应的AFHTTPSessionManager对象标记值
@property (nonatomic, copy) NSString *sessionIdentifier;
/// 请求所对应的解析器
@property (nonatomic, strong) FCNetworkParser *parser;
/// 请求URL地址，默认为 @""
@property (nonatomic, copy) NSString *url;
/// 请求方式，默认GET
@property (nonatomic, assign) FCNetworkRequestMode requestMode;
/// 超时时间，默认30秒，最小为1秒
@property (nonatomic, assign) NSInteger timeoutInterval;

/// 标签值，可以用来进行相关标记
@property (nonatomic, assign) NSInteger tag;

/**
    请求头参数，需要子类继承并实现
 */
- (NSDictionary*)headerParams;

/**
    请求体参数，需要子类继承并实现
 */
- (NSDictionary*)bodyParams;




// -------------- 缓存相关 --------------

/// 是否启用请求缓存机制，默认NO
@property (nonatomic, assign) BOOL enableCache;
/// 缓存类型，默认RAM
@property (nonatomic, assign) FCNetworkCacheType cacheType;
/// 缓存有效期，默认-1，值 <= 0为无时限，> 0 时为设置的时间，单位 ( 秒 )
@property (nonatomic, assign) NSInteger cacheExpireTime;

/**
    计算请求的缓存key值
 
    key = md5(requestMode + url + headerParams + bodyParams)
 */
- (NSString*)cacheKey;

@end

NS_ASSUME_NONNULL_END
