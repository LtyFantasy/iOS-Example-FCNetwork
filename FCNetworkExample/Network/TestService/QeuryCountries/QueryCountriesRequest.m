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
        self.url = @"https://api.openaq.org/v1/countries";
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
