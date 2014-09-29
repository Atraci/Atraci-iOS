//
//  Playlist.h
//  Atraci
//
//  Created by Uriel Garcia on 28/09/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Playlist : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *playlistSong;
@end

@interface Playlist (CoreDataGeneratedAccessors)

- (void)addPlaylistSongObject:(NSManagedObject *)value;
- (void)removePlaylistSongObject:(NSManagedObject *)value;
- (void)addPlaylistSong:(NSSet *)values;
- (void)removePlaylistSong:(NSSet *)values;

@end
