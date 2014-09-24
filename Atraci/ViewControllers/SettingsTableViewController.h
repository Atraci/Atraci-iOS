//
//  SettingsTableViewController.h
//  Atraci
//
//  Created by Uriel Garcia on 13/08/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface SettingsTableViewController : UITableViewController <MFMailComposeViewControllerDelegate>
{
    MFMailComposeViewController *mailComposer;
}

@end
