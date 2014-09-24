//
//  SearchResultViewController.m
//  Atraci
//
//  Created by Uriel Garcia on 28/06/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import "SearchResultViewController.h"
#import "ArtistCell.h"
#import "QueueSingleton.h"
#import "QueueViewController.h"
#import "SVProgressHUD.h"

@interface SearchResultViewController ()
@end

@implementation SearchResultViewController
{
    NSArray *autoCompletionSearchResults, *searchResults;
    NSMutableArray *artists, *albums, *tracks, *thumbnails;
    NSMutableDictionary *searchTableSections;
    NSString *lastSearchBarText;
}

@synthesize request;
            
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    lastSearchBarText = [[NSString alloc] init];
    thumbnails = [[NSMutableArray alloc] init];
    request = [[RequestClass alloc] init];
    request.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated{
    if ([QueueViewController sharedQueue].playerView.playerState == kYTPlayerStatePlaying ) {
        [[QueueViewController sharedQueue].playerView playVideo];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods
- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar
{

}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    
}

- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar
{
    
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    //Strip the whitespace off the end of the search text
    NSString *searchText = [searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.searchDisplayController setActive:NO animated:YES];
    [self requestMainTableData:searchText];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    return YES;
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{

}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    searchBar.text = lastSearchBarText;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    lastSearchBarText = searchText;
    
    [self.searchTimer invalidate];
    self.searchTimer = nil; // this releases the retained property implicitly
    self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(OnTextChange:) userInfo:searchText repeats:NO];
}

-(void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {

}

- (void)OnTextChange:(NSTimer *)timer
{
    NSString *searchText = [timer userInfo];
    
    if ([searchText length] > 0) {
        NSString* encoded = [searchText stringByAddingPercentEscapesUsingEncoding:
                             NSASCIIStringEncoding];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",@"http://www.last.fm/search/autocomplete?q=",encoded]];
        
        [request request:url withSelector:@selector(reloadSearchTableWithData:)];
    }
}

#pragma mark -
#pragma mark TableView Delegate Methods
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 70;
//}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    int count = 0;

    if (tableView == self.mainTable) {
        count = 1;
    }
    else{
        count = 3;
    }
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = 0;
    
    if (tableView == self.mainTable) {
        count = searchResults.count;
    }
    else{
        switch (section) {
            case 0:
                count = artists.count;
                break;
            case 1:
                count = albums.count;
                break;
            case 2:
                count = tracks.count;
                break;
            default:
                break;
        }
    }
    
    return count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString * sectionTitle = @"";
    
    if (tableView != self.mainTable) {
        switch (section) {
            case 0:
                sectionTitle = @"Artists";
                break;
            case 1:
                sectionTitle = @"Albums";
                break;
            case 2:
                sectionTitle = @"Songs";
                break;
            default:
                break;
        }
    }
    return sectionTitle;
}

