//
//  TestServiceBaseParser.m
//  FCNetworkExample
//
//  Created by LeoLiu on 2020/1/9.
//  Copyright (c) 2020 ForestCocoon ltyfantasy@163.com. All rights reserved.
//

#import "TestServiceBaseParser.h"

@implementation TestServiceBaseParser

- (FCNetworkError *)verifyResponse:(id)responseObject {
    
    // 做一个简单的验证
    if (![responseObject objectForKey:@"results"]) {
        return [FCNetworkError errorWithErrorCode:1001 errorDescription:@"服务端返回数据有误"];
    }
    
    return nil;
}

@end
