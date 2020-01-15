//
//  QueryCountriesRequest.m
//  FCNetworkExample
//
//  Created by LeoLiu on 2020/1/9.
//  Copyright (c) 2020 ForestCocoon ltyfantasy@163.com. All rights reserved.
//

#import "QueryCountriesRequest.h"
#import "QueryCountriesParser.h"

@implementation QueryCountriesRequest

- (instancetype)init {
    
    if (self = [super init]) {
        
        self.requestMode = FCNetworkRequestModeGET;
        // 实际业务中，URL的拼接要么用基类控制，要么用宏控制
        self.url = @"https://api.openaq.org/v1/countries";
        // 如果某个接口，因为参数的不同，可能返回多种差异巨大的数据结构，那么需要创建多个parser来为其服务，在业务请求时赋值即可
        self.parser = [QueryCountriesParser new];
    }
    return self;
}

- (NSDictionary *)bodyParams {
    
    NSMutableDictionary *dict = [[super bodyParams] mutableCopy];
    
    if (_orderBy.count > 0) {
        dict[@"order_by"] = _orderBy;
    }
    
    if (_sort.count > 0) {
        dict[@"sort"] = _sort;
    }
    
    dict[@"limit"] = @(_limit);
    dict[@"page"] = @(_page);
    
    return dict;
}

@end
