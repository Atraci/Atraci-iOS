//
//  QueueSingleton.m
//  Atraci
//
//  Created by Uriel Garcia on 12/07/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import "QueueSingleton.h"

@implementation QueueSingleton
@synthesize queueSongs, currentSongIndex;

static QueueSingleton *sharedInstance = nil;

// Get the shared instance and create it if necessary.
+ (QueueSingleton *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    
    return sharedInstance;
}

// We can still have a regular init method, that will get called the first time the Singleton is used.
- (id)init
{
    self = [super init];
    
    if (self) {
        // Work your initialising magic here as you normally would
        queueSongs = [[NSMutableArray alloc] init];
        currentSongIndex = 0;
    }
    
    return self;
}

// We don't want to allocate a new instance, so return the current one.
+ (id)allocWithZone:(NSZone*)zone {
    return [self sharedInstance];
}

// Equally, we don't want to generate multiple copies of the singleton.
- (id)copyWithZone:(NSZone *)zone {
    return self;
}
@end
