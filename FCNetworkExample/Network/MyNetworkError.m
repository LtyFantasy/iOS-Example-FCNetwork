//
//  MyNetworkError.m
//  FCNetworkExample
//
//  Created by LeoLiu on 2020/1/9.
//  Copyright (c) 2020 ForestCocoon ltyfantasy@163.com. All rights reserved.
//

#import "MyNetworkError.h"

@implementation MyNetworkError

/**
    这里，转换网络通信错误到本项目的错误体系中，重新赋值错误码和错误描述等
 */
+ (instancetype)errorWithSystemError:(NSError *)error {
    return [super errorWithSystemError:error];
}

@end
