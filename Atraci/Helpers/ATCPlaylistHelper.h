//
//  ATCPlaylistHelper.h
//  Atraci
//
//  Created by Uriel Garcia on 04/10/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ATCPlaylistHelperDelegate <NSObject>   //define delegate protocol
@required
- (void) reloadQueueDelegate;  //define delegate method to be implemented within another class
@end //end protocol

@interface ATCPlaylistHelper : NSObject

@property BOOL recordsFound;
@property (nonatomic, weak) id <ATCPlaylistHelperDelegate> delegate; //define ATCPlaylistHelperDelegate as delegate
+(BOOL)setPlaylist:(NSString *)playlistName withSongQueue:(NSMutableArray *)queue;
-(BOOL)getPlaylist:(NSString *)playlistName withPredicate:(NSPredicate *)predicate andSongs:(BOOL)getSongs;
+(BOOL)deletePlaylist:(NSString *)playlistName;
@end
