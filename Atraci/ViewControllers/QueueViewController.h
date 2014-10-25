//
//  QueueViewController.h
//  Atraci
//
//  Created by Uriel Garcia on 28/06/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YTPlayerView.h"
#import "RequestClass.h"
#import "ATCPlaylistHelper.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "ATCSong.h"

@interface QueueViewController : UIViewController <YTPlayerViewDelegate, RequestClassDelegate, AVAudioPlayerDelegate, UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource,ATCPlaylistHelperDelegate, UITabBarControllerDelegate>
{
    UITabBarItem *tabBarItem;
}

@property (nonatomic, assign) ATCSong* currentSongObj;
@property (nonatomic, assign) BOOL shoudDisplayHUD;
@property (nonatomic, assign) BOOL isPlaying;
@property(strong ,nonatomic) RequestClass *request;
@property (weak, nonatomic) IBOutlet UITableView *mainTable;
@property(nonatomic, strong) IBOutlet YTPlayerView *playerView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UITabBarItem *QueueIcon;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *PlayListBtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *PlayPauseBtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *PlayerOptionsBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *ActivityIndicator;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *fixedSpace;

- (void)loadSongs:(BOOL)load shouldReloadTable:(BOOL)reloadTable withSongPostition:(NSUInteger)songPosition;
-(void)getSongInfo;
+ (instancetype)sharedQueue;
@end

