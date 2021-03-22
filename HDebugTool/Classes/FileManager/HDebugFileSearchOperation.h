//
//  HDebugFileSearchOperation.h
//  HDebugTool
//
//  Created by HeXiaoTian on 2021/3/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HDebugFileSearchOperationDelegate <NSObject>

- (void)fileBrowserSearchOperationResult:(NSArray<NSString *> *)searchResult size:(uint64_t)size;

@end

@interface HDebugFileSearchOperation : NSOperation

@property (nonatomic, weak) id<HDebugFileSearchOperationDelegate> delegate;

- (id)initWithPath:(NSString *)currentPath searchString:(NSString *)searchString;

@end


NS_ASSUME_NONNULL_END
