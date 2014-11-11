//
//  AppDelegate.m
//  Example
//
//  Created by Elvis Nuñez on 11/11/14.
//  Copyright (c) 2014 KIPU. All rights reserved.
//

#import "AppDelegate.h"
//#import "ANDYDataManager.h"
#import "ViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    ViewController *mainController = [[ViewController alloc] init];
    self.window.rootViewController = mainController;

    [self.window makeKeyAndVisible];
    return YES;
}

//- (void)applicationWillTerminate:(UIApplication *)application
//{
//    [[ANDYDataManager sharedManager] persistContext];
//}

@end
