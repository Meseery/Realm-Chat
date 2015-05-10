//
//  ViewController.m
//  Realm Chat
//
//  Created by Mohamed EL Meseery on 5/7/15.
//  Copyright (c) 2015 Mohamed EL Meseery. All rights reserved.
//

#import "HomeViewController.h"
#import "ChatViewController.h"

@interface HomeViewController ()
@property (weak, nonatomic) IBOutlet UIButton *loginBTN;

@property (nonatomic) NSString *userName ;
@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewWillAppear:(BOOL)animated{

    _userName = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserName"];
    if (_userName) {
        // show button for login
        _loginBTN.hidden=NO;
    }

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)tappedJoinChatRoom:(id)sender {
    UIAlertView *alert =[[UIAlertView alloc]initWithTitle:@"Welcome" message:@"What's your name ?" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Confirm", nil];
    alert.alertViewStyle=UIAlertViewStylePlainTextInput;
    [alert show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        self.userName=[alertView textFieldAtIndex:0].text;
        [[NSUserDefaults standardUserDefaults] setObject:self.userName forKey:@"UserName"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self performSegueWithIdentifier:@"enterChatroom" sender:self];
    }
}

- (IBAction)tappedLoginChatRoom:(id)sender {
    [self performSegueWithIdentifier:@"enterChatroom" sender:self];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"enterChatroom"]) {
        ChatViewController *destinationVC = (ChatViewController*)segue.destinationViewController;
        destinationVC.userName=_userName;
    }
}

@end
