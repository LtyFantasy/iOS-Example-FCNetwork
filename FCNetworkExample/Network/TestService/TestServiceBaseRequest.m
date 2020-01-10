//
//  FCTestServiceBaseRequest.m
//  FCNetworkExample
//
//  Created by 刘天羽 on 2020/1/9.
//  Copyright © 2020 LeoLiu. All rights reserved.
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
