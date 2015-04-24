//
//  findImageVc.h
//  matchTemple
//
//  Created by cici on 15/3/19.
//  Copyright (c) 2015年 xl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface findImageVc : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *rootimage;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addBt;

@property(assign,nonatomic) BOOL isAppclassify;
@end
