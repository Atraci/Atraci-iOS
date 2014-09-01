//
//  QueueSingleton.h
//  Atraci
//
//  Created by Uriel Garcia on 12/07/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QueueSingleton : NSObject

@property(strong ,nonatomic) NSMutableArray *queueSongs;
@property int currentSongIndex;
+ (id)sharedInstance;
@end
