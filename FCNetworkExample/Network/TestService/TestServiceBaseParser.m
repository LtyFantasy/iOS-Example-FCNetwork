//
//  TestServiceBaseParser.m
//  FCNetworkExample
//
//  Created by 刘天羽 on 2020/1/9.
//  Copyright © 2020 LeoLiu. All rights reserved.
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
