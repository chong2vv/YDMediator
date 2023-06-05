//
//  YDMediator.m
//  YDMediator_Example
//
//  Created by 王远东 on 2022/8/16.
//  Copyright © 2022 wangyuandong. All rights reserved.
//

#import "YDMediator.h"
#import <objc/runtime.h>

@interface YDSafeMutableDictionary : NSMutableDictionary

@end

@interface YDMediator ()

#ifdef DEBUG
@property (nonatomic, strong) YDSafeMutableDictionary *checkDic;
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

- (NSArray <NSString *> *)getAvoidCrashMethodByListPrefix:(NSString *)prefix {
    return [[self class] getAvoidCrashMethodByListPrefix:prefix];
}

+ (NSArray <NSString *> *)getAvoidCrashMethodByListPrefix:(NSString *)prefix {
    
    Class currentClass = [self class];
    NSMutableArray <NSString *> *selArrayM = [[NSMutableArray alloc] init];
    while (currentClass) {
        unsigned int methodCount;
        Method *methodList = class_copyMethodList(currentClass, &methodCount);
        unsigned int i = 0;
        for (; i < methodCount; i++) {
            
            SEL sel = method_getName(methodList[i]);
            NSString *methodString = [NSString stringWithCString:sel_getName(sel) encoding:NSUTF8StringEncoding];
            if ([methodString hasPrefix:prefix]) {
                [selArrayM addObject:methodString];
            }
        }
        
        free(methodList);
        currentClass = class_getSuperclass(currentClass);
    }
    
    if (selArrayM.count <= 0) {
        return nil;
    }
    
#if DEBUG
    for (int i = 0; i < selArrayM.count; i ++) {
        for (int j = i + 1; j < selArrayM.count; j ++) {
            NSString *stri = selArrayM[i];
            NSString *strj = selArrayM[j];
            if ([stri isEqualToString:strj]) {
                NSAssert(NO, @"请检查有同名分类名注意修改-- %@",stri);
            }
        }
    }
#endif
    return [selArrayM copy];
}
@end


#define INIT(...) self = super.init; \
if (!self) return nil; \
__VA_ARGS__; \
if (!_dic) return nil; \
_lock = dispatch_semaphore_create(1); \
return self;

#define LOCK(...) dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__; \
dispatch_semaphore_signal(self->_lock);

@implementation YDSafeMutableDictionary{
    NSMutableDictionary *_dic;  //Subclass a class cluster...
    dispatch_semaphore_t _lock;
}


#pragma mark - init

- (instancetype)init {
    INIT(_dic = [[NSMutableDictionary alloc] init]);
}

