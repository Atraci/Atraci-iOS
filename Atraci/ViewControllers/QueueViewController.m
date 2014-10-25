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

@implementation QueueViewController
{
    NSMutableArray *artists, *albums, *tracks, *queue;
    BOOL repeatQueue,repeatSong,shuffleQueue, isQueueTab;
    UIAlertView *deleteQueueAlert, *playlistAlert;
    UIActionSheet *actionSheetPlayerOptions, *actionSheetPlaylistAction;
    UIBarButtonItem *barButtonItemBackup;
    NSDictionary *playerVars;
}
@synthesize request,isPlaying,mainTable,shoudDisplayHUD,currentSongObj;

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
    
    //LoadPlayerVars
    [self loadPlayerVars];
    
    self.request = [[RequestClass alloc] init];
    self.request.delegate = self;
    
    repeatQueue = NO;
    repeatSong = NO;
    shuffleQueue = NO;
    
    //finally, create your UIBarButtonItem using that button
    self.PlayListBtn.target = self;
    self.PlayListBtn.action = @selector(playlistAction:);
    
    //create the image for your button, and set the frame for its size
    UIImage *imagePlay = [UIImage imageNamed:@"Play"];
    UIImage *imagePause = [UIImage imageNamed:@"Pause"];
    CGRect frame = CGRectMake(0, 0, 25, 25);

    //init a normal UIButton using that image
    UIButton* button = [[UIButton alloc] initWithFrame:frame];
    [button setBackgroundImage:imagePlay forState:UIControlStateNormal];
    [button setBackgroundImage:imagePause forState:UIControlStateSelected];
    [button setShowsTouchWhenHighlighted:YES];

    //set the button to handle clicks - this one calls a method called 'downloadClicked'
    [button addTarget:self action:@selector(playPause:) forControlEvents:UIControlEventTouchDown];

    //finally, create your UIBarButtonItem using that button
    self.PlayPauseBtn.customView = button;
    
    self.tabBarController.delegate = self;
    self.fixedSpace.width = 0.0;
}

- (void)tabBarController:(UITabBarController *)tabBarController
 didSelectViewController:(UIViewController *)viewController
{
    if ([viewController isEqual:self] == YES) {
        //Set selected song index
        if (isQueueTab == YES) {
            QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:queueSingleton.currentSongIndex inSection: 0];
            
            if (queueSingleton.queueSongs.count > 0) {
                [self.mainTable selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                [self.mainTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
            }
        }
        isQueueTab = YES;
    }
    else
    {
        isQueueTab = NO;
    }
}

-(void)viewDidAppear:(BOOL)animated{
    
    if (self.shoudDisplayHUD == YES && queue.count == 0) {
        [SVProgressHUD show];
    }
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

-(BOOL)canBecomeFirstResponder
{
    return  YES;
}

-(void)loadPlayerVars
{
    playerVars = @{
                   @"controls" : @1,
                   @"playsinline" : @1,
                   @"autohide" : @1,
                   @"showinfo" : @0,
                   @"modestbranding" : @1,
                   @"iv_load_policy" : @3,
                   @"autoplay" : @1,
                   @"rel": @0
                   };
    self.playerView.opaque = NO;
    self.playerView.backgroundColor = [UIColor blackColor];
    self.playerView.delegate = self;
}

//required delegate from defined protocol
-(void)reloadQueueDelegate
{
    [self loadSongs:NO shouldReloadTable:YES withSongPostition:0];
    [SVProgressHUD dismiss];
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
        [self hidePlayPauseBarButtonItem];
        [self.ActivityIndicator startAnimating];
        UIButton* button = (UIButton *)self.PlayPauseBtn.customView;
        [button setSelected:YES];
        
        queueSingleton.currentSongIndex = (int)songPosition;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:queueSingleton.currentSongIndex inSection: 0];
        [self.mainTable selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self.mainTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
        
        ATCSong *song = [queue objectAtIndex:songPosition];
        currentSongObj = song;
        NSString *stringToEncode = [NSString stringWithFormat:@"%@ - %@",song.artist,song.title];
        NSString* encoded = [stringToEncode stringByAddingPercentEscapesUsingEncoding:
                             NSUTF8StringEncoding];
        
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
    
    if (url == nil) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"sNotAvailable", nil)];
        [self playNextSong];
        [self showPlayPauseBarButtonItem];
        [self.ActivityIndicator stopAnimating];
        UIButton* button = (UIButton *)self.PlayPauseBtn.customView;
        [button setSelected:NO];
    }
    else
    {
        NSRange charStart = [url rangeOfString:@"v="];
        NSString *videoID = [url substringFromIndex:charStart.location + charStart.length];
        charStart = [videoID rangeOfString:@"&"];
        videoID = [videoID substringToIndex:charStart.location];
        
        //NSLog(@"%@",videoID);
        [QueueViewController sharedQueue].playerView = self.playerView;
        [self performSelectorOnMainThread:@selector(playInBackgroundStepOne:) withObject:videoID waitUntilDone:YES];
        [self playInBackgroundStepOneB];
    }
}

