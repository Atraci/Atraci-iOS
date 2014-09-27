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
    NSDictionary* currentSongObj;
    NSMutableArray *artists, *albums, *tracks, *thumbnails, *queue;
    BOOL repeatQueue,shuffleQueue;
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
    
    thumbnails = [[NSMutableArray alloc] init];
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
    
    [thumbnails removeAllObjects];
    
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
        [self loadLockScreenAlbumArt:queueSingleton.currentSongIndex];
        
        currentSongObj = [[NSDictionary alloc] initWithDictionary:[queue objectAtIndex:songPosition]];
        
        NSString *artist = [currentSongObj objectForKey:@"artist"];
        NSString *title = [currentSongObj objectForKey:@"title"];
        NSString *stringToEncode = [NSString stringWithFormat:@"%@ - %@",artist,title];
        NSString* encoded = [stringToEncode stringByAddingPercentEscapesUsingEncoding:
                             NSASCIIStringEncoding];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://gdata.youtube.com/feeds/api/videos?alt=json&max-results=1&q=%@",encoded]];
        [self.request request:url withSelector:@selector(loadPlayerWithData:)];
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
    NSString *artist = [currentSongObj objectForKey:@"artist"];
    NSString *title = [currentSongObj objectForKey:@"title"];
    UIImage* musicImage = [currentSongObj objectForKey:@"cover_url_large"];
    
    [self setLockSProperties:artist withSong:title andAlbumArt:musicImage];
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

- (void)getThumbImage:(int)indexRow andArtistCell:(ArtistCell *)cellArtist
{
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Add code here to do background processing
        //request album art
        id imageUrl = [[queue objectAtIndex:indexRow] objectForKey:@"cover_url_medium"];
        if (imageUrl != [NSNull null] && imageUrl != nil) {
            NSURL *imgUrl = [NSURL URLWithString:imageUrl];
            NSData *imgData = [NSData dataWithContentsOfURL:imgUrl];
            UIImage *image = [UIImage imageWithData:imgData];
            
            if (image != nil) {
                [thumbnails addObject:image];
                
                dispatch_async( dispatch_get_main_queue(), ^{
                    // Add code here to update the UI/send notifications based on the
                    // results of the background processing
                    cellArtist.thumbnailImageView.image = (UIImage *)image;
                });
            }
        }
    });
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
        
        if (rowIndex < thumbnails.count) {
            cellArtist.thumbnailImageView.image = [thumbnails objectAtIndex:rowIndex];
        }
        else
        {
            cellArtist.thumbnailImageView.image = [UIImage imageNamed:@"cover_default_large.png"];
            [self getThumbImage:(int)rowIndex andArtistCell:cellArtist];
        }
        
        NSString *artist = [[queue objectAtIndex:rowIndex] objectForKey:@"artist"];
        NSString *title = [[queue objectAtIndex:rowIndex] objectForKey:@"title"];
        
        if (artist) {
            cellArtist.artistLabel.text = artist;
        }
        
        if (title) {
            cellArtist.titleLabel.text = title;
        }
        
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
    NSMutableDictionary* updatedQueueSong = [[queue objectAtIndex:index] mutableCopy];

    //Load big image to use in lockscreen
    id imageProp = [updatedQueueSong objectForKey:@"cover_url_large"];

    if (imageProp != [NSNull null] && imageProp != nil) {
        if([imageProp isKindOfClass:[UIImage class]]){
            [updatedQueueSong setValue:imageProp forKey:@"cover_url_large"];
        }
        else
        {
            NSURL *imgUrl = [NSURL URLWithString:imageProp];
            NSData *imgData = [NSData dataWithContentsOfURL:imgUrl];
            UIImage *image = [UIImage imageWithData:imgData];
            
            if (image != nil) {
                [updatedQueueSong setValue:image forKey:@"cover_url_large"];
            }
            else
            {
                [updatedQueueSong setValue:[UIImage imageNamed:@"cover_default_large.png"] forKey:@"cover_url_large"];
            }
        }
    }
    else
    {
        [updatedQueueSong setValue:[UIImage imageNamed:@"cover_default_large.png"] forKey:@"cover_url_large"];
    }
    
    [queue setObject:updatedQueueSong atIndexedSubscript:index];
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
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Delete Queue",@"Save Playlist", nil];
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
    if (buttonIndex != 2) {
        QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];

        switch (buttonIndex) {
            case 0:
                
                [QueueViewController sharedQueue].isPlaying = NO;
                queueSingleton.currentSongIndex = 0;
                [queueSingleton.queueSongs removeAllObjects];
                [queue removeAllObjects];
                [thumbnails removeAllObjects];
                [self.mainTable reloadData];
                [self.playerView stopVideo];
                [self.playerView clearVideo];
                
                break;
            case 1:
                
                break;
            default:
                break;
        }
    }
}

@end
