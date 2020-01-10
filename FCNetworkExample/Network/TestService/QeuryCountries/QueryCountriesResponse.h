//
//  QueryCountriesResponse.h
//  FCNetworkExample
//
//  Created by 刘天羽 on 2020/1/9.
//  Copyright © 2020 LeoLiu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QueryCountriesResponse : NSObject

@property (nonatomic, copy) NSString *code;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) NSInteger locations;
@property (nonatomic, assign) NSInteger cities;

@end

NS_ASSUME_NONNULL_END
