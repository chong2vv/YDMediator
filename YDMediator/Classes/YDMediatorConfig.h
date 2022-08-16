//
//  YDMediatorConfig.h
//  YDMediator
//
//  Created by 王远东 on 2022/8/16.
//

#ifndef YDMediatorConfig_h
#define YDMediatorConfig_h

#define kVcShowType @"kVcShowType" // 控制器出来的类型 EYDMediatorShowType
#define kVcTitle    @"kVcTitle"    // 控制器的title
#define kNavigation @"kNavigation" // 传递导航控制器

typedef NS_ENUM(NSInteger, EYDMediatorShowType) {
    EYDMediatorShowTypePush = 0,     // push出Vc
    EYDMediatorShowTypePresent = 1,  // Present出Vc
    EYDMediatorShowTypePresentNoNav = 2, // Prese出Vc 不用nav 包
    EYDMediatorShowTypeNone = 3,     // 只创建不处理
    EYDMediatorShowTypePresentCrossDissolve = 4,// Present出Vc
};

#endif /* YDMediatorConfig_h */
