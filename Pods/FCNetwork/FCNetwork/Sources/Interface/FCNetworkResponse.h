//
//  FCNetworkResponse.h
//  AFNetworking
//
//  Created by LeoLiu on 2020/01/13.
//  Copyright (c) 2019 ForestCocoon ltyfantasy@163.com. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FCNetworkRequest, FCNetworkError;
@interface FCNetworkResponse : NSObject

@property (nonatomic, strong) FCNetworkRequest *request;

@end

@interface FCNetworkSuccessResponse : FCNetworkResponse

@property (nonatomic, strong) id responseObject;

@end;

@interface FCNetworkErrorResponse : FCNetworkResponse

@property (nonatomic, strong) FCNetworkError *error;

@end

NS_ASSUME_NONNULL_END
