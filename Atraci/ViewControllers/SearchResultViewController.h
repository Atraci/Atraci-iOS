//
//  SearchResultViewController.h
//  Atraci
//
//  Created by Uriel Garcia on 28/06/14.
//  Copyright © 2014 Alan Garcia, Atraci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RequestClass.h"

@interface SearchResultViewController : UIViewController <UISearchDisplayDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, RequestClassDelegate>
@property (readwrite, retain) NSTimer *searchTimer;
@property (weak, nonatomic) IBOutlet UITableView *mainTable;
@property(strong ,nonatomic) RequestClass *request;

@end

