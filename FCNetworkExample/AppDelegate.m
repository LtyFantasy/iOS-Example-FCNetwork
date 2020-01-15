//
//  AppDelegate.m
//  FCNetworkExample
//
//  Created by LeoLiu on 2020/1/9.
//  Copyright (c) 2020 ForestCocoon ltyfantasy@163.com. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "MyNetworkInterceptor.h"
#import "MyNetworkError.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self dataInit];
    [self uiInit];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {


}

- (void)applicationDidEnterBackground:(UIApplication *)application {

}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
}

#pragma mark - Init

- (void)dataInit {
    
    FCNetworkManager *manager = [FCNetworkManager manager];
    // 打印日志等级
    [manager setLogLevel:FCNetworkLogLevelVerbose];
    // 拦截器
    [manager setInterceptor:[MyNetworkInterceptor new]];
    // 错误类
    [manager setErrorClass:MyNetworkError.class];
    
    // 添加一个session，用于TestService服务
    AFHTTPSessionManager *normalSessionManager = [AFHTTPSessionManager manager];
    normalSessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/plain", nil];
    [manager addSessionManager:normalSessionManager withIdentifier:@"TestServiceSession"];
}

- (void)uiInit {
    
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _window.backgroundColor = [UIColor whiteColor];
    
    ViewController *vc = [ViewController new];
    _window.rootViewController = vc;
    [_window makeKeyAndVisible];
}

@end
