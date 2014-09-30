//
//  ATCSong.m
//  Atraci
//
//  Created by Uriel Garcia on 29/09/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import "ATCSong.h"

@implementation ATCSong
@synthesize artist,title,urlCoverMedium,urlCoverLarge,imageCoverMedium,imageCoverLarge;

- (id)init {
    
    self = [super init];
    
    if (self) {
        
    }
    
    return self;
}

-(void)setUrlCoverMedium:(id)urlCoverMediumString
{
    if (urlCoverMediumString != [NSNull null] && urlCoverMediumString != nil) {
        urlCoverMedium = [NSURL URLWithString:urlCoverMediumString];
    }
}

-(void)setUrlCoverLarge:(id)urlCoverLargeString
{
    if (urlCoverLargeString != [NSNull null] && urlCoverLargeString != nil) {
        urlCoverLarge = [NSURL URLWithString:urlCoverLargeString];
    }
}

-(void)setImageCoverMedium
{
    NSURL *urlImage = self.urlCoverMedium;
    UIImage *image = [self getImageFromUrl:urlImage];
    self.imageCoverMedium = image;
}

-(void)setImageCoverLarge
{
    NSURL *urlImage = self.urlCoverLarge;
    UIImage *image = [self getImageFromUrl:urlImage];
    self.imageCoverLarge = image;
}

- (UIImage *)getImageFromUrl:(NSURL *)urlImage
{
    NSData *imgData = [NSData dataWithContentsOfURL:urlImage];
    UIImage *image = [UIImage imageWithData:imgData];
    
    if (image == nil) {
        image = [UIImage imageNamed:@"cover_default_large.png"];
    }
    return image;
}
@end
