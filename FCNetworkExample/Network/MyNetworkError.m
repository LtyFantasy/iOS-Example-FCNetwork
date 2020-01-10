//
//  MyNetworkError.m
//  FCNetworkExample
//
//  Created by 刘天羽 on 2020/1/9.
//  Copyright © 2020 LeoLiu. All rights reserved.
//

#import "MyNetworkError.h"

@implementation MyNetworkError

+ (instancetype)errorWithSystemError:(NSError *)error {
    return [super errorWithSystemError:error];
}

@end
