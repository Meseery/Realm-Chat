//
//  ChatViewController.m
//  Realm Chat
//
//  Created by Mohamed EL Meseery on 5/8/15.
//  Copyright (c) 2015 Mohamed EL Meseery. All rights reserved.
//

#import "ChatViewController.h"
#import "ChatCell.h"

#import <Parse/Parse.h>
#import "Reachability.h"

#define MESSAGE_TEXTFIELD_HEIGHT 70.0f
#define MAX_ENTRIES_LOADED 25 

@interface ChatViewController () <UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate>

@property (weak,nonatomic) IBOutlet UITextField * messageTextField;
@property (weak,nonatomic) IBOutlet UITableView * messagesTable;
@property (retain,nonatomic) UIRefreshControl *refreshControl;

@property (nonatomic, retain) NSMutableArray *chatData;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
#pragma mark - Register For Keyboard Notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
#pragma mark - Message Textfield Setup
    _messageTextField.delegate = self;
    _messageTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    
    UIView *refreshView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 55)];
    [self.messagesTable insertSubview:refreshView atIndex:0]; //the tableView is a IBOutlet
    
    _refreshControl = [[UIRefreshControl alloc] init];
    _refreshControl.tintColor = [UIColor redColor];
    [_refreshControl addTarget:self action:@selector(reloadMessagesTable) forControlEvents:UIControlEventValueChanged];
     NSMutableAttributedString *refreshString = [[NSMutableAttributedString alloc] initWithString:@"Pull To Refresh"];
     [refreshString addAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]} range:NSMakeRange(0, refreshString.length)];
     _refreshControl.attributedTitle = refreshString;
    [refreshView addSubview:_refreshControl];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [reach currentReachabilityStatus];
    if (status == NotReachable){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network"
                                                        message:[self stringFromStatus: status]
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    _chatData  = [NSMutableArray array];
    [self loadLocalChat];
    
}

#pragma mark - Message Textfield Handling

-(IBAction) textFieldDoneEditing : (id) sender
{
    [sender resignFirstResponder];
    [self.messageTextField resignFirstResponder];
}

-(IBAction) backgroundTap:(id) sender
{
    [self.messageTextField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    [self sendMessage:nil];
    
    // reload the data
    [self loadLocalChat];
    return NO;
}

#pragma mark - Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Keyboard Handling
-(void) keyboardWasShown:(NSNotification*)aNotification
{
    
    NSDictionary* info = [aNotification userInfo];
    
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardFrame];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    [self.view setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height- keyboardFrame.size.height)];
    
    [UIView commitAnimations];
    
}

-(void) keyboardWillHide:(NSNotification*)aNotification
{
   
    NSDictionary* info = [aNotification userInfo];
    
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardFrame];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    [self.view setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height+ keyboardFrame.size.height)];
    
    [UIView commitAnimations];
}

#pragma mark - Tableview Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return self.chatData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *cellIdentifier = @"chatCell";
    ChatCell *cell = (ChatCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if(cell == nil) {
        cell = [[ChatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    NSUInteger row = _chatData.count-indexPath.row-1;
    
    if (row < _chatData.count){
        // Message Text

        NSString *chatText = [[_chatData objectAtIndex:row] objectForKey:@"text"];
        
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        UIFont *font = [UIFont systemFontOfSize:14];
        NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        CGSize size =[chatText boundingRectWithSize:CGSizeMake(225.0f, 1000.0f)
                                 options:NSStringDrawingUsesLineFragmentOrigin
                              attributes:@{NSFontAttributeName: font,
                                           NSParagraphStyleAttributeName:paragraphStyle}
                                 context:nil].size;
        
        cell.textString.frame = CGRectMake(cell.textString.frame.origin.x, cell.textString.frame.origin.y, size.width +20, size.height + 20);
        cell.textString.font = [UIFont fontWithName:@"Helvetica" size:14.0];
        cell.textString.text = chatText;
        [cell.textString sizeToFit];
            
        
        // Message Date
        NSDate *theDate = [[_chatData objectAtIndex:row] objectForKey:@"date"];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"HH:mm a"];
        NSString *timeString = [formatter stringFromDate:theDate];
        cell.timeLabel.text = timeString;
        
        // Message sender
        cell.userLabel.text = [[_chatData objectAtIndex:row] objectForKey:@"userName"];
    }

    
    return cell;
}

- (void)reloadMessagesTable{
    
    [self loadLocalChat];
    [_messagesTable reloadData];
    [_refreshControl endRefreshing];
}

#pragma mark - Tableview Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight=80.0;
    
    NSString *cellText = [[_chatData objectAtIndex:_chatData.count-indexPath.row-1] objectForKey:@"text"];
    UIFont *cellFont = [UIFont fontWithName:@"Helvetica" size:14.0];
    CGSize constraintSize = CGSizeMake(250.0f, MAXFLOAT);
    
    NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    CGSize labelSize =[cellText boundingRectWithSize:constraintSize
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                     attributes:@{NSFontAttributeName: cellFont,
                                                  NSParagraphStyleAttributeName:paragraphStyle}
                                        context:nil].size;
        cellHeight=labelSize.height+40;
    
    
    return cellHeight;
}

#pragma mark - Parse

- (void)loadLocalChat
{
    PFQuery *query = [PFQuery queryWithClassName: @"Message"];
    
    if (_chatData.count == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
        [query orderByAscending:@"createdAt"];
        
        // Trying to retrieve from cache
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                // The find succeeded.
                [_chatData removeAllObjects];
                [_chatData addObjectsFromArray:objects];
                [_messagesTable reloadData];
            } else {
                // Log details of the failure
                NSLog(@"Error: %@ %@", error, [error userInfo]);
            }
        }];
    }   
}

- (NSString *)stringFromStatus:(NetworkStatus ) status {
    NSString *string; switch(status) {
        case NotReachable:
            string = @"You are not connected to the internet, you cannot join Chat Room";
            break;
        case ReachableViaWiFi:
            string = @"Reachable via WiFi";
            break;
        case ReachableViaWWAN:
            string = @"Reachable via WWAN";
            break;
        default:
            string = @"Unknown connection";
            break;
    }
    return string;
}
#pragma mark - Send Message

-(IBAction)sendMessage:(id)sender{

    if (_messageTextField.text.length>0) {
      
        NSArray *keys = @[@"text", @"userName", @"date"];
        NSArray *objects = @[_messageTextField.text, _userName, [NSDate date]];
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
        [_chatData addObject:dictionary];
        
        NSMutableArray *insertIndexPaths = [[NSMutableArray alloc] init];
        NSIndexPath *newPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [insertIndexPaths addObject:newPath];
        [_messagesTable beginUpdates];
        [_messagesTable insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationTop];
        [_messagesTable endUpdates];
        [_messagesTable reloadData];
        
        // going for the parsing
        PFObject *newMessage = [PFObject objectWithClassName:@"Message"];
        [newMessage setObject:_messageTextField.text forKey:@"text"];
        [newMessage setObject:_userName forKey:@"userName"];
        [newMessage setObject:[NSDate date] forKey:@"date"];
        [newMessage saveInBackground];
        _messageTextField.text = @"";
    }

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
