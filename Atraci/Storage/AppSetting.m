//
//  AppSetting.m
//  Atraci
//
//  Created by Uriel Garcia on 19/10/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import "AppSetting.h"
#import "AppDelegate.h"

@implementation AppSetting

@dynamic key;
@dynamic value;

NSString *const ENTITY = @"AppSetting";

+(BOOL)addSettingValue:(NSString *)value forKey:(NSString *)key
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    // Create Managed Object
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:ENTITY inManagedObjectContext:context];
    NSManagedObject *appSetting = [[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
    
    [appSetting setValue:key forKey:@"key"];
    [appSetting setValue:value forKey:@"value"];
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unable to save managed object context.");
        NSLog(@"%@, %@", error, error.localizedDescription);
        return NO;
    }
    
    return YES;
}

+(AppSetting *)getSettingforKey:(NSString *)key
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:ENTITY inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    //Get All Except MainQueue
    NSPredicate *predicate =[NSPredicate predicateWithFormat:
                                         @"(key = %@)", key];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *result = [context executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        NSLog(@"Unable to execute fetch request.");
        NSLog(@"%@, %@", error, error.localizedDescription);
        
    } else {
        if (result.count > 0) {
            return [result firstObject];
        }
    }
    
    return nil;
}

+(BOOL)deleteSetting:(NSString *)key
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    BOOL isSuccessful = YES;
    
    //Delete Playlist
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:ENTITY inManagedObjectContext:context];
    NSFetchRequest *fRequest = [[NSFetchRequest alloc] init];
    [fRequest setEntity:entityDesc];
    
    NSPredicate *pred =[NSPredicate predicateWithFormat:
                        @"(key = %@)", key];
    [fRequest setPredicate:pred];
    
    NSManagedObject *match = nil;
    
    NSError *error;
    NSArray *objects = [context executeFetchRequest:fRequest
                                              error:&error];
    
    if ([objects count] == 0)
    {
        NSLog(@"No matches");
        isSuccessful = NO;
    }
    else
    {
        for (int i = 0; i < [objects count]; i++)
        {
            match = objects[i];
            [context deleteObject:match];
            
            NSError *error = nil;
            if (![context save:&error])
            {
                isSuccessful = NO;
                NSLog(@"Error deleting, %@", [error userInfo]);
                return isSuccessful;
            }
        }
    }
    
    return isSuccessful;
}

+(BOOL)updateSettingValue:(NSString *)value forSetting:(AppSetting *)setting
{
    BOOL isSuccessful = YES;

    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];

    setting.value = value;
    
    NSError *error = nil;
    if (![context save:&error])
    {
        isSuccessful = NO;
        NSLog(@"Error deleting, %@", [error userInfo]);
    }
    
    return isSuccessful;
}
@end
