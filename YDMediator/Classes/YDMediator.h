//
//  YDMediator.h
//  YDMediator_Example
//
//  Created by 王远东 on 2022/8/16.
//  Copyright © 2022 wangyuandong. All rights reserved.
//

#import "CTMediator.h"
#import "YDMediatorConfig.h"
#import <YDClearCacheService/YDClearCacheProtocol.h>


@interface YDMediator : CTMediator <YDClearCacheProtocol>

+ (instancetype)shared;

+ (instancetype)sharedInstance;

- (NSDictionary *)handleParam:(NSDictionary *)aParam type:(NSUInteger)aType;
- (NSDictionary *)handleParam:(NSDictionary *)aParam type:(NSUInteger)aType navigationController:(UINavigationController *)aNav;

// 所有模块初始化调用 模块初始化
#pragma mark - - (void)initialization_module;
- (void)initializationModule;

#pragma mark - 各个分类数据块清理问题 命名规范 通过遍历指定前缀名调用 实现解耦
/* 1.清理完成必须调用 clearBlock 回调。
 * 2.回调放在异步线程 主线程 均可。
 * 3.下面命名方式 中 moduleName 为模块名字，必须以下划线前面开头
 */

/**
 *  清空缓存
 *
 *  清除所有缓存 回调在异步线程 需要自行处理
 *  @param clearBlock 清空缓存
 */
#pragma mark - - (void)clearDisk_moduleNameOnCompletion:(void(^)())clearBlock;

/**
 *  磁盘缓存大小 以 b 为单位
 */
#pragma mark - - (NSNumber *)diskCache_moduleNameTotalCost;


// 启动修复的处理， 如不实现 就调用 clearDiskOnCompletion
#pragma mark - - (void)startRepairDisk_moduleNameOnCompletion:(void(^)())clearBlock;

/**
 *  启动App时清理数据
 */
#pragma mark - - (void)startAppClearCache_moduleNameCompletion:(void(^)())clearBlock;

@end