- (void)getThumbImage:(int)indexRow andArtistCell:(ArtistCell *)cellArtist
{
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Add code here to do background processing
        //request album art
        id imageUrl = [[searchResults objectAtIndex:indexRow] objectForKey:@"cover_url_medium"];
        if (imageUrl != [NSNull null] && imageUrl != nil) {
            NSURL *imgUrl = [NSURL URLWithString:imageUrl];
            NSData *imgData = [NSData dataWithContentsOfURL:imgUrl];
            UIImage *image = [UIImage imageWithData:imgData];

            if (image != nil) {
                    [thumbnails addObject:image];
                
                dispatch_async( dispatch_get_main_queue(), ^{
                // Add code here to update the UI/send notifications based on the
                // results of the background processing
                    cellArtist.thumbnailImageView.image = (UIImage *)image;
                });
            }
        }
    });
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier;
    UITableViewCell *cell;
    ArtistCell *cellArtist;
    int rowIndex = (int)indexPath.row;

    if (tableView == self.mainTable) {
        CellIdentifier = @"ArtistCell";
        cellArtist = (ArtistCell *)[self.mainTable dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cellArtist == nil) {
            cellArtist = [[ArtistCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        // Configure the cell...
        
        if (rowIndex < thumbnails.count) {
            cellArtist.thumbnailImageView.image = [thumbnails objectAtIndex:rowIndex];
        }
        else
        {
            cellArtist.thumbnailImageView.image = [UIImage imageNamed:@"cover_default_large.png"];
            [self getThumbImage:(int)rowIndex andArtistCell:cellArtist];
        }
        
        NSString *artist = [[searchResults objectAtIndex:rowIndex] objectForKey:@"artist"];
        NSString *title = [[searchResults objectAtIndex:rowIndex] objectForKey:@"title"];
        
        if (artist) {
            cellArtist.artistLabel.text = artist;
        }
        
        if (title) {
            cellArtist.titleLabel.text = title;
        }
        
        return cellArtist;
    }
    else{
        CellIdentifier = @"CustomTableCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        // Configure the cell...
        NSString *label;
        UIImage *image;
        
        switch (indexPath.section) {
            case 0:
                if (artists.count > 0 && rowIndex < artists.count){
                    label = [[artists objectAtIndex:rowIndex] objectForKey:@"label"];
                    image = [[artists objectAtIndex:rowIndex] objectForKey:@"image"];
                }
                break;
            case 1:
                if (albums.count > 0 && rowIndex < albums.count){
                    label = [[albums objectAtIndex:rowIndex] objectForKey:@"label"];
                    image = [[albums objectAtIndex:rowIndex] objectForKey:@"image"];
                }
                break;
            case 2:
                if (tracks.count > 0 && rowIndex < tracks.count){
                    label = [[tracks objectAtIndex:rowIndex] objectForKey:@"label"];
                    image = [[tracks objectAtIndex:rowIndex] objectForKey:@"image"];
                }
                break;
            default:
                break;
        }
        
        cell.imageView.image = image;
        cell.textLabel.text = label;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *value = @"";
    
    if (tableView == self.mainTable) {
        //Choose index of the last added song or the position choosen
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Play Now",@"Play Next",@"Play Last", nil];
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    }
    else{
        switch (indexPath.section) {
            case 0:
                value = [[artists objectAtIndex:indexPath.row] objectForKey:@"value"];
                break;
            case 1:
                value = [[albums objectAtIndex:indexPath.row] objectForKey:@"value"];
                break;
            case 2:
                value = [[tracks objectAtIndex:indexPath.row] objectForKey:@"value"];
                break;
            default:
                break;
        }
        lastSearchBarText = value;
        self.searchDisplayController.searchBar.text = value;
        [self.searchDisplayController setActive:NO animated:YES];
        [self requestMainTableData:value];
        //Ressing Keyboard and search here
    }
}

#pragma mark -
#pragma mark Search Results Table Logic
- (void)requestMainTableData:(NSString *)searchText {
    searchResults = nil;
    [self.mainTable reloadData];
    
    NSString* encoded = [searchText stringByAddingPercentEscapesUsingEncoding:
                         NSASCIIStringEncoding];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", ATRACI_API_LINK, encoded]];
    
    [request request:url withSelector:@selector(reloadMainTableWithData:)];
    [SVProgressHUD show];
}

- (void)reloadMainTableWithData:(NSData *)data
{
    [thumbnails removeAllObjects];
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Add code here to do background processing
        NSError *error;
        searchResults = [[NSArray alloc] initWithArray:[NSJSONSerialization JSONObjectWithData:data options:0 error:&error]];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if(searchResults.count > 0){
                [SVProgressHUD dismiss];
                [self.mainTable reloadData];
            }
            else{
                [SVProgressHUD showErrorWithStatus:@"No results"];
            }
        });
    });
 }

#pragma mark Search Autocompletion Table Logic
- (void)reloadSearchTableWithData:(NSData *)data
{
    NSError *error;
    
    autoCompletionSearchResults = [self sortTracksJSON:[NSJSONSerialization JSONObjectWithData:data options:0 error:&error]];
    
    artists = [[NSMutableArray alloc] init];
    albums = [[NSMutableArray alloc] init];
    tracks = [[NSMutableArray alloc] init];
    
    for (NSDictionary *o in autoCompletionSearchResults) {
        if ([[o objectForKey:@"type"] isEqualToString:@"artist"]) {
            [artists addObject:o];
        }
        else if ([[o objectForKey:@"type"] isEqualToString:@"album"]) {
            [albums addObject:o];
        }
        else if ([[o objectForKey:@"type"] isEqualToString:@"track"]) {
            [tracks addObject:o];
        }
    }
    
    //Reload table
    double delayInSeconds = 0.02;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.searchDisplayController.searchResultsTableView reloadData];
    });
}

- (NSArray *)sortTracksJSON:(NSDictionary *)dataDic
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

#pragma mark -
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 3) {
        QueueSingleton *sharedSingleton = [QueueSingleton sharedInstance];
        int songAtIndex = (int)sharedSingleton.currentSongIndex;
        
        switch (buttonIndex) {
            case 1:
                if (sharedSingleton.queueSongs.count > 0) {
                    songAtIndex = songAtIndex + 1;
                }
                break;
            case 2:
                songAtIndex = (int)sharedSingleton.queueSongs.count;
                break;
            default:
                break;
        }

        id song = [searchResults objectAtIndex:self.mainTable.indexPathForSelectedRow.row];
        [sharedSingleton.queueSongs insertObject:song atIndex:songAtIndex];
        QueueViewController *qVc = (QueueViewController*)[self.tabBarController.viewControllers objectAtIndex:1];
        
        if (buttonIndex == 0) {
            [self.tabBarController setSelectedIndex:1];//Important to be set before loading a song
            [qVc loadSongs:YES shouldReloadTable:YES withSongPostition:[sharedSingleton.queueSongs indexOfObject:song]];
        }
        else
        {
            [SVProgressHUD showSuccessWithStatus:@"Song Added"];
            [qVc loadSongs:NO shouldReloadTable:YES withSongPostition:0];
        }
    }
}

#pragma mark -
#pragma mark RequestClass Delegates
- (void)dataReceived:(SEL)selector withObject:(NSData *)data{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:selector withObject:data];
#pragma clang diagnostic pop
}
@end
