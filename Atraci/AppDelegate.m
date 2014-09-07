//
//  AppDelegate.m
//  Atraci
//
//  Created by Uriel Garcia on 28/06/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import "AppDelegate.h"
#import "QueueViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window.tintColor = [UIColor colorWithRed:0.35 green:0.36 blue:0.35 alpha:1.0];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    QueueViewController *qVc = (QueueViewController*)[tabBarController.viewControllers objectAtIndex:1];
    [qVc.playerView playVideo];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    QueueViewController *qVc = (QueueViewController*)[tabBarController.viewControllers objectAtIndex:1];
    [qVc.playerView playVideo];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    
//    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
//    QueueViewController *qVc = (QueueViewController*)[tabBarController.viewControllers objectAtIndex:1];
//    
//    id presentedViewController = [window.rootViewController presentedViewController];
//    NSString *className = presentedViewController ? NSStringFromClass([presentedViewController class]) : nil;

//    if(qVc.isPlaying){
//        return UIInterfaceOrientationMaskAll;
//    }
//    else{
//        if (window && [className isEqualToString:@"AVFullScreenViewController"]) {
//            return UIInterfaceOrientationMaskAll;
//        }
//        else {
//            return UIInterfaceOrientationMaskPortrait;
//        }
//    }
    return UIInterfaceOrientationMaskPortrait;
}
@end
