//
//  SettingsWebViewController.m
//  Atraci
//
//  Created by Uriel Garcia on 07/09/14.
//  Copyright © 2014 Alan Garcia, Atraci. All rights reserved.
//

#import "SettingsWebViewController.h"

@interface SettingsWebViewController ()

@end

@implementation SettingsWebViewController
@synthesize url;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSURL *websiteUrl = [NSURL URLWithString:url];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:websiteUrl];
    [_webView loadRequest:urlRequest];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
