//
//  PlaylistsTableViewController.h
//  Atraci
//
//  Created by Uriel Garcia on 05/10/14.
//  Copyright © 2014 Alan Garcia, Atraci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlaylistsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *playlistsTable;

@end
