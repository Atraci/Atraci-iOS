//
//  QueueViewController.m
//  Atraci
//
//  Created by Uriel Garcia on 28/06/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import "QueueViewController.h"
#import "QueueSingleton.h"
#import "ArtistCell.h"
#import <MediaPlayer/MediaPlayer.h>
#import "AppDelegate.h"
#import "Playlist.h"
#import "PlaylistSong.h"
#import "ATCSong.h"

@implementation QueueViewController
{
    ATCSong* currentSongObj;
    NSMutableArray *artists, *albums, *tracks, *queue;
    BOOL repeatQueue,shuffleQueue;
    UIAlertView *deleteQueueAlert, *playlistAlert;
}
@synthesize request,isPlaying,mainTable;

+ (instancetype)sharedQueue{
    static id _sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.request = [[RequestClass alloc] init];
    self.request.delegate = self;
    
    // for run application in background
    NSError *setCategoryError = nil;
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &setCategoryError];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemEnded:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    repeatQueue = NO;
    shuffleQueue = NO;
    
    
    //create the image for your button, and set the frame for its size
    UIImage *image = [UIImage imageNamed:@"AtraciLogo.png"];
    CGRect frame = CGRectMake(0, 0, 35, 35);
    
    //init a normal UIButton using that image
    UIButton* button = [[UIButton alloc] initWithFrame:frame];
    [button setBackgroundImage:image forState:UIControlStateNormal];
    [button setShowsTouchWhenHighlighted:YES];
    
    //set the button to handle clicks - this one calls a method called 'downloadClicked'
    [button addTarget:self action:@selector(AtraciTools:) forControlEvents:UIControlEventTouchDown];
    
    //finally, create your UIBarButtonItem using that button
    self.AtraciBarBtn.customView = button;
    
    //Load Main queue
    [self loadPlaylist:@"MainQueue"];
}

-(void)viewDidAppear:(BOOL)animated{
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

-(BOOL)canBecomeFirstResponder
{
    return  YES;
}


- (void)playerItemEnded:(NSNotification *)notification
{
    //NSLog(@"end");
}

#pragma mark - Receive events

- (void) remoteControlReceivedWithEvent: (UIEvent*) event
{
    if (event.type == UIEventTypeRemoteControl) {
        
        switch (event.subtype) {
                
            case UIEventSubtypeRemoteControlNextTrack:
                [self playNextSong];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [self playPreviousSong];
                break;
            default:
                break;
        }
    }

}

- (IBAction)btnPlayPrevious:(id)sender {
    [self playPreviousSong];
}

- (IBAction)btnPlayNext:(id)sender {
    [self playNextSong];
}

#pragma mark -
- (void)loadSongs:(BOOL)load shouldReloadTable:(BOOL)reloadTable withSongPostition:(NSUInteger)songPosition {
    QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];
    queue = queueSingleton.queueSongs;
    
    if (reloadTable == YES) {
        //Reload Table
        [self.mainTable reloadData];
        if ([self.mainTable numberOfRowsInSection:0] > 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:queueSingleton.currentSongIndex inSection: 0];
            [self.mainTable selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            [self.mainTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
        }
    }
    
    if (load == YES) {
        queueSingleton.currentSongIndex = (int)songPosition;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:queueSingleton.currentSongIndex inSection: 0];
        [self.mainTable selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self.mainTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
        
        ATCSong *song = [queue objectAtIndex:songPosition];
        currentSongObj = song;
        NSString *stringToEncode = [NSString stringWithFormat:@"%@ - %@",song.artist,song.title];
        NSString* encoded = [stringToEncode stringByAddingPercentEscapesUsingEncoding:
                             NSASCIIStringEncoding];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://gdata.youtube.com/feeds/api/videos?alt=json&max-results=1&q=%@",encoded]];
        [self.request request:url withSelector:@selector(loadPlayerWithData:)];
        
        [self loadLockScreenAlbumArt:queueSingleton.currentSongIndex];
    }
}

- (void)loadPlayerWithData:(NSData *)data
{
    tabBarItem = [self.tabBarController.tabBar.items objectAtIndex:1];
    NSError *error;
    NSDictionary *songDic = [[NSDictionary alloc] initWithDictionary:[NSJSONSerialization JSONObjectWithData:data options:0 error:&error]];
    NSString *url = [[[[[[songDic objectForKey:@"feed"] objectForKey:@"entry"] firstObject] objectForKey:@"link"] firstObject] objectForKey:@"href"];
    
    NSRange charStart = [url rangeOfString:@"v="];
    NSString *videoID = [url substringFromIndex:charStart.location + charStart.length];
    charStart = [videoID rangeOfString:@"&"];
    videoID = [videoID substringToIndex:charStart.location];
    
    //NSLog(@"%@",videoID);
    
    NSString *videoId = videoID;
    NSDictionary *playerVars = @{
                                 @"controls" : @1,
                                 @"playsinline" : @1,
                                 @"autohide" : @1,
                                 @"showinfo" : @0,
                                 @"modestbranding" : @1,
                                 @"iv_load_policy" : @3,
                                 @"autoplay" : @1
                                 };
    self.playerView.opaque = NO;
    self.playerView.backgroundColor = [UIColor blackColor];
    self.playerView.delegate = self;
    [self.playerView loadWithVideoId:videoId playerVars:playerVars];
    
    double delayInSeconds = 2.8;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [QueueViewController sharedQueue].playerView = self.playerView;
        [self.playerView playVideo];
        //tabBarItem.badgeValue = @"1";
    });
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)playerView:(YTPlayerView *)playerView didChangeToState:(YTPlayerState)state {
    //Always reload lockscreen data due to how the video api performs
    [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(getSongInfo) userInfo:nil repeats:NO];
    
    switch (state) {
        case kYTPlayerStatePlaying:
            NSLog(@"Started playback");
            [QueueViewController sharedQueue].isPlaying = YES;
            
            [self resetPlayerSize];
            break;
        case kYTPlayerStatePaused:
            NSLog(@"Paused playback");
            [QueueViewController sharedQueue].isPlaying = NO;
            break;
        case kYTPlayerStateEnded:
            NSLog(@"Ended playback");
            [QueueViewController sharedQueue].isPlaying = NO;
            [self.playerView stopVideo];
            
            [self playNextSong];
            //tabBarItem.badgeValue = nil;
            break;
        default:
            break;
    }
}

