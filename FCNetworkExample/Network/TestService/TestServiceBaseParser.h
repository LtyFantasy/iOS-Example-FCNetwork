//
//  TestServiceBaseParser.h
//  FCNetworkExample
//
//  Created by LeoLiu on 2020/1/9.
//  Copyright (c) 2020 ForestCocoon ltyfantasy@163.com. All rights reserved.
//

#import <FCNetwork/FCNetwork.h>

NS_ASSUME_NONNULL_BEGIN

/**
    同一批业务接口，其返回数据的外层数据结构也应该是相同的，仅仅是具体的业务数据结构不同
    因此，基类parser可以进行外层数据的剥离，具体的业务接口parser仅需要处理业务数据的解析即可
 */
@interface TestServiceBaseParser : FCNetworkParser

@end

NS_ASSUME_NONNULL_END
