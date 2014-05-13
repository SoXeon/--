//
//  DPLocationItem.m
//  一团
//
//  Created by 戴鹏 on 14-5-12.
//  Copyright (c) 2014年 戴鹏. All rights reserved.
//

#import "DPLocationItem.h"
#import "DPCityListController.h"

#define kImageScale 0.5

@interface DPLocationItem() <UIPopoverControllerDelegate>
{
    UIPopoverController *_popover;
}

@end

@implementation DPLocationItem

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //设置内部图片
        [self setIcon:@"ic_district.png" selectedIcon:@"ic_district_hl.png"];
        
        //自动伸缩
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        
        //显示文字
        [self setTitle:@"定位中" forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont systemFontOfSize:16];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [self setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        
        //设置图片属性
        self.imageView.contentMode = UIViewContentModeCenter;
        
        //监听点击
        [self addTarget:self action:@selector(locationClick) forControlEvents:UIControlEventTouchDown];
    }
    return self;
}

- (void)screenRoate
{
    if (_popover.popoverVisible) {
        //关闭之前的
        [_popover dismissPopoverAnimated:NO];
        
        //创建新的
        [self performSelector:@selector(locationClick) withObject:nil afterDelay:0.5];
    }
}

- (void)locationClick
{
    DPCityListController *city = [[DPCityListController alloc]init];
    _popover = [[UIPopoverController alloc] initWithContentViewController:city];
    _popover.popoverContentSize = CGSizeMake(320, 480);
    _popover.delegate = self;
    [_popover presentPopoverFromRect:self.bounds inView:self permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
    //监听屏幕旋转的通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(screenRoate) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    //popover被销毁的时候，移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    CGFloat w = contentRect.size.width;
    CGFloat h = contentRect.size.height * kImageScale;
    return CGRectMake(0, 0, w, h);
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    CGFloat w = contentRect.size.width;
    CGFloat h = contentRect.size.height * (1 - kImageScale);
    CGFloat y = contentRect.size.height - h;
    return CGRectMake(0, y, w, h);
}


@end
