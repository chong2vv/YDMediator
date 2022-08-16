//
//  YDApp.h
//  YDMediator_Example
//
//  Created by 王远东 on 2022/8/16.
//  Copyright © 2022 wangyuandong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "YDMediatorConfig.h"


@interface YDApp : NSObject

@property (nonatomic, strong)UINavigationController *navigationController;
@property (nonatomic, strong)UIViewController *viewController;


- (void)showViewController:(UIViewController *)vc showType:(EYDMediatorShowType)showType;

- (void)showViewController:(UIViewController *)vc showType:(EYDMediatorShowType)showType animated:(BOOL)animated completion:(void (^)(void))completion;

@end

