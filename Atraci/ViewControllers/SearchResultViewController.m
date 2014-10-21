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
#import "ATCLogicAlgorithms.h"
#import "ATCSong.h"

@interface SearchResultViewController ()
@end

@implementation SearchResultViewController
{
    NSArray *autoCompletionSearchResults, *searchResults;
    NSMutableArray *artists, *albums, *tracks, *customSearch, *ATCSearchResults, *queryResults;
    NSMutableDictionary *searchTableSections;
    NSString *customSearchText;
}

@synthesize request;
            
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    ATCSearchResults = [[NSMutableArray alloc] init];
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

}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
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
        customSearchText = searchText;
        
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
        count = queryResults.count;
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
                count = [[queryResults objectAtIndex:section] count];
                break;
            case 1:
                count = [[queryResults objectAtIndex:section] count];
                break;
            case 2:
                count = [[queryResults objectAtIndex:section] count];
                break;
            case 3:
                count = [[queryResults objectAtIndex:section] count];
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
        if ([queryResults objectAtIndex:section] == artists) {
            sectionTitle = @"Artists";
        }else if([queryResults objectAtIndex:section] == albums) {
            sectionTitle = @"Albums";
        }else if([queryResults objectAtIndex:section] == tracks) {
            sectionTitle = @"Songs";
        }
        else if([queryResults objectAtIndex:section] == customSearch) {
            sectionTitle = @"Search";
        }
    }
    return sectionTitle;
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
        //Song Artist and Title
        ATCSong *song;
        
        if(ATCSearchResults.count == searchResults.count)
        {
            song = [ATCSearchResults objectAtIndex:rowIndex];
        }
        else
        {
            song = [[ATCSong alloc] init];
            song.artist = [[searchResults objectAtIndex:rowIndex] objectForKey:@"artist"];
            song.title = [[searchResults objectAtIndex:rowIndex] objectForKey:@"title"];
            song.urlCoverMedium = [[searchResults objectAtIndex:rowIndex] objectForKey:@"cover_url_medium"];
            song.urlCoverLarge = [[searchResults objectAtIndex:rowIndex] objectForKey:@"cover_url_large"];
            
            [ATCSearchResults addObject:song];
        }
        
        if (song.artist) {
            cellArtist.artistLabel.text = song.artist;
        }
        if (song.title) {
            cellArtist.titleLabel.text = song.title;
        }
        
        //Thumbnail
        if (song.imageCoverMedium == nil) {
            cellArtist.thumbnailImageView.image = [UIImage imageNamed:@"cover_default_large.png"];
            
            dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Add code here to do background processing
                [song setImageCoverMedium];
                        
                dispatch_async( dispatch_get_main_queue(), ^{
                    // Add code here to update the UI/send notifications based on the
                    // results of the background processing
                    cellArtist.thumbnailImageView.image = song.imageCoverMedium;
                });
            });
        }
        else
        {
            cellArtist.thumbnailImageView.image = song.imageCoverMedium;
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
        
        NSArray *object = [queryResults objectAtIndex:indexPath.section] ;
        int objCount = [object count];
        if (objCount > 0 && rowIndex < objCount){
            label = [[object objectAtIndex:rowIndex] objectForKey:@"label"];
            image = [[object objectAtIndex:rowIndex] objectForKey:@"image"];
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
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Play Now",@"Play Next",@"Add To Queue", nil];
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    }
    else{
        NSDictionary *object = [[queryResults objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        value = [object objectForKey:@"value"];

        //Hide search bar
        [self.searchDisplayController setActive:NO animated:YES];
        [self requestMainTableData:value];
        
        self.searchDisplayController.searchBar.text = value;
    }
}

#pragma mark -
#pragma mark Search Results Table Logic
- (void)requestMainTableData:(NSString *)searchText {
    //Clear Table before loading new data
    searchResults = nil;
    [ATCSearchResults removeAllObjects];
    [self.mainTable reloadData];
    
    NSString* encoded = [searchText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", ATRACI_API_LINK, encoded]];
    
    [request request:url withSelector:@selector(reloadMainTableWithData:)];
    [SVProgressHUD show];
}

- (void)reloadMainTableWithData:(NSData *)data
{
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
    
    autoCompletionSearchResults = [ATCLogicAlgorithms sortTracksJSON:[NSJSONSerialization JSONObjectWithData:data options:0 error:&error]];
    
    artists = [[NSMutableArray alloc] init];
    albums = [[NSMutableArray alloc] init];
    tracks = [[NSMutableArray alloc] init];
    customSearch = [[NSMutableArray alloc] init];
    
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
    
    queryResults = [[NSMutableArray alloc] init];
    
    if (artists.count > 0) {
        [queryResults addObject:artists];
    }
    if (albums.count > 0) {
        [queryResults addObject:albums];
    }
    if (tracks.count > 0) {
        [queryResults addObject:tracks];
    }
    
    //Custom Search
        UIImage *image = [UIImage imageNamed:@"cover_default_large.png"];
        
        NSMutableDictionary *customObject = [[NSMutableDictionary alloc] init];
        [customObject setObject:customSearchText forKey:@"value"];
        [customObject setObject:customSearchText forKey:@"label"];
        [customObject setObject:image forKey:@"image"];

        [customSearch addObject:customObject];
        [queryResults addObject:customSearch];
    
    //Reload table
    double delayInSeconds = 0.02;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.searchDisplayController.searchResultsTableView reloadData];
    });
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

        ATCSong *song = [ATCSearchResults objectAtIndex:self.mainTable.indexPathForSelectedRow.row];
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
