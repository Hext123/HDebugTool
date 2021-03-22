//
//  HDebugFileSearchOperation.m
//  HDebugTool
//
//  Created by HeXiaoTian on 2021/3/22.
//

#import "HDebugFileSearchOperation.h"

@implementation NSMutableArray (FIFO)

- (void)fifo_push:(id)object
{
    [self addObject:object];
}

- (id)fifo_pop
{
    id object = [self lastObject];
    [self removeLastObject];
    return object;
}

@end

@interface HDebugFileSearchOperation ()

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *searchString;

@end

@implementation HDebugFileSearchOperation

- (uint64_t)totalSizeAtPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary<NSString *, id> *attributes = [fileManager attributesOfItemAtPath:path error:NULL];
    uint64_t totalSize = [attributes fileSize];
    
    for (NSString *fileName in [fileManager enumeratorAtPath:path]) {
        attributes = [fileManager attributesOfItemAtPath:[path stringByAppendingPathComponent:fileName] error:NULL];
        totalSize += [attributes fileSize];
    }
    return totalSize;
}


- (id)initWithPath:(NSString *)currentPath searchString:(NSString *)searchString
{
    self = [super init];
    if (self) {
        self.path = currentPath;
        self.searchString = searchString;
    }
    return self;
}


- (void)main
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray<NSString *> *searchPaths = [NSMutableArray array];
    NSMutableDictionary<NSString *, NSNumber *> *sizeMapping = [NSMutableDictionary dictionary];
    uint64_t totalSize = 0;
    NSMutableArray<NSString *> *stack = [NSMutableArray array];
    [stack fifo_push:self.path];
    
    while ([stack count]) {
        NSString *currentPath = [stack fifo_pop];
        NSArray<NSString *> *directoryPath = [fileManager contentsOfDirectoryAtPath:currentPath error:nil];
        
        for (NSString *subPath in directoryPath) {
            NSString *fullPath = [currentPath stringByAppendingPathComponent:subPath];
            
            if ([[subPath lowercaseString] rangeOfString:[self.searchString lowercaseString]].location != NSNotFound) {
                [searchPaths addObject:fullPath];
                if (!sizeMapping[fullPath]) {
                    uint64_t fullPathSize = [self totalSizeAtPath:fullPath];
                    totalSize += fullPathSize;
                    [sizeMapping setObject:@(fullPathSize) forKey:fullPath];
                }
            }
            BOOL isDirectory;
            if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory] && isDirectory) {
                [stack fifo_push:fullPath];
            }
            
            if ([self isCancelled]) {
                return;
            }
        }
    }
    

    NSArray<NSString *> *sortedArray = [searchPaths sortedArrayUsingComparator:^NSComparisonResult(NSString *path1, NSString *path2) {
        uint64_t pathSize1 = [sizeMapping[path1] unsignedLongLongValue];
        uint64_t pathSize2 = [sizeMapping[path2] unsignedLongLongValue];
        if (pathSize1 < pathSize2) {
            return NSOrderedAscending;
        } else if (pathSize1 > pathSize2) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    
    if ([self isCancelled]) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate fileBrowserSearchOperationResult:sortedArray size:totalSize];
    });
}

@end
