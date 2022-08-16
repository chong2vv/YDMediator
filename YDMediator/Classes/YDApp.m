//
//  YDApp.m
//  YDMediator_Example
//
//  Created by 王远东 on 2022/8/16.
//  Copyright © 2022 wangyuandong. All rights reserved.
//

#import "YDApp.h"

@implementation YDApp


- (void)showViewController:(UIViewController *)vc showType:(EYDMediatorShowType)showType{
    [self showViewController:vc showType:showType animated:NO completion:nil];
}

- (void)showViewController:(UIViewController *)vc showType:(EYDMediatorShowType)showType animated:(BOOL)animated completion:(void (^ __nullable)(void))completion{
    switch (showType) {
        case EYDMediatorShowTypePush:
        {
            [self.navigationController pushViewController:vc animated:animated];
        }
            break;
            
        case EYDMediatorShowTypePresent:
        {
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            nav.modalPresentationStyle = UIModalPresentationFullScreen;
            [self.navigationController presentViewController:nav animated:animated completion:completion];
        }
            break;
            
        case EYDMediatorShowTypePresentCrossDissolve:
        {
            vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self.navigationController presentViewController:vc animated:animated completion:completion];
        }
            break;
            
        case EYDMediatorShowTypePresentNoNav:
        {
            vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
            [self.navigationController presentViewController:vc animated:animated completion:completion];
        }
            break;
            
        case EYDMediatorShowTypeNone:
        {
            
        }
            break;
        default:
            break;
    }
    self.navigationController = nil;
}

- (UINavigationController *)navigationForViewController:(UIViewController *)vc{
    
    UINavigationController *nav = nil;
    if ([vc isKindOfClass:[UINavigationController class]]) {
        nav = (UINavigationController *)vc;
    }
    
    UIViewController *pvc = vc.presentedViewController;
    while (pvc != nil) {
        
        if ([pvc isKindOfClass:[UINavigationController class]]) {
            nav = (UINavigationController *)pvc;
        }
        pvc = pvc.presentedViewController;
    }
    
    return nav;
}

- (UIViewController *)viewController
{
    return self.navigationController.visibleViewController;
}

- (UIViewController*)topPresentedController
{
    UIViewController *topController = [UIApplication sharedApplication].delegate.window.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

@end
