//
//  QueryCountriesParser.m
//  FCNetworkExample
//
//  Created by LeoLiu on 2020/1/9.
//  Copyright (c) 2020 ForestCocoon ltyfantasy@163.com. All rights reserved.
//

#import "QueryCountriesParser.h"
#import "QueryCountriesResponse.h"

@implementation QueryCountriesParser

- (id)parseResponse:(id)responseObject {
    
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSArray *resultsArray = [responseObject objectForKey:@"results"];
    if (!resultsArray || ![resultsArray isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *resultDict in resultsArray) {
        
        QueryCountriesResponse *response = [QueryCountriesResponse new];
        response.code = [resultDict objectForKey:@"code"];
        response.name = [resultDict objectForKey:@"name"];
        response.count = [[resultDict objectForKey:@"count"] integerValue];
        response.locations = [[resultDict objectForKey:@"locations"] integerValue];
        response.cities = [[resultDict objectForKey:@"cities"] integerValue];
        [array addObject:response];
    }
    
    return array;
}

@end
