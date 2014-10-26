//
//  SettingsWebViewController.h
//  Atraci
//
//  Created by Uriel Garcia on 07/09/14.
//  Copyright © 2014 Alan Garcia, Atraci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsWebViewController : UIViewController <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) NSString* url;

@end