//--
- (void)playInBackgroundStepOne:(NSString *)videoID
{
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier background_task;
    background_task = [application beginBackgroundTaskWithExpirationHandler: ^{
        [application endBackgroundTask: background_task];
        background_task = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self performSelectorOnMainThread:@selector(playInBackgroundStepTwo:) withObject:videoID waitUntilDone:YES];
        
        [application endBackgroundTask: background_task];
        background_task = UIBackgroundTaskInvalid;
    });
}

-(void)playInBackgroundStepTwo:(NSString *)videoID
{
    [self.playerView loadWithVideoId:videoID playerVars:playerVars];
}

- (void)playInBackgroundStepOneB
{
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier background_task;
    background_task = [application beginBackgroundTaskWithExpirationHandler: ^{
        [application endBackgroundTask: background_task];
        background_task = UIBackgroundTaskInvalid;
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      //  [self performSelectorOnMainThread:@selector(playInBackgroundStepTwoB) withObject:nil waitUntilDone:YES];
                double delayInSeconds = 3;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                //for run application in background
                    [self playInBackgroundStepTwoB];
                });
        [application endBackgroundTask: background_task];
        background_task = UIBackgroundTaskInvalid;
    });
}

-(void)playInBackgroundStepTwoB
{
   // [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
          [self.playerView playVideo];
   // }];
}
//--

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)playerView:(YTPlayerView *)playerView didChangeToState:(YTPlayerState)state {
    
    UIButton *button;
    
    switch (state) {
        case kYTPlayerStatePlaying:
            NSLog(@"Started playback");
            [QueueViewController sharedQueue].isPlaying = YES;
            button = (UIButton *)self.PlayPauseBtn.customView;
            [button setSelected:YES];
            
            [self.ActivityIndicator stopAnimating];
            [self showPlayPauseBarButtonItem];
            
            [self resetPlayerSize];
            
            //Always reload lockscreen data due to how the video api performs
            [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(getSongInfo) userInfo:nil repeats:NO];
            [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(getSongInfo) userInfo:nil repeats:NO];
            break;
        case kYTPlayerStatePaused:
            NSLog(@"Paused playback");
            [QueueViewController sharedQueue].isPlaying = NO;
            button = (UIButton *)self.PlayPauseBtn.customView;
            [button setSelected:NO];
            
            //Always reload lockscreen data due to how the video api performs
            [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(getSongInfo) userInfo:nil repeats:NO];
            break;
        case kYTPlayerStateEnded:
            NSLog(@"Ended playback");
            [QueueViewController sharedQueue].isPlaying = NO;
            button = (UIButton *)self.PlayPauseBtn.customView;
            [button setSelected:YES];
            
            if (repeatSong == YES) {
                [self.playerView seekToSeconds:0.0 allowSeekAhead:YES];
            }
            else
            {
                [self playNextSong];
            }
            
            break;
        case kYTPlayerStateBuffering:
            [self hidePlayPauseBarButtonItem];
            [self.ActivityIndicator startAnimating];
            break;
        default:
            break;
    }
}

- (void)showPlayPauseBarButtonItem{
    
    NSMutableArray * toolbarButtonItems = [NSMutableArray arrayWithArray:
                                           [self.toolbar items]];
    
    BOOL found = NO;
    
    for(UIBarButtonItem * tmpButton in toolbarButtonItems){
        
        if([tmpButton tag] == 1){ //settings button.
            
            //keep it
            found = YES;
            break;
        }
    }
    
    if(found == NO){
        [toolbarButtonItems insertObject:barButtonItemBackup atIndex:4]; //insert item at index you like.
        
        [self.toolbar setItems:toolbarButtonItems];
        self.fixedSpace.width = 0.0;
    }
}

- (void)hidePlayPauseBarButtonItem{
    NSMutableArray * toolbarButtonItems = [NSMutableArray arrayWithArray:
                                           [self.toolbar items]];
    
    BOOL found = NO;
    
    for(UIBarButtonItem * tmpButton in toolbarButtonItems){
        
        if([tmpButton tag] == 1){ //settings button tag. set in IB.
            
            found = YES;
            barButtonItemBackup = tmpButton; //save it for later.
            //should keep a reference to your VC.
            
            [toolbarButtonItems removeObject:tmpButton];
            self.fixedSpace.width = 35.0;
            
            break;
        }
    }
    
    if(found == YES){
        [self.toolbar setItems:toolbarButtonItems];
    }
}

-(void)playNextSong
{
    if (shuffleQueue == YES) {
        [self loadSongs:YES shouldReloadTable:NO withSongPostition:arc4random() % queue.count];
    }
    else
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            //Your code goes in here
            NSLog(@"Main Thread Code");
            QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];
            int nextSongPosition = queueSingleton.currentSongIndex + 1;
            if (nextSongPosition < queue.count) {
                [self loadSongs:YES shouldReloadTable:NO withSongPostition:nextSongPosition];
            }
            else{
                if (repeatQueue == YES) {
                    [self loadSongs:YES shouldReloadTable:NO withSongPostition:0];
                }
            }
        }];
    }
}

