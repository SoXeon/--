//
//  DPDealTool.m
//  一团
//
//  Created by DP on 14-5-20.
//  Copyright (c) 2014年 戴鹏. All rights reserved.
//

#import "DPDealTool.h"
#import "DPMetaDataTool.h"
#import "DPAPI.h"
#import "DPCity.h"
#import "DPOrder.h"
#import "DPDeal.h"
#import "NSObject+Value.h"
#import "DPLocationTool.h"

typedef void (^RequestBlock)(id result,NSError *errorObj);

@interface DPDealTool() <DPRequestDelegate>
{
    NSMutableDictionary *_blocks;
}
@end

@implementation DPDealTool

singleton_implementation(DPDealTool)

- (id)init
{
    if (self = [super init]) {
        _blocks = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark 获取大批量团购
-(void)getDealsWithParams:(NSDictionary *)params success:(DealsSuccessBlock)success error:(DealsErrorBlock)error
{
    //发送请求
    [self requestWithURL:@"v1/deal/find_deals" params:params block:^(id result, NSError *errorObj) {
        if (errorObj) {//请求失败
            if (error) {
                error(errorObj);
            }
        } else if (success) {//请求成功
            NSArray *array = result[@"deals"];
            NSMutableArray *deals = [NSMutableArray array];
            
            for (NSDictionary *dict in array) {
                DPDeal *d = [[DPDeal alloc]init];
                [d setValues:dict];
                [deals addObject:d];
            }
            success(deals,[result[@"total_count"]intValue]);
        }
    }];
}

#pragma mark 获取团购详情
-(void)dealWithID:(NSString *)ID success:(DealSuccessBlock)success error:(DealErrorBlock)error
{
    [self requestWithURL:@"v1/deal/get_single_deal" params:@{@"deal_id":ID} block:^(id result, NSError *errorObj) {
        NSArray *deals = result[@"deals"];
        if (deals.count) {
            if (success) {
                DPDeal *deal = [[DPDeal alloc]init];
                [deal setValues:deals[0]];
                success(deal);
            }
        } else {
            if (error) {
                error(errorObj);
            }
        }
    }];
}


- (void)dealsWithPage:(int)page success:(DealsSuccessBlock)success error:(DealsErrorBlock)error
{
    //设置一次性加载多少条数据
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:@(15) forKey:@"limit"];
    
    //添加城市参数
    NSString *city = [DPMetaDataTool sharedDPMetaDataTool].currentCity.name;
    [params setObject:city forKey:@"city"];
    
    //添加区域参数
    NSString *district = [DPMetaDataTool sharedDPMetaDataTool].currentDistrict;
    if (district && ![district isEqualToString:KAllDistrict]) {
        [params setObject:district forKey:@"region"];
    }
    
    //添加分类参数
    NSString *category = [DPMetaDataTool sharedDPMetaDataTool].currentCategory;
    if (category && ![category isEqualToString:kAllCategory]) {
        [params setObject:category forKey:@"category"];
    }
    
    //添加排序参数
    DPOrder *order = [DPMetaDataTool sharedDPMetaDataTool].currentOrder;
    if (order) {
        //按照距离最近排序
        if (order.index == 7) {
            DPCity *city = [DPLocationTool sharedDPLocationTool].locationCity;
            if (city) {
                [params setObject:@(order.index) forKey:@"sort"];
                
                //增肌经纬度参数
                [params setObject:@(city.position.latitude) forKey:@"latitude"];
                [params setObject:@(city.position.longitude) forKey:@"longitude"];
            }
        } else {
            [params setObject:@(order.index) forKey:@"sort"];
        }
    }
    
    //添加页码参数
    [params setObject:@(page) forKey:@"page"];
    
    //发送请求
    [self getDealsWithParams:params success:success error:error];

}

#pragma mark 获取周边团购
-(void)dealsWithPos:(CLLocationCoordinate2D)pos success:(DealsSuccessBlock)success error:(DealsErrorBlock)error
{
   DPCity *localCity = [DPLocationTool sharedDPLocationTool].locationCity;
    
    if (localCity == nil) {
        return;
    }
    
    [self getDealsWithParams:@{@"city": localCity.name,
                               @"latitude":@(pos.latitude),
                               @"longitude":@(pos.longitude),
                               @"radius":@5000 }success:success error:error];
}

#pragma mark 封装了大众点评的所有请求
-(void)requestWithURL:(NSString *)url params:(NSDictionary *)params block:(RequestBlock)block
{
    DPAPI *api = [DPAPI sharedDPAPI];
    DPRequest *request = [api requestWithURL:url params:params delegate:self];
    
    //一次请求对应一个block
    [_blocks setObject:block forKey:request.description];
}

#pragma mark 大众点评的代理方法
- (void)request:(DPRequest *)request didFinishLoadingWithResult:(id)result
{
    RequestBlock block = _blocks[request.description];
    if (block) {
        block(result,nil);
    }
}

- (void)request:(DPRequest *)request didFailWithError:(NSError *)error
{
    RequestBlock block = _blocks[request.description];
    if (block) {
        block(nil,error);
    }
}
@end
