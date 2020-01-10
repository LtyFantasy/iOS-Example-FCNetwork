//
//  QueryCountriesRequest.h
//  FCNetworkExample
//
//  Created by 刘天羽 on 2020/1/9.
//  Copyright © 2020 LeoLiu. All rights reserved.
//

#import "TestServiceBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface QueryCountriesRequest : TestServiceBaseRequest

@property (nonatomic, strong) NSArray<NSString*> *orderBy;
@property (nonatomic, strong) NSArray<NSString*> *sort;
@property (nonatomic, assign) NSInteger limit;
@property (nonatomic, assign) NSInteger page;

@end

NS_ASSUME_NONNULL_END
