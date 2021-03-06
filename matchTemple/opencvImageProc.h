//
//  opencvImageProc.h
//  matchTemple
//
//  Created by cici on 15/3/2.
//  Copyright (c) 2015年 xl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface opencvImageProc : NSObject
+ (UIImage *)matchTemple :(UIImage *)image temple:(UIImage *)temple ;
+ (UIImage *)stitcherImage:(NSArray *)arrayImages;
+(UIImage *)fetchImage:(UIImage*)templet;
+(NSString *)classiflerApp:(UIImage  *)image;
//test===
+(UIImage *)getSingleChannelImage:(UIImage *)image;

+(UIImage*)histImage:(UIImage *) image;
//===
@end