- (instancetype)initWithObjects:(NSArray *)objects forKeys:(NSArray *)keys {
    INIT(_dic =  [[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys]);
}

- (instancetype)initWithCapacity:(NSUInteger)capacity {
    INIT(_dic = [[NSMutableDictionary alloc] initWithCapacity:capacity]);
}

- (instancetype)initWithObjects:(const id[])objects forKeys:(const id <NSCopying>[])keys count:(NSUInteger)cnt {
    INIT(_dic = [[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys count:cnt]);
}

- (instancetype)initWithDictionary:(NSDictionary *)otherDictionary {
    INIT(_dic = [[NSMutableDictionary alloc] initWithDictionary:otherDictionary]);
}

- (instancetype)initWithDictionary:(NSDictionary *)otherDictionary copyItems:(BOOL)flag {
    INIT(_dic = [[NSMutableDictionary alloc] initWithDictionary:otherDictionary copyItems:flag]);
}


#pragma mark - method

- (NSUInteger)count {
    LOCK(NSUInteger c = _dic.count); return c;
}

- (id)objectForKey:(id)aKey {
    LOCK(id o = [_dic objectForKey:aKey]); return o;
}

- (NSEnumerator *)keyEnumerator {
    LOCK(NSEnumerator * e = [_dic keyEnumerator]); return e;
}

- (NSArray *)allKeys {
    LOCK(NSArray * a = [_dic allKeys]); return a;
}

- (NSArray *)allKeysForObject:(id)anObject {
    LOCK(NSArray * a = [_dic allKeysForObject:anObject]); return a;
}

- (NSArray *)allValues {
    LOCK(NSArray * a = [_dic allValues]); return a;
}

- (NSString *)description {
    LOCK(NSString * d = [_dic description]); return d;
}

- (NSString *)descriptionInStringsFileFormat {
    LOCK(NSString * d = [_dic descriptionInStringsFileFormat]); return d;
}

- (NSString *)descriptionWithLocale:(id)locale {
    LOCK(NSString * d = [_dic descriptionWithLocale:locale]); return d;
}

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level {
    LOCK(NSString * d = [_dic descriptionWithLocale:locale indent:level]); return d;
}

- (BOOL)isEqualToDictionary:(NSDictionary *)otherDictionary {
    if (otherDictionary == self) return YES;
    
    if ([otherDictionary isKindOfClass:YDSafeMutableDictionary.class]) {
        YDSafeMutableDictionary *other = (id)otherDictionary;
        BOOL isEqual;
        dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_wait(other->_lock, DISPATCH_TIME_FOREVER);
        isEqual = [_dic isEqual:other->_dic];
        dispatch_semaphore_signal(other->_lock);
        dispatch_semaphore_signal(self->_lock);
        return isEqual;
    }
    return NO;
}

- (NSEnumerator *)objectEnumerator {
    LOCK(NSEnumerator * e = [_dic objectEnumerator]); return e;
}

- (NSArray *)objectsForKeys:(NSArray *)keys notFoundMarker:(id)marker {
    LOCK(NSArray * a = [_dic objectsForKeys:keys notFoundMarker:marker]); return a;
}

- (NSArray *)keysSortedByValueUsingSelector:(SEL)comparator {
    LOCK(NSArray * a = [_dic keysSortedByValueUsingSelector:comparator]); return a;
}

- (void)getObjects:(id  _Nonnull __unsafe_unretained [])objects andKeys:(id  _Nonnull __unsafe_unretained [])keys count:(NSUInteger)count {
    LOCK([_dic getObjects:objects andKeys:keys count:count]);
}

- (id)objectForKeyedSubscript:(id)key {
    LOCK(id o = [_dic objectForKeyedSubscript:key]); return o;
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (NS_NOESCAPE ^)(id key, id obj, BOOL *stop))block {
    LOCK([_dic enumerateKeysAndObjectsUsingBlock:block]);
}

- (void)enumerateKeysAndObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (NS_NOESCAPE ^)(id key, id obj, BOOL *stop))block {
    LOCK([_dic enumerateKeysAndObjectsWithOptions:opts usingBlock:block]);
}

- (NSArray *)keysSortedByValueUsingComparator:(NS_NOESCAPE NSComparator)cmptr {
    LOCK(NSArray * a = [_dic keysSortedByValueUsingComparator:cmptr]); return a;
}

- (NSArray *)keysSortedByValueWithOptions:(NSSortOptions)opts usingComparator:(NS_NOESCAPE NSComparator)cmptr {
    LOCK(NSArray * a = [_dic keysSortedByValueWithOptions:opts usingComparator:cmptr]); return a;
}

- (NSSet *)keysOfEntriesPassingTest:(BOOL (NS_NOESCAPE ^)(id key, id obj, BOOL *stop))predicate {
    LOCK(NSSet * a = [_dic keysOfEntriesPassingTest:predicate]); return a;
}

- (NSSet *)keysOfEntriesWithOptions:(NSEnumerationOptions)opts passingTest:(BOOL (NS_NOESCAPE ^)(id key, id obj, BOOL *stop))predicate {
    LOCK(NSSet * a = [_dic keysOfEntriesWithOptions:opts passingTest:predicate]); return a;
}

#pragma mark - mutable

- (void)removeObjectForKey:(id)aKey {
    if (aKey == nil) {
        return;
    }
    LOCK([_dic removeObjectForKey:aKey]);
}

- (void)setObject:(id)anObject forKey:(id <NSCopying> )aKey {
    if (aKey == nil || anObject == nil) {
        return;
    }
    LOCK([_dic setObject:anObject forKey:aKey]);
}

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary {
    LOCK([_dic addEntriesFromDictionary:otherDictionary]);
}

- (void)removeAllObjects {
    LOCK([_dic removeAllObjects]);
}

- (void)removeObjectsForKeys:(NSArray *)keyArray {
    LOCK([_dic removeObjectsForKeys:keyArray]);
}

- (void)setDictionary:(NSDictionary *)otherDictionary {
    LOCK([_dic setDictionary:otherDictionary]);
}

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying> )key {
    LOCK([_dic setObject:obj forKeyedSubscript:key]);
}

#pragma mark - protocol

- (id)copyWithZone:(NSZone *)zone {
    return [self mutableCopyWithZone:zone];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    LOCK(id copiedDictionary = [[self.class allocWithZone:zone] initWithDictionary:_dic]);
    return copiedDictionary;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained[])stackbuf
                                    count:(NSUInteger)len {
    LOCK(NSUInteger count = [_dic countByEnumeratingWithState:state objects:stackbuf count:len]);
    return count;
}

- (BOOL)isEqual:(id)object {
    if (object == self) return YES;
    
    if ([object isKindOfClass:YDSafeMutableDictionary.class]) {
        YDSafeMutableDictionary *other = object;
        BOOL isEqual;
        dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_wait(other->_lock, DISPATCH_TIME_FOREVER);
        isEqual = [_dic isEqual:other->_dic];
        dispatch_semaphore_signal(other->_lock);
        dispatch_semaphore_signal(self->_lock);
        return isEqual;
    }
    return NO;
}

- (NSUInteger)hash {
    LOCK(NSUInteger hash = [_dic hash]);
    return hash;
}

@end
