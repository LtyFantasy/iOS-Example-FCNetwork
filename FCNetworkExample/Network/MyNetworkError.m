//
//  MyNetworkError.m
//  FCNetworkExample
//
//  Created by LeoLiu on 2020/1/9.
//  Copyright (c) 2020 ForestCocoon ltyfantasy@163.com. All rights reserved.
//

#import "MyNetworkError.h"

@implementation MyNetworkError

+ (instancetype)errorWithSystemError:(NSError *)error {
    return [super errorWithSystemError:error];
}

@end