-(void)playNextSong
{
    QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];
    if (shuffleQueue == YES) {
        [self loadSongs:YES shouldReloadTable:NO withSongPostition:arc4random() % queue.count];
    }
    else
    {
        int nextSongPosition = queueSingleton.currentSongIndex + 1;
        if (nextSongPosition < queue.count) {
            [self loadSongs:YES shouldReloadTable:NO withSongPostition:nextSongPosition];
        }
        else{
            if (repeatQueue == YES) {
                [self loadSongs:YES shouldReloadTable:NO withSongPostition:0];
            }
        }
    }
}

-(void)playPreviousSong
{
    QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];
    int previousSongPosition;
    
        float seconds = self.playerView.currentTime;
            if (seconds < 15.0) {
                previousSongPosition = queueSingleton.currentSongIndex - 1;
            } else{
                previousSongPosition = queueSingleton.currentSongIndex;
            }
        if (previousSongPosition < queue.count) {
            [self loadSongs:YES shouldReloadTable:NO withSongPostition:previousSongPosition];
        }
        else{
            if (repeatQueue == YES) {
                [self loadSongs:YES shouldReloadTable:NO withSongPostition:0];
            }
        }
    
}

-(void)getSongInfo
{
    [self setLockSProperties:currentSongObj.artist withSong:currentSongObj.title andAlbumArt:currentSongObj.imageCoverLarge];
}

#pragma mark -
#pragma mark lockscreen media properties
-(void)setLockSProperties:(NSString *)artist withSong:(NSString *)song andAlbumArt:(UIImage *)musicImage
{
    //Step 1: image and track name
    MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage: musicImage];
    
    // Step 2: Create
    NSMutableDictionary* songInfo = [[NSMutableDictionary alloc] init];
    
    songInfo = [[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo] mutableCopy];
    //[songInfo setObject:song forKey:MPMediaItemPropertyTitle];
    //[songInfo setObject:artist forKey:MPMediaItemPropertyArtist];
    //[songInfo setObject:@"Audio Album" forKey:MPMediaItemPropertyAlbumTitle];
    [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
    
    // Step 4: Set now playing info
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
}

#pragma mark -
#pragma mark RequestClass Delegates
- (void)dataReceived:(SEL)selector withObject:(NSData *)data{
    dispatch_sync(dispatch_get_main_queue(), ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:selector withObject:data];
#pragma clang diagnostic pop
    });
}

