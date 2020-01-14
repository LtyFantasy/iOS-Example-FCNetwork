//
//  MyNetworkInterceptor.m
//  FCNetworkExample
//
//  Created by 刘天羽 on 2020/1/9.
//  Copyright © 2020 LeoLiu. All rights reserved.
//

#import "MyNetworkInterceptor.h"
#import "QueryCountriesRequest.h"

@implementation MyNetworkInterceptor

- (BOOL)interceptRequest:(FCNetworkRequest *)request originalHandler:(void (^)(void))originalHandler successBlock:(FCNetworkSuccessBlock)successBlock failureBlock:(FCNetworkFailureBlock)failureBlock {
    
    // 拦截指定的请求
    if ([request isKindOfClass:[QueryCountriesRequest class]]) {
        
        // 模拟，拦截了该请求，跑去做了其他事，做完了，再继续被拦截的请求
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            int i = 3;
            while (i > 0) {
                sleep(1);
                NSLog(@"Interceptor do something %d", i);
                i--;
            }
            
            // 如果做事情期间发生了某种错误，则可以直接调用failureBlock返回，表明被拦截的请求，请求失败
            /*if (error) {
                failureBlock([FCNetworkError errorWithErrorCode:10086 errorDescription:@"error"]);
            }*/
            
            // 拦截期间要做的事做完了，继续被拦截的请求
            originalHandler();
        });
        
        return YES;
    }
    
    return NO;
}

- (BOOL)interceptError:(FCNetworkError *)error request:(FCNetworkRequest *)request successBlock:(FCNetworkSuccessBlock)successBlock failureBlock:(FCNetworkFailureBlock)failureBlock {
    
    // 拦截特定的错误码，比如请求失败，发现原因是token失效了
    if (error.errorCode == 1001) {
        
        // 以下代码模拟发起一次token刷新请求，当然，本处是不可能执行成功的
        FCNetworkRequest *tokenRefreshRequest = [FCNetworkRequest new];
        tokenRefreshRequest.parser = [FCNetworkParser new];
        [[FCNetworkManager manager] sendRequest:tokenRefreshRequest successBlock:^(id response) {
           
            // 如果Token请求成功了
            NSString *newToken = response;
            // TODO ....
            
            // 然后继续之前因为token过期，而导致失败的请求，从而实现token自动续期
            [[FCNetworkManager manager] sendRequest:request successBlock:successBlock failureBlock:failureBlock];
            
        } failureBlock:^(FCNetworkError *tokenError) {
            
            // 如果刷新token也失败了，则调用原来的请求的失败回调就行了，通知上层
            // 具体，到底要用哪个error，还是自己重新创建一个error，随你了~
            failureBlock(error);
        }];
        
        return YES;
    }
    
    return NO;
}

@end
