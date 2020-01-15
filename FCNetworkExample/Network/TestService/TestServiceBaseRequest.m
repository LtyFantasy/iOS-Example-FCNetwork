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
        
        self.sessionIdentifier = @"TestServiceSession";
        self.timeoutInterval = 15;
    }
    return self;
}

- (NSDictionary *)headerParams {
    return [super headerParams];
}

- (NSDictionary *)bodyParams {
    return [super bodyParams];
}

@end