#pragma mark -
#pragma mark TableView Delegate Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [queue count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier;
    UITableViewCell *cell;
    ArtistCell *cellArtist;
    int rowIndex = (int)indexPath.row;
    
    if (tableView == self.mainTable) {
        CellIdentifier = @"ArtistCell";
        cellArtist = (ArtistCell *)[self.mainTable dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cellArtist == nil) {
            cellArtist = [[ArtistCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        // Configure the cell...
        //Song Artist and Title
        ATCSong *song;
        song = [queue objectAtIndex:rowIndex];
        
        if (song.artist) {
            cellArtist.artistLabel.text = song.artist;
        }
        if (song.title) {
            cellArtist.titleLabel.text = song.title;
        }
        
        //Thumbnail
        cellArtist.thumbnailImageView.image = song.imageCoverMedium;
        
        return cellArtist;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    if (tableView == self.mainTable) {
        [self loadSongs:YES shouldReloadTable:NO withSongPostition:indexPath.row];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];
    if (queueSingleton.currentSongIndex != -1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:queueSingleton.currentSongIndex inSection: 0];
            [tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        });
    }
    
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];
    
    [queue removeObjectAtIndex:indexPath.row];
    [tableView reloadData];
    
    if (indexPath.row == queueSingleton.currentSongIndex) {
        [self.playerView stopVideo];
        queueSingleton.currentSongIndex = -1;
    }
    else{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:queueSingleton.currentSongIndex inSection: 0];
            [tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        });
    }
}

#pragma mark -
- (void)loadLockScreenAlbumArt:(int)index {
    ATCSong *songToUpdate = [queue objectAtIndex:index];
    //Load big image to use in lockscreen
    songToUpdate.imageCoverLarge = [UIImage imageNamed:@"cover_default_large.png"];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Add code here to do background processing
        [songToUpdate setImageCoverLarge];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            // Add code here to update the UI/send notifications based on the
            // results of the background processing
            [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(getSongInfo) userInfo:nil repeats:NO];
        });
    });
}


- (IBAction)repeatQueue:(id)sender {
    repeatQueue = !repeatQueue;
    if (repeatQueue == YES) {
        [_repeatBarBtn setTintColor:[UIColor redColor]];
    }
    else{
        [_repeatBarBtn setTintColor:self.view.tintColor];
    }
}

- (IBAction)shuffleQueue:(id)sender {
    shuffleQueue = !shuffleQueue;
    if (shuffleQueue == YES) {
        [_shuffleBarBtn setTintColor:[UIColor redColor]];
    }
    else{
        [_shuffleBarBtn setTintColor:self.view.tintColor];
    }
}

- (IBAction)AtraciTools:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Load Playlist",@"Save Playlist",@"Delete Queue", nil];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

#pragma mark -
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                               duration:(NSTimeInterval)duration
{
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
        toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        self.toolbar.hidden = YES;
        self.tabBarController.tabBar.hidden = YES;
        [self.playerView.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('player').height = screen.width;"];
    }
    else
    {
        self.toolbar.hidden = NO;
        self.tabBarController.tabBar.hidden = NO;
        [self.playerView.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('player').height=\"100%\";"];
    }
}

//Used only when player loads another song while device is in landscape, since the web view's iframe is loaded again, we need to modify the height again.
- (void)resetPlayerSize {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        [self.playerView.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('player').height = screen.width;"];
    }
}

