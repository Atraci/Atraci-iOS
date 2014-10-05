//
//  ATCPlaylistHelper.m
//  Atraci
//
//  Created by Uriel Garcia on 04/10/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import "ATCPlaylistHelper.h"
#import "AppDelegate.h"
#import "Playlist.h"
#import "PlaylistSong.h"
#import "ATCSong.h"
#import "QueueSingleton.h"

@implementation ATCPlaylistHelper
@synthesize delegate, recordsFound;

-(id)init {
    if ( self = [super init] ) {

    }
    return self;
}

#pragma mark -
//#pragma mark -
+(BOOL)setPlaylist:(NSString *)playlistName withSongQueue:(NSMutableArray *)queue
{
    BOOL isSuccessful = YES;
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    if ([ATCPlaylistHelper getPlaylist:playlistName withPredicate:nil] == YES) {
        [ATCPlaylistHelper deletePlaylist:playlistName];
    }
    
    //---Add playlist to entity---//
    NSEntityDescription *playlistEntityDesc = [NSEntityDescription entityForName:@"Playlist" inManagedObjectContext:context];
    
    Playlist *playlist = (Playlist *)[[NSManagedObject alloc] initWithEntity:playlistEntityDesc
                                              insertIntoManagedObjectContext:context];
    
    [playlist setValue:playlistName forKey:@"name"];
    
    //---Add playlist song to entity---//
    PlaylistSong *playlistSong;
    for (ATCSong* song in queue) {
        playlistSong = [ATCPlaylistHelper addPlaylistSong:context withSong:song playlist:playlist];
    }
    
    // Save Managed Object Context
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unable to save managed object context.");
        NSLog(@"%@, %@", error, error.localizedDescription);
        
        isSuccessful = NO;
    }
    
    NSLog(@"%@",[playlist objectID]);
    
    return isSuccessful;
}

+ (PlaylistSong *)addPlaylistSong:(NSManagedObjectContext *)context withSong:(ATCSong*)song playlist:(Playlist *)playlist
{
    //---Add playlist song to entity---//
    NSEntityDescription *playlistSongEntityDesc = [NSEntityDescription entityForName:@"PlaylistSong" inManagedObjectContext:context];
    
    PlaylistSong *playlistSong = (PlaylistSong *)[[NSManagedObject alloc] initWithEntity:playlistSongEntityDesc
                                                          insertIntoManagedObjectContext:context];
    
    [playlistSong setValue:song.artist forKey:@"artist"];
    [playlistSong setValue:song.title forKey:@"title"];
    [playlistSong setValue:[song.urlCoverMedium absoluteString] forKey:@"coverMedium"];
    [playlistSong setValue:[song.urlCoverLarge absoluteString] forKey:@"coverLarge"];
    
    //---Creating a Relationship between entitiy records---//
    [playlist addPlaylistSongObject:playlistSong];
    NSLog(@"%@",[playlistSong objectID]);
    
    return playlistSong;
}

+(BOOL)getPlaylist:(NSString *)playlistName withPredicate:(NSPredicate *)predicate
{
    BOOL isSuccessful = YES;
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Playlist" inManagedObjectContext:context];
    NSFetchRequest *fRequest = [[NSFetchRequest alloc] init];
    [fRequest setEntity:entityDesc];
    
    //Criteria
    if (predicate != nil) {
        [fRequest setPredicate:predicate];
    }
    
    NSPredicate *predicatePlaylistName =[NSPredicate predicateWithFormat:
                                         @"(name = %@)", playlistName];
    [fRequest setPredicate:predicatePlaylistName];
    
    NSError *error;
    NSArray *objects = [context executeFetchRequest:fRequest
                                              error:&error];
    
    if ([objects count] == 0)
    {
        NSLog(@"No matches for playlist: %@", playlistName);
        isSuccessful = NO;
    }
    return isSuccessful;
}

-(BOOL)getPlaylist:(NSString *)playlistName withPredicate:(NSPredicate *)predicate andSongs:(BOOL)getSongs
{
    BOOL isSuccessful = YES;
    self.recordsFound = YES;
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Playlist" inManagedObjectContext:context];
    NSFetchRequest *fRequest = [[NSFetchRequest alloc] init];
    [fRequest setEntity:entityDesc];
    
    //Criteria
    if (predicate != nil) {
        [fRequest setPredicate:predicate];
    }
    
    NSPredicate *predicatePlaylistName =[NSPredicate predicateWithFormat:
                             @"(name = %@)", playlistName];
    [fRequest setPredicate:predicatePlaylistName];
    
    NSError *error;
    NSArray *objects = [context executeFetchRequest:fRequest
                                              error:&error];
    
    if ([objects count] == 0)
    {
        NSLog(@"No matches for playlist: %@", playlistName);
        isSuccessful = NO;
    }
    else
    {
        if (getSongs == YES) {
            NSManagedObject *match = nil;
            NSMutableArray *queue = [[NSMutableArray alloc] init];

            for (int i = 0; i < [objects count]; i++)
            {
                match = objects[i];
                //Fetch Playlist Songs
                Playlist *playlist = (Playlist *)match;
                NSSet *set = playlist.playlistSong;
                
                if (set.count == 0) {
                    self.recordsFound = NO;
                }
                else
                {
                    for (PlaylistSong *plsSong in set) {
                        ATCSong *song = [[ATCSong alloc] init];
                        song.artist = plsSong.artist;
                        song.title = plsSong.title;
                        song.urlCoverMedium = (id)plsSong.coverMedium;
                        song.urlCoverLarge = (id)plsSong.coverLarge;
                        song.imageCoverMedium = [UIImage imageNamed:@"cover_default_large.png"];
                        
                        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            // Add code here to do background processing
                            [song setImageCoverMedium];
                            [queue addObject:song];
                            
                            dispatch_async( dispatch_get_main_queue(), ^{
                                // Add code here to update the UI/send notifications based on the
                                // results of the background processing
                                if (queue.count == set.count) {
                                    QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];
                                    queueSingleton.queueSongs = queue;
                                    
                                    //Relaod table
                                    [self.delegate reloadQueueDelegate];
                                }
                            });
                        });
                    }
                }
            }
        }
    }
    return isSuccessful;
}

+(BOOL)deletePlaylist:(NSString *)playlistName
{
    BOOL isSuccessful = YES;
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    //Delete Playlist
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Playlist" inManagedObjectContext:context];
    NSFetchRequest *fRequest = [[NSFetchRequest alloc] init];
    [fRequest setEntity:entityDesc];
    
    NSPredicate *pred =[NSPredicate predicateWithFormat:
                        @"(name = %@)", playlistName];
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

@end
