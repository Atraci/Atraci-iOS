//
//  ATCSong.h
//  Atraci
//
//  Created by Uriel Garcia on 29/09/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ATCSong : NSObject

@property (nonatomic, strong) NSString *artist;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSURL *urlCoverMedium;
@property (nonatomic, strong) NSURL *urlCoverLarge;
@property (nonatomic, retain) UIImage *imageCoverMedium;
@property (nonatomic, strong) UIImage *imageCoverLarge;

-(void)setImageCoverMedium;
-(void)setImageCoverLarge;
@end
