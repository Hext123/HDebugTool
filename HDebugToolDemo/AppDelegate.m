//
//  AppDelegate.m
//  HDebugToolDemo
//
//  Created by HeXiaoTian on 2021/3/20.
//

#import "AppDelegate.h"
#import <HDebugTool/HDebugTool-Swift.h>
#import "HDebugToolDemo-Swift.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    HDebugTool.envNames = @[@"dev1",@"sit2"];
    HDebugTool.currentEnv = @"sit2";
    HDebugTool.envDatas = @{
        @"dev1": @{
            @"api1": @"http://baidu.com/api",
            @"cas1": @"http://baidu.com/cas",
            @"mqtt1": @"http://baidu.com/mqtt",
        },
        @"sit2": @{
            @"api2": @"http://sit.com/api",
            @"cas2": @"http://sit.com/cas",
            @"mqtt2": @"http://sit.com/mqtt",
        }
    };
    HDebugTool.envChanged = ^{
        NSLog(@"ENV: %@", HDebugTool.currentEnv);
    };
    
    // 借助 Swift 类型的帮助类去使用 HDebugTool, 可以使用一些 OC 没有的属性和类型
    [DebugToolHelper settingItems];
    
    [HDebugTool show];
    
    return YES;
}


@end
