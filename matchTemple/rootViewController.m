//
//  rootViewController.m
//  matchTemple
//
//  Created by cici on 15/4/22.
//  Copyright (c) 2015年 xl. All rights reserved.
//

#import "rootViewController.h"
#import "findImageVc.h"
@interface rootViewController ()

@end

@implementation rootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"appClassify"]) //"goView2"是SEGUE连线的标识
    {
        findImageVc* theSegue = segue.destinationViewController;
        theSegue.isAppclassify = YES;

    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