#pragma mark -
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 3) {
        
        switch (buttonIndex) {
            case 0:

                break;
            case 1:
                if (queue.count > 0) {
                    playlistAlert = [[UIAlertView alloc] initWithTitle:@"Playlist Name:" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
                    [playlistAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
                    [playlistAlert show];
                }
                break;
            case 2:
                deleteQueueAlert = [[UIAlertView alloc] initWithTitle:@"¿Proceed on clearing the queue?" message:@"" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes",nil];
                [deleteQueueAlert show];
                
                break;
            default:
                break;
        }
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSLog(@"Cancel Tapped.");
    }
    else if (buttonIndex == 1) {
        if(alertView == playlistAlert)
        {
            //handle save playlist with current queue
            [self savePlaylist];
        }
        else
        {
            QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];
            [QueueViewController sharedQueue].isPlaying = NO;
            queueSingleton.currentSongIndex = 0;
            [queueSingleton.queueSongs removeAllObjects];
            [queue removeAllObjects];
            [self.mainTable reloadData];
            [self.playerView stopVideo];
            [self.playerView clearVideo];
            
            //Delete MainQueue Playlist
            [self deletePlaylist:@"MainQueue"];
        }
    }
}

- (void)didPresentAlertView:(UIAlertView *)alertView {
    if(alertView == playlistAlert)
    {
        [[alertView textFieldAtIndex:0] becomeFirstResponder];//not working, probably we need to create a custom alert view with uitextfield
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    if(alertView == playlistAlert)
    {
        NSString *inputText = [[alertView textFieldAtIndex:0] text];
        if( [inputText length] >= 1 )
        {
            return YES;
        }
        else
        {
            return NO;
        }
    }
    return YES;
}

#pragma mark - playlist events
- (void)deletePlaylist:(NSString *)playlistName
{
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
    }
    else
    {
        match = objects[0];
        [context deleteObject:match];
        
        NSError *error = nil;
        if (![context save:&error])
        {
            NSLog(@"Error deleting movie, %@", [error userInfo]);
        }
    }
}

-(void)savePlaylist
{
    NSString *inputText = [[playlistAlert textFieldAtIndex:0] text];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    //if Playlist is Main Queue return
    BOOL isMainQueueOrExists = NO;
    if ([inputText isEqualToString:@"MainQueue"]) {
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Playlist" inManagedObjectContext:context];
        NSFetchRequest *fRequest = [[NSFetchRequest alloc] init];
        [fRequest setEntity:entityDesc];
        
        //Criteria
            NSPredicate *pred =[NSPredicate predicateWithFormat:
                                @"(name = %@)", @"MainQueue"];
            [fRequest setPredicate:pred];
        NSError *error;
        NSArray *objects = [context executeFetchRequest:fRequest
                                                  error:&error];
        
        if ([objects count] > 0)
        {
            isMainQueueOrExists = YES;
        }
    }

    if (isMainQueueOrExists == NO) {
        
        //---Add playlist to entity---//
        NSEntityDescription *playlistEntityDesc = [NSEntityDescription entityForName:@"Playlist" inManagedObjectContext:context];

        Playlist *playlist = (Playlist *)[[NSManagedObject alloc] initWithEntity:playlistEntityDesc
                                                  insertIntoManagedObjectContext:context];

        [playlist setValue:inputText forKey:@"name"];

        //---Add playlist song to entity---//
        PlaylistSong *playlistSong;
        for (ATCSong* song in queue) {
            playlistSong = [self addPlaylistSong:context withSong:song playlist:playlist];
        }

        // Save Managed Object Context
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unable to save managed object context.");
            NSLog(@"%@, %@", error, error.localizedDescription);
        }
        
        NSLog(@"%@",[playlist objectID]);
    }
}

- (PlaylistSong *)addPlaylistSong:(NSManagedObjectContext *)context withSong:(ATCSong*)song playlist:(Playlist *)playlist
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

-(void)loadPlaylist:(NSString *)playlistName
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Playlist" inManagedObjectContext:context];
    NSFetchRequest *fRequest = [[NSFetchRequest alloc] init];
    [fRequest setEntity:entityDesc];
    
    //Criteria
    if ([playlistName isEqualToString:@"MainQueue"]) {
        NSPredicate *pred =[NSPredicate predicateWithFormat:
                            @"(name = %@)", playlistName];
        [fRequest setPredicate:pred];
    }

    NSManagedObject *match = nil;
    
    NSError *error;
    NSArray *objects = [context executeFetchRequest:fRequest
                                              error:&error];
    
    if ([objects count] == 0)
    {
        NSLog(@"No matches for playlist: %@", playlistName);
    }
    else
    {
        for (int i = 0; i < [objects count]; i++)
        {
            match = objects[i];
            //Fetch Playlist Songs
            Playlist *playlist = (Playlist *)match;
            NSSet *set = [playlist playlistSong];
            
            queue = [[NSMutableArray alloc] init];
            
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
                            [self.mainTable reloadData];
                            
                            if ([self.mainTable numberOfRowsInSection:0] > 0) {
                                [self.mainTable deselectRowAtIndexPath:0 animated:NO];
                            }
                            
                            QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];
                            queueSingleton.queueSongs = queue;
                        }
                    });
                });
            }
        }
    }
}

@end
