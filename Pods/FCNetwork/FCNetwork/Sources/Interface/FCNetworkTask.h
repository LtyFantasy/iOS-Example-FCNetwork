//
//  FCNetworkTask.h
//  AFNetworking
//
//  Created by LeoLiu on 2020/01/13.
//  Copyright (c) 2019 ForestCocoon ltyfantasy@163.com. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FCNetworkRequest;
@interface FCNetworkTask : NSObject

/// 任务对应的原始请求对象
@property (nonatomic, strong) FCNetworkRequest *request;
/// 发起请求时，请求对应的NSURLSessionTask对象
@property (nonatomic, strong) NSURLSessionTask *task;

@end

NS_ASSUME_NONNULL_END
