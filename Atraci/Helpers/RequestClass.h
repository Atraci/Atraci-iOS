//
//  RequestClass.h
//  Atraci
//
//  Created by Uriel Garcia on 12/07/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RequestClassDelegate <NSObject>
@required
- (void)dataReceived:(SEL)selector withObject:(NSData *)data;
@end

@interface RequestClass : NSObject

@property (nonatomic,retain) NSOperationQueue* queue;
@property (nonatomic, weak) id <RequestClassDelegate> delegate;
- (void)request:(NSURL *)url withSelector:(SEL)selector;
@end
