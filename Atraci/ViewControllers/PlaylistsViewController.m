//
//  PlaylistsTableViewController.m
//  Atraci
//
//  Created by Uriel Garcia on 05/10/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import "PlaylistsViewController.h"
#import "QueueViewController.h"
#import "ATCPlaylistHelper.h"
#import "Playlist.h"

@interface PlaylistsViewController ()

@end

@implementation PlaylistsViewController
{
    NSMutableArray *playlists;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    //GetAllPlaylists
    playlists = [[ATCPlaylistHelper getAllPlaylists] mutableCopy];
}

-(void)viewDidAppear:(BOOL)animated
{
    [self.playlistsTable reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Top Bar Events
- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [playlists count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Playlist" forIndexPath:indexPath];
    
    // Configure the cell...
    NSManagedObject *mObject = nil;
    mObject = playlists[indexPath.row];
    //Fetch Playlist Songs
    Playlist *playlist = (Playlist *)mObject;
    
    cell.textLabel.text = playlist.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //The first time the app loads we'll load the main queue playlist if exists, otherwise create it of it return NO
    //Set delegate method to always reload queue when loading playlists
    ATCPlaylistHelper *atcPlaylistHelper = [ATCPlaylistHelper sharedInstance];
    // grab a reference to the Tab Bar Controller
    
    //Playlist Name
    NSManagedObject *mObject = nil;
    mObject = playlists[indexPath.row];
    Playlist *playlist = (Playlist *)mObject;
    
    if([atcPlaylistHelper getPlaylist:playlist.name withPredicate:nil andSongs:YES] == YES)
    {
        if (atcPlaylistHelper.recordsFound == YES) {
            [SVProgressHUD showWithStatus:@"Loading Playlist..."];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSManagedObject *mObject = nil;
        mObject = playlists[indexPath.row];
        Playlist *playlist = (Playlist *)mObject;
        [ATCPlaylistHelper deletePlaylist:playlist.name];
        
        //Delete from tableview source
        [playlists removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
