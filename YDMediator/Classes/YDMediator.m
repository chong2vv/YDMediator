//
//  YDMediator.m
//  YDMediator_Example
//
//  Created by 王远东 on 2022/8/16.
//  Copyright © 2022 wangyuandong. All rights reserved.
//

#import "YDMediator.h"
#import <YDAvoidCrashKit/YDAvoidCrashKit.h>
#import <YDAvoidCrashKit/NSObject+YDAvoidCrashRunTime.h>

@interface YDMediator ()

#ifdef DEBUG
@property (nonatomic, strong) YDThreadSafeMutableDictionary *checkDic;
#endif

@end

@implementation YDMediator

+ (instancetype)shared {
    return [self sharedInstance];
}


+ (instancetype)sharedInstance {
    static YDMediator *mediator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mediator = [[[self class] alloc] init];
    });
    return mediator;
}

- (NSDictionary *)handleParam:(NSDictionary *)aParam type:(NSUInteger)aType navigationController:(UINavigationController *)aNav {
    NSMutableDictionary *param = [NSMutableDictionary dictionaryWithDictionary:aParam];
    [param setValue:@(aType) forKey:@"des"];
    if (aNav) {
        [param setValue:aNav forKey:@"nav"];
    }
    return [param copy];
}

- (NSDictionary *)handleParam:(NSDictionary *)aParam type:(NSUInteger)aType {
    return [self handleParam:aParam type:aType navigationController:nil];
}

- (void)initializationModule {
    NSArray<NSString *> * list = [self getAvoidCrashMethodByListPrefix:@"initialization_"];
    [list enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SEL sel = NSSelectorFromString(obj);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:sel];
#pragma clang diagnostic pop
    }];
}

#pragma mark - 缓存清理 启动修复
- (void)dispatchGroupPrefix:(NSString *)prefix completeBlock:(void(^)(void))completeBlock{
    
    NSArray<NSString *> * list = [self getAvoidCrashMethodByListPrefix:prefix];
    if (list.count <= 0) {
        if (completeBlock) {
            completeBlock();
        }
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 调度组
        dispatch_group_t group = dispatch_group_create();
        
        [list enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            SEL sel = NSSelectorFromString(obj);
            dispatch_group_enter(group);
#ifdef DEBUG
            NSString *checkKey = NSStringFromSelector(sel);
            self.checkDic[checkKey] = @(YES);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([self.checkDic[checkKey] boolValue]) {
                    NSAssert(NO, @"%@ 该方法没有回调请检查",checkKey);
                }
            });
#endif
            id block = ^(){
                dispatch_group_leave(group);
#ifdef DEBUG
                self.checkDic[checkKey] = @(NO);
#endif
            };
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:sel withObject:block];
#pragma clang diagnostic pop
        }];
#ifdef DEBUG
        [self.checkDic removeAllObjects];
#endif
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        
        if (completeBlock) {
            completeBlock();
        }
    });
}

/**
 *  清空缓存
 *
 *  清除所有缓存 回调在异步线程 需要自行处理
 *  @param clearBlock 清空缓存
 */
- (void)clearDiskOnCompletion:(void (^)(void))clearBlock {
    [self dispatchGroupPrefix:@"clearDisk_" completeBlock:clearBlock];
}


/**
 *  磁盘缓存大小 以 b 为单位
 */
- (CGFloat)diskCacheTotalCost {
    
    __block CGFloat totalCost = 0;
    [[self getAvoidCrashMethodByListPrefix:@"diskCache_"] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SEL sel = NSSelectorFromString(obj);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSNumber *number = [self performSelector:sel];
        totalCost += [number floatValue];
#pragma clang diagnostic pop
    }];
    
    return totalCost;
}


// 启动修复的处理， 如不实现 就调用 clearDiskOnCompletion
- (void)startRepairDiskOnCompletion:(void (^)(void))clearBlock {
    [self dispatchGroupPrefix:@"startRepairDisk_" completeBlock:clearBlock];
}

/**
 *  启动App时清理数据
 */
- (void)startAppClearCacheCompletion:(void (^)(void))clearBlock {
    [self dispatchGroupPrefix:@"startAppClearCache_" completeBlock:clearBlock];
}
@end
