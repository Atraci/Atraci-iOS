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
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface QueueViewController : UIViewController <YTPlayerViewDelegate, RequestClassDelegate, AVAudioPlayerDelegate, UITableViewDelegate, UITableViewDataSource>
{
    UITabBarItem *tabBarItem;
}

@property (nonatomic, assign) BOOL isPlaying;
@property(strong ,nonatomic) RequestClass *request;
@property (weak, nonatomic) IBOutlet UITableView *mainTable;
@property(nonatomic, strong) IBOutlet YTPlayerView *playerView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *repeatBarBtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shuffleBarBtn;
@property (weak, nonatomic) IBOutlet UITabBarItem *QueueIcon;

- (void)loadSongs:(BOOL)load shouldReloadTable:(BOOL)reloadTable withSongPostition:(NSUInteger)songPosition;
+ (instancetype)sharedQueue;
@end

