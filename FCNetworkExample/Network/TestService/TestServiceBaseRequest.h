//
//  TestServiceBaseRequest.h
//  FCNetworkExample
//
//  Created by LeoLiu on 2020/1/9.
//  Copyright (c) 2020 ForestCocoon ltyfantasy@163.com. All rights reserved.
//

#import <FCNetwork/FCNetwork.h>

NS_ASSUME_NONNULL_BEGIN

/**
    实际业务中，同一个业务的后端服务，一般都具有共同性，如URL基地址、所有接口都会有的公共Header参数等
    此时，应当先创建一个Request基类，来统筹这些信息
 */
@interface TestServiceBaseRequest : FCNetworkRequest

@end

NS_ASSUME_NONNULL_END
