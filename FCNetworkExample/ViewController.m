//
//  ViewController.m
//  FCNetworkExample
//
//  Created by LeoLiu on 2020/1/9.
//  Copyright (c) 2020 ForestCocoon ltyfantasy@163.com. All rights reserved.
//

#import "ViewController.h"

#import "QueryCountriesRequest.h"
#import "QueryCountriesParser.h"
#import "QueryCountriesResponse.h"

#pragma mark - Inner Class

@interface CellModel : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) SEL selector;

@end

@implementation CellModel

+ (instancetype)modelWithTitle:(NSString*)title selector:(SEL)selector {
    
    CellModel *obj = [CellModel new];
    obj.title = title;
    obj.selector = selector;
    return obj;
}

@end

#pragma mark - Main Class

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<CellModel*> *cellModels;

@end

@implementation ViewController

#pragma mark - Life Circle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self dataInit];
    [self uiInit];
}

#pragma mark - Init

- (void)dataInit {
    
    _cellModels = [NSMutableArray array];
    [_cellModels addObject:[CellModel modelWithTitle:@"GET请求" selector:@selector(sendGetRequest)]];
    [_cellModels addObject:[CellModel modelWithTitle:@"GET批量组请求" selector:@selector(sendGroupRequest)]];
    [_cellModels addObject:[CellModel modelWithTitle:@"清除请求缓存" selector:@selector(cleanCache)]];
}

- (void)uiInit {
    
    _tableView = ({
       
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.rowHeight = 50;
        [self.view addSubview:tableView];
        tableView;
    });
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _cellModels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    cell.textLabel.text = _cellModels[indexPath.row].title;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    CellModel *model = _cellModels[indexPath.row];
    [self performSelectorOnMainThread:model.selector withObject:nil waitUntilDone:YES];
}

#pragma mark - Network Test

- (void)sendGetRequest {
    
    QueryCountriesRequest *request = [QueryCountriesRequest new];
    request.orderBy = @[@"cities", @"locations"];
    request.sort = @[@"desc"];
    request.limit = 1;
    request.page = 1;
    
    request.enableCache = YES;
    request.cacheType = FCNetworkCacheTypeCache;
    request.cacheExpireTime = -1;
    
    [[FCNetworkManager manager] sendRequest:request successBlock:^(id response) {
       
        NSLog(@"请求成功");
        NSArray<QueryCountriesResponse*> *array = response;
        for (QueryCountriesResponse *data in array) {
            NSLog(@"name = %@, code = %@, cities = %zd", data.name, data.code, data.cities);
        }
        
    } failureBlock:^(FCNetworkError *error) {
        
        NSLog(@"请求错误 ：%@", error);
    }];
}

- (void)sendGroupRequest {
    
    QueryCountriesRequest *request1 = [QueryCountriesRequest new];
    request1.orderBy = @[@"cities", @"locations"];
    request1.sort = @[@"desc"];
    request1.limit = 1;
    request1.page = 1;
    
    QueryCountriesRequest *request2 = [QueryCountriesRequest new];
    request2.orderBy = @[@"cities", @"locations"];
    request2.sort = @[@"desc"];
    request2.limit = 1;
    request2.page = 2;
    
    QueryCountriesRequest *request3 = [QueryCountriesRequest new];
    request3.orderBy = @[@"cities", @"locations"];
    request3.sort = @[@"desc"];
    request3.limit = 1;
    request3.page = 3;
    
    [[FCNetworkManager manager] sendGroupRequest:@[request1, request2, request3] successBlock:^(NSArray<FCNetworkSuccessResponse *> *responses) {
        
        NSLog(@"请求成功");
        for (FCNetworkSuccessResponse *response in responses) {
            
            // response.request 可以判断这个是属于哪个请求的
            // TODO ..
            
            // 获取请求的返回数据
            NSArray<QueryCountriesResponse*> *array = response.responseObject;
            for (QueryCountriesResponse *data in array) {
                NSLog(@"name = %@, code = %@, cities = %zd", data.name, data.code, data.cities);
            }
        }
        
    } failureBlock:^(FCNetworkErrorResponse *responses) {
        
        NSLog(@"请求错误 ：%@", responses.error);
    }];
}

- (void)cleanCache {
    
    NSLog(@"清理缓存");
    [[FCNetworkCache defaultCache] cleanAllData];
}


@end
