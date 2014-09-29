//
//  PlaylistSong.h
//  Atraci
//
//  Created by Uriel Garcia on 28/09/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Playlist;

@interface PlaylistSong : NSManagedObject

@property (nonatomic, retain) NSString * artist;
@property (nonatomic, retain) NSString * coverLarge;
@property (nonatomic, retain) NSString * coverMedium;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) Playlist *playlist;

@end
