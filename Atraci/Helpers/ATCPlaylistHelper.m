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
#import "AppSetting.h"
#import "ATCSong.h"
#import "QueueSingleton.h"

@implementation ATCPlaylistHelper
@synthesize delegate, recordsFound;

static ATCPlaylistHelper *sharedInstance = nil;

// Get the shared instance and create it if necessary.
+ (ATCPlaylistHelper *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    
    return sharedInstance;
}

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
    
    Playlist *playlist = [ATCPlaylistHelper getPlaylist:playlistName withPredicate:nil];
    
    if (playlist != nil) {
        //just delete the songs
        [ATCPlaylistHelper deletePlaylistSongs:playlistName];
        
    }else{
        //---Add playlist to entity---//
        NSEntityDescription *playlistEntityDesc = [NSEntityDescription entityForName:@"Playlist" inManagedObjectContext:context];
        
        playlist = (Playlist *)[[NSManagedObject alloc] initWithEntity:playlistEntityDesc
                                        insertIntoManagedObjectContext:context];
        
        [playlist setValue:playlistName forKey:@"name"];
    }
    
    //---Add playlist song to entity---//
    PlaylistSong *playlistSong;
    for (ATCSong* song in queue) {
        playlistSong = [ATCPlaylistHelper addPlaylistSong:context withSong:song playlist:playlist];
        
        // Save Managed Object Context
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unable to save managed object context.");
            NSLog(@"%@, %@", error, error.localizedDescription);
            
            isSuccessful = NO;
        }
    }
    
    NSLog(@"%@",[playlist objectID]);
    
    return isSuccessful;
}

+ (PlaylistSong *)addPlaylistSong:(NSManagedObjectContext *)context withSong:(ATCSong*)song playlist:(Playlist *)playlist
{
    //---Add playlist song to entity---//
    PlaylistSong *playlistSong = [NSEntityDescription insertNewObjectForEntityForName:@"PlaylistSong"  inManagedObjectContext:context];
    
    [playlistSong setValue:song.artist forKey:@"artist"];
    [playlistSong setValue:song.title forKey:@"title"];
    [playlistSong setValue:[song.urlCoverMedium absoluteString] forKey:@"coverMedium"];
    [playlistSong setValue:[song.urlCoverLarge absoluteString] forKey:@"coverLarge"];
    
    //---Creating a Relationship between entitiy records---//
    [playlist addPlaylistSongObject:playlistSong];
    NSLog(@"%@",[playlistSong objectID]);
    
    return playlistSong;
}

+(NSArray *)getAllPlaylists
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Playlist" inManagedObjectContext:context];
    NSFetchRequest *fRequest = [[NSFetchRequest alloc] init];
    [fRequest setEntity:entityDesc];
    
    //Get All Except MainQueue
    NSPredicate *predicatePlaylistName =[NSPredicate predicateWithFormat:
                                         @"(name != %@)", ATRACI_PLAYLIST_MAINQUEUE];
    [fRequest setPredicate:predicatePlaylistName];
    
    NSError *error;
    NSArray *objects = [context executeFetchRequest:fRequest
                                              error:&error];
    
    if ([objects count] == 0)
    {
        NSLog(@"No playlists");
    }
    
    return objects;
}

+(Playlist *)getPlaylist:(NSString *)playlistName withPredicate:(NSPredicate *)predicate
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
        
        return nil;
    }
    
    return [objects firstObject];
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
                    //Order by Id
                    NSArray *sortedSet = [[set allObjects] sortedArrayUsingComparator:^NSComparisonResult(NSManagedObject *obj1, NSManagedObject *obj2) {
                        
                        NSString *s = [obj1.objectID.URIRepresentation lastPathComponent];
                        NSString *r = [obj2.objectID.URIRepresentation lastPathComponent];
                        return [s compare:r];
                        
                    }];
                    
                    __block int songsCount = 0;
                    
                    for (PlaylistSong *plsSong in sortedSet) {
                        ATCSong *song = [[ATCSong alloc] init];
                        song.artist = plsSong.artist;
                        song.title = plsSong.title;
                        song.urlCoverMedium = (id)plsSong.coverMedium;
                        song.urlCoverLarge = (id)plsSong.coverLarge;
                        song.imageCoverMedium = [UIImage imageNamed:@"cover_default_large.png"];
                        [queue addObject:song];
                        
                        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            // Add code here to do background processing
                            [song setImageCoverMedium];
                            
                            dispatch_async( dispatch_get_main_queue(), ^{
                                // Add code here to update the UI/send notifications based on the
                                // results of the background processing
                                songsCount = songsCount + 1;
                                
                                if (songsCount == sortedSet.count) {
                                    QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];
                                    queueSingleton.queueSongs = queue;
                                    
                                    //Set lastPlayed Index
                                    if ([playlistName isEqualToString:ATRACI_PLAYLIST_MAINQUEUE] == YES) {
                                        AppSetting *appSetting = [AppSetting alloc];
                                        appSetting = [appSetting getSettingforKey:@"LAST_PLAYED_SONG"];
                                        QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];
                                        queueSingleton.currentSongIndex = [appSetting.value intValue];
                                    }
                                    
                                    //Reload table
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

+(BOOL)deletePlaylistSongs:(NSString *)playlistName
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
        NSManagedObject *match = nil;
        match = objects[0];
        
        //Fetch Playlist Songs
        Playlist *playlist = (Playlist *)match;
        NSSet *set = playlist.playlistSong;
        
        for (PlaylistSong *plsSong in set) {
            [context deleteObject:plsSong];
        }
        
        NSError *error = nil;
        if (![context save:&error])
        {
            isSuccessful = NO;
            NSLog(@"Error deleting, %@", [error userInfo]);
            return isSuccessful;
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