-(void)playPreviousSong
{
    int previousSongPosition;
    float seconds = self.playerView.currentTime;
    QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];

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
    [self setLockSProperties:self.currentSongObj.artist withSong:self.currentSongObj.title andAlbumArt:self.currentSongObj.imageCoverLarge];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
    });
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
        UIButton *button = (UIButton *)self.PlayPauseBtn.customView;
        [button setSelected:YES];
        
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

    self.shoudDisplayHUD = NO;
    [queue removeObjectAtIndex:indexPath.row];
    [tableView reloadData];
    QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];
    
    if (indexPath.row == queueSingleton.currentSongIndex) {
        [self.playerView stopVideo];
        queueSingleton.currentSongIndex = -1;
    }
    else{
        if (indexPath.row < queueSingleton.currentSongIndex) {
            queueSingleton.currentSongIndex = queueSingleton.currentSongIndex - 1;
        }
        
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


- (IBAction)playPause:(id)sender {
    UIButton *button;
    
    if ([self.playerView playerState] == kYTPlayerStatePlaying) {
        [self.playerView pauseVideo];
        
        button = (UIButton *)self.PlayPauseBtn.customView;
        [button setSelected:NO];
    }
    else if([self.playerView playerState] == kYTPlayerStatePaused)
    {
        [self.playerView playVideo];
        
        button = (UIButton *)self.PlayPauseBtn.customView;
        [button setSelected:YES];
    }
    else if([self.playerView playerState] == kYTPlayerStateUnknown)
    {
        QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];
        if (queueSingleton.queueSongs.count > 0) {
            [self loadSongs:YES shouldReloadTable:NO withSongPostition:queueSingleton.currentSongIndex];
            
            button = (UIButton *)self.PlayPauseBtn.customView;
            [button setSelected:YES];
        }
    }
}

- (IBAction)playerOptions:(id)sender {
    NSString *shuffleState = @"Shuffle is Off";
    NSString *repeatState = @"Repeat All is Off";
    NSString *repeatSongState = @"Repeat Song is Off";
    
    if (shuffleQueue == YES) {
        shuffleState = @"Shuffle ✓";
    }
    
    if (repeatQueue == YES) {
        repeatState = @"Repeat All ✓";
    }
    
    if (repeatSong == YES) {
        repeatSongState = @"Repeat Song ✓";
    }
    
    actionSheetPlayerOptions = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:shuffleState,repeatState,repeatSongState, nil];
    [actionSheetPlayerOptions showFromTabBar:self.tabBarController.tabBar];
}

- (IBAction)playlistAction:(id)sender {
    actionSheetPlaylistAction = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"lPlaylist", nil),NSLocalizedString(@"sPlaylist", nil),NSLocalizedString(@"dQueue", nil), nil];

    [actionSheetPlaylistAction showFromTabBar:self.tabBarController.tabBar];

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
    if (actionSheet == actionSheetPlaylistAction) {
        if (buttonIndex != 3) {
            switch (buttonIndex) {
                case 0:
                    [self performSegueWithIdentifier:@"PlaylistsSegue" sender:self];
                    break;
                case 1:
                    if (queue.count > 0) {
                        playlistAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"pName", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"save", nil), nil];
                        [playlistAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
                        [playlistAlert show];
                    }
                    break;
                    
                case 2:
                    deleteQueueAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"pClear", nil)message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"no", nil) otherButtonTitles:NSLocalizedString(@"yes", nil),nil];
                    [deleteQueueAlert show];
                    break;
                default:
                    break;
            }
        }
    }
    else if (actionSheet == actionSheetPlayerOptions)
    {
        if (buttonIndex != 3) {
            
            switch (buttonIndex) {
                case 0:
                    shuffleQueue = !shuffleQueue;
                    break;
                case 1:
                    repeatQueue = !repeatQueue;
                    break;
                case 2:
                    repeatSong = !repeatSong;
                    break;
                default:
                    break;
            }
            
            if (shuffleQueue == YES || repeatQueue == YES || repeatSong == YES) {
                [self.PlayerOptionsBtn setTintColor:[UIColor blueColor]];
            }
            else
            {
                [self.PlayerOptionsBtn setTintColor:self.view.tintColor];
            }

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
            NSString *inputText = [[playlistAlert textFieldAtIndex:0] text];
            if([ATCPlaylistHelper setPlaylist:inputText withSongQueue:queue])
            {
                [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat: NSLocalizedString(@"pSaved", nil),inputText]];
            }
        }
        else
        {
            UIButton *button = (UIButton *)self.PlayPauseBtn.customView;
            [button setSelected:NO];
            
            self.shoudDisplayHUD = NO;
            [QueueViewController sharedQueue].isPlaying = NO;
            QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];
            queueSingleton.currentSongIndex = 0;
            [queueSingleton.queueSongs removeAllObjects];
            [queue removeAllObjects];
            [self.mainTable reloadData];
            [self.playerView stopVideo];
            [self.playerView clearVideo];
            
            //Delete MainQueue Playlist
            [ATCPlaylistHelper deletePlaylist:ATRACI_PLAYLIST_MAINQUEUE];
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
@end
