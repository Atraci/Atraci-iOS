//
//  QueueViewController.m
//  Atraci
//
//  Created by Uriel Garcia on 28/06/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import "QueueViewController.h"
#import "QueueSingleton.h"

@implementation QueueViewController
{
    NSDictionary* currentSong;
}
@synthesize request,isPlaying;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
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
- (void)loadSongs {    
    QueueSingleton *sharedSingleton = [QueueSingleton sharedInstance];
    NSArray *songs = sharedSingleton.queueSongs;
    
    currentSong = [[NSDictionary alloc] initWithDictionary:[songs objectAtIndex:0]];
    
    NSString *artist = [currentSong objectForKey:@"artist"];
    NSString *title = [currentSong objectForKey:@"title"];
    NSString *stringToEncode = [NSString stringWithFormat:@"%@ - %@",artist,title];
    NSString* encoded = [stringToEncode stringByAddingPercentEscapesUsingEncoding:
                         NSASCIIStringEncoding];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://gdata.youtube.com/feeds/api/videos?alt=json&max-results=1&q=%@",encoded]];
    [self.request request:url withSelector:@selector(loadPlayerWithData:)];
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
        tabBarItem.badgeValue = @"1";
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
            tabBarItem.badgeValue = nil;
            break;
        default:
            break;
    }
    
   [NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(getSongInfo) userInfo:nil repeats:NO];
}

-(void)getSongInfo
{
    NSString *artist = [currentSong objectForKey:@"artist"];
    NSString *title = [currentSong objectForKey:@"title"];
    UIImage* musicImage = [currentSong objectForKey:@"cover_url_large"];
    
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
@end
