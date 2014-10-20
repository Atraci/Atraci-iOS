//
//  AppSetting.h
//  Atraci
//
//  Created by Uriel Garcia on 19/10/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AppSetting : NSManagedObject

@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSString * value;

+(BOOL)addSettingValue:(NSString *)value forKey:(NSString *)key;
+(AppSetting *)getSettingforKey:(NSString *)key;
+(BOOL)deleteSetting:(NSString *)key;
+(BOOL)updateSettingValue:(NSString *)value forSetting:(AppSetting *)setting;
@end
