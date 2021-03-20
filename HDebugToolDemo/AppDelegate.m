//
//  AppDelegate.m
//  HDebugToolDemo
//
//  Created by HeXiaoTian on 2021/3/20.
//

#import "AppDelegate.h"
#import <HDebugTool/HDebugTool-Swift.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [HDebugTool show];
    
    return YES;
}


@end
