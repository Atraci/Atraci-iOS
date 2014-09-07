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

@implementation QueueViewController
{
    NSDictionary* currentSongObj;
    NSMutableArray *artists, *albums, *tracks, *thumbnails, *queue;
    BOOL repeatQueue,shuffleQueue;
}
@synthesize request,isPlaying,mainTable;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    thumbnails = [[NSMutableArray alloc] init];
    self.request = [[RequestClass alloc] init];
    self.request.delegate = self;
    
        // for run application in background
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
        NSError *setCategoryError = nil;
        BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
        if (!success) { /* handle the error condition */ }
    
        NSError *activationError = nil;
        success = [audioSession setActive:YES error:&activationError];
        if (!success) { /* handle the error condition */ }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemEnded:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    repeatQueue = NO;
    shuffleQueue = NO;
}

- (void)playerItemEnded:(NSNotification *)notification
{
    NSLog(@"end");
}

-(void)viewDidAppear:(BOOL)animated{
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

-(BOOL)canBecomeFirstResponder
{
    return  true;
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
    
    NSLog(@"%@",videoID);
    
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
    
    
    double delayInSeconds = 2.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
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
    switch (state) {
        case kYTPlayerStatePlaying:
            NSLog(@"Started playback");
            isPlaying = YES;
            break;
        case kYTPlayerStatePaused:
            NSLog(@"Paused playback");
            isPlaying = NO;
            break;
        case kYTPlayerStateEnded:
            NSLog(@"Ended playback");
            isPlaying = NO;
            [self.playerView stopVideo];
            
            [self playNextSong];
            //tabBarItem.badgeValue = nil;
            break;
        default:
            break;
    }
    
   [NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(getSongInfo) userInfo:nil repeats:NO];
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
    
    [songInfo setObject:song forKey:MPMediaItemPropertyTitle];
    [songInfo setObject:artist forKey:MPMediaItemPropertyArtist];
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
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [queue removeObjectAtIndex:indexPath.row];
    [self.mainTable reloadData];
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

- (IBAction)emptyQueue:(id)sender {
    QueueSingleton *queueSingleton = [QueueSingleton sharedInstance];
    queueSingleton.currentSongIndex = 0;
    [queueSingleton.queueSongs removeAllObjects];
    [queue removeAllObjects];
    [thumbnails removeAllObjects];
    
    [self.mainTable reloadData];
    [self.playerView stopVideo];
    [self.playerView clearVideo];
}

@end
