//
//  FCTestServiceBaseRequest.m
//  FCNetworkExample
//
//  Created by LeoLiu on 2020/1/9.
//  Copyright (c) 2020 ForestCocoon ltyfantasy@163.com. All rights reserved.
//

#import "TestServiceBaseRequest.h"

@implementation TestServiceBaseRequest

- (instancetype)init {
    
    if (self = [super init]) {
        
        // 同一批业务接口，session一般都是一样的，所以在基类里控制
        self.sessionIdentifier = @"TestServiceSession";
        self.timeoutInterval = 15;
    }
    return self;
}

/**
  这里放置公共的Header参数等
 */
- (NSDictionary *)headerParams {
    return [super headerParams];
}

- (NSDictionary *)bodyParams {
    return [super bodyParams];
}

@end
