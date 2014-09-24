//
//  SettingsTableViewController.m
//  Atraci
//
//  Created by Uriel Garcia on 13/08/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "SettingsWebViewController.h"
#import "QueueViewController.h"

@interface SettingsTableViewController ()
@property (weak, nonatomic) IBOutlet UILabel *AboutAtraciLabel;

@end

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.AboutAtraciLabel.text = [NSString stringWithFormat:@"About Atraci v%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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

- (void)showEmail {
    // Email Subject
    NSString *emailTitle = @"Download Atraci Music App for free";
    // Email Content
    NSString *messageBody = @"Atraci is an application for iOS, Mac, Windows and Linux that lets you listen instantly to more than 60 million songs. It requires no sign up, displays no ads and is 100% safe and free. <br /><br />Download our iOS App on the App Store or our desktop apps for free at: <a href=\"http://atra.ci\">http://atra.ci</a><br /><br />The Atraci Team (<a href=\"mailto:atraciapp@gmail.com?Subject=Atraci iOS Support\">atraciapp@gmail.com</a>)";
    // To address
    //NSArray *toRecipents = //[NSArray arrayWithObject:@"support@appcoda.com"];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:YES];
    //[mc setToRecipients:toRecipents];
    
    // Present mail view controller on screen
    [self presentViewController:mc animated:YES completion:NULL];
    
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 4;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger currentTag = [[tableView cellForRowAtIndexPath:indexPath] tag];
    switch (currentTag) {
        case 2:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:ATRACI_DONATION_LINK]];
            break;
        case 3:
            [self showEmail];
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    UIViewController *vC = [segue destinationViewController];
    
    if ([segue.identifier isEqualToString:@"SupportSegue"]) {
        SettingsWebViewController *sWvC = (SettingsWebViewController *)vC;
        sWvC.url = ATRACI_GITHUB_LINK;
    }
//    else if ([segue.identifier isEqualToString:@"DonateSegue"])
//    {
//        SettingsWebViewController *sWvC = (SettingsWebViewController *)vC;
//        sWvC.url = ATRACI_DONATION_LINK;
//    }
}

@end
