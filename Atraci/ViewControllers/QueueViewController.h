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

@interface QueueViewController : UIViewController <YTPlayerViewDelegate, RequestClassDelegate, AVAudioPlayerDelegate>
{
    UITabBarItem *tabBarItem;
}

@property (nonatomic, assign) BOOL isPlaying;
@property(strong ,nonatomic) RequestClass *request;
@property(nonatomic, strong) IBOutlet YTPlayerView *playerView;

- (void)loadSongs;
@end

