//
//  ChatCell.h
//  Realm Chat
//
//  Created by Mohamed EL Meseery on 5/8/15.
//  Copyright (c) 2015 Mohamed EL Meseery. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatCell : UITableViewCell

@property (nonatomic,retain) IBOutlet UILabel *userLabel;
@property (nonatomic,retain) IBOutlet UITextView *textString;
@property (nonatomic,retain) IBOutlet UILabel *timeLabel;


@end
