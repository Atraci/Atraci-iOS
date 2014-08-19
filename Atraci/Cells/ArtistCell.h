//
//  ArtistCell.h
//  Atraci
//
//  Created by Uriel Garcia on 28/06/14.
//  Copyright (c) 2014 Atraci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ArtistCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end
