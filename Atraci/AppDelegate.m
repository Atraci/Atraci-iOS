//
//  AppDelegate.m
//  Atraci
//
//  Created by Uriel Garcia on 28/06/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import "AppDelegate.h"
#import "QueueViewController.h"
#import "QueueSingleton.h"
#import "ATCPlaylistHelper.h"
#import "Storage/AppSetting.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window.tintColor = [UIColor colorWithRed:0.35 green:0.36 blue:0.35 alpha:1.0];
    
    [self LoadMainQueuePlaylist];
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    if([QueueViewController sharedQueue].isPlaying == YES){
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            //Your code goes in here
            NSLog(@"Main Thread Code");
            double delayInSeconds = 1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                 [[QueueViewController sharedQueue].playerView playVideo];
                 [[NSOperationQueue mainQueue] cancelAllOperations];
            });
        }];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//    if([QueueViewController sharedQueue].isPlaying == YES){
//        [[QueueViewController sharedQueue].playerView playVideo];
//    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    //Save current queue playlist
    QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];
    [ATCPlaylistHelper setPlaylist:ATRACI_PLAYLIST_MAINQUEUE withSongQueue:queueSingleton.queueSongs];
    
    //Save current played song index
    NSString *settingKey = @"LAST_PLAYED_SONG";
    NSString *currentSongIndex = [NSString stringWithFormat:@"%d",queueSingleton.currentSongIndex];
    AppSetting *appSetting = [AppSetting getSettingforKey:settingKey];

    if (appSetting == nil) {
        [AppSetting addSettingValue:currentSongIndex forKey:settingKey];
    }
    else
    {
        [AppSetting updateSettingValue:currentSongIndex forSetting:appSetting];
    }
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    if(tabBarController.selectedIndex == 0 || tabBarController.selectedIndex == 2 || [QueueViewController sharedQueue].isPlaying == false)
    {
        return UIInterfaceOrientationMaskPortrait;
    }
    
    return UIInterfaceOrientationMaskAll;
}

-(void)removeAllSQLiteFiles
{
    NSFileManager  *manager = [NSFileManager defaultManager];
    
    // the preferred way to get the apps documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // grab all the files in the documents dir
    NSArray *allFiles = [manager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    
    // filter the array for only sqlite files
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.sqlite'"];
    NSArray *sqliteFiles = [allFiles filteredArrayUsingPredicate:fltr];
    
    // use fast enumeration to iterate the array and delete the files
    for (NSString *sqliteFile in sqliteFiles)
    {
        NSError *error = nil;
        [manager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:sqliteFile] error:&error];
    }
}

#pragma mark - Initial Playlist Interactions
- (void)LoadMainQueuePlaylist {
    //The first time the app loads we'll load the main queue playlist if exists, otherwise create it of it return NO
    //Set delegate method to always reload queue when loading playlists
    ATCPlaylistHelper *atcPlaylistHelper = [ATCPlaylistHelper sharedInstance];
    // assign delegate
    // grab a reference to the Tab Bar Controller and its viewController array
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    NSArray *allTabs = tabBarController.viewControllers;
    
    QueueViewController *qVc = (QueueViewController*)[allTabs objectAtIndex:1];
    atcPlaylistHelper.delegate = qVc;
    
    //Load or Create the playlist
    if([atcPlaylistHelper getPlaylist:ATRACI_PLAYLIST_MAINQUEUE withPredicate:nil andSongs:YES] == NO)
    {
        [ATCPlaylistHelper setPlaylist:ATRACI_PLAYLIST_MAINQUEUE withSongQueue:nil];
    }
    else
    {
        if (atcPlaylistHelper.recordsFound == YES) {
            qVc.shoudDisplayHUD = YES;
            
            [tabBarController setSelectedIndex:1];
        }
    }
}

#pragma mark - Application's Core Data
- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"AtraciModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}
//
// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AtraciModel.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
