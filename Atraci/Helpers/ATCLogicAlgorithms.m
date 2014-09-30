//
//  ATCLogicAlgorithms.m
//  Atraci
//
//  Created by Uriel Garcia on 29/09/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import "ATCLogicAlgorithms.h"
#import <UIKit/UIKit.h>

@implementation ATCLogicAlgorithms

+(NSArray *)sortTracksJSON:(NSDictionary *)dataDic
{
    NSDictionary *results = [[dataDic objectForKey:@"response"] objectForKey:@"docs"];
    //NSLog(@"%@", results);
    
    NSMutableArray *foundTracks = [[NSMutableArray alloc] init];
    NSArray *sortfoundTracks;
    
    if (results.count > 0) {
        for (NSDictionary *o in results) {
            NSString *itemType = @"", *itemValue = @"", *itemWeight = @"";
            
            if ([o objectForKey:@"track"]) {
                itemType = @"track";
                itemValue = [NSString stringWithFormat:@"%@ %@",[o objectForKey:@"artist"],[o objectForKey:@"track"]];
            }
            else if ([o objectForKey:@"album"]) {
                itemType = @"album";
                itemValue = [NSString stringWithFormat:@"%@ %@",[o objectForKey:@"artist"],[o objectForKey:@"album"]];
            }
            else if ([o objectForKey:@"artist"]) {
                itemType = @"artist";
                itemValue = [NSString stringWithFormat:@"%@",[o objectForKey:@"artist"]];
            }
            else{
                continue;
            }
            
            itemWeight = [o objectForKey:@"weight"];
            
            NSURL *imgUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://userserve-ak.last.fm/serve/34s/%@" ,[o objectForKey:@"image"]]];
            NSData *imgData = [NSData dataWithContentsOfURL:imgUrl];
            UIImage *image = [UIImage imageWithData:imgData];
            
            if (image == nil) {
                image = [UIImage imageNamed:@"cover_default_large.png"];
            }
            
            if (itemType != nil && itemWeight != nil && itemValue != nil) {
                NSDictionary *track = @{
                                        @"type" : itemType,
                                        @"weight" : itemWeight,
                                        @"label" : itemValue,
                                        @"value" : itemValue,
                                        @"image" : image
                                        };
                
                [foundTracks addObject:track];
            }
        }
        
        //sort the dictionaries by weight and save them into the array
        sortfoundTracks = [foundTracks sortedArrayUsingComparator:^(NSDictionary *obj1, NSDictionary *obj2) {
            if ([[obj1 objectForKey:@"weight"] floatValue] > [[obj2 objectForKey:@"weight"] floatValue] ) {
                return (NSComparisonResult)NSOrderedAscending;
            }
            if ([[obj1 objectForKey:@"weight"] floatValue] < [[obj2 objectForKey:@"weight"] floatValue] ) {
                return (NSComparisonResult)NSOrderedDescending;
            }
            return (NSComparisonResult)NSOrderedSame;
        }];
    }
    //NSLog(@"%@", sortfoundTracks);
    return sortfoundTracks;
}
@end
