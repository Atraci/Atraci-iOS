//
//  RequestClass.m
//  Atraci
//
//  Created by Uriel Garcia on 12/07/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import "RequestClass.h"

@implementation RequestClass
@synthesize queue,delegate;


-(id)init {
    if ( self = [super init] ) {
        self.queue =  [[NSOperationQueue alloc] init];
    }
    return self;
}

#pragma mark -
#pragma mark Request
- (void)request:(NSURL *)url withSelector:(SEL)selector
{
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection
     sendAsynchronousRequest:request
     queue:self.queue
     completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
         // do something useful
         if ([data length] >0 && error == nil)
         {
             [self.delegate dataReceived:selector withObject:data];
         }
         else if ([data length] == 0 && error == nil)
         {
             NSLog(@"Nothing was downloaded.");
         }
         else if (error != nil){
             NSLog(@"Error = %@", error);
         }
     }];
}
@end
