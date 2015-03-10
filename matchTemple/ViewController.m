//
//  ViewController.m
//  matchTemple
//
//  Created by cici on 15/3/2.
//  Copyright (c) 2015年 xl. All rights reserved.
//

#import "ViewController.h"
#import "opencvImageProc.h"
@interface ViewController ()
@property (nonatomic,strong) UIImageView *baseImageView;
@property (nonatomic,strong) UIImageView *imageV1;
@property (nonatomic,strong) UIImageView *imageV2;
@property (nonatomic,assign) NSInteger countImage;
@property (nonatomic,strong) UIActivityIndicatorView *activityIndicator;
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    UIImageView *imageV1  =[[UIImageView alloc] initWithFrame:CGRectMake(0, 64, 150, 150)];
    UIImageView *imageV2 = [[UIImageView alloc] initWithFrame:CGRectMake(160, 64, 150, 150)];
    UIImageView *base = [[UIImageView alloc] initWithFrame:CGRectMake(0, 160+64, 320, 320)];
    imageV1.contentMode = UIViewContentModeScaleAspectFit;
    imageV2.contentMode = UIViewContentModeScaleAspectFit;
    base.contentMode = UIViewContentModeScaleAspectFit;
    NSLog(@"%@",self.navigationController.navigationBar);
    [self.view addSubview:base];
    [self.view addSubview:imageV1];
    [self.view addSubview:imageV2];
    self.baseImageView = base;
    self.imageV2 = imageV2;
    self.imageV1 = imageV1;
    self.navigationController.hidesBarsOnTap = YES;
    self.countImage = 0;
    [self.view setBackgroundColor:[UIColor blackColor]];
    UIActivityIndicatorView* activityIndicatorView = [ [ UIActivityIndicatorView  alloc ] initWithFrame:CGRectMake(0,0,30.0,30.0)];
    activityIndicatorView.center = self.view.center;
    activityIndicatorView.activityIndicatorViewStyle= UIActivityIndicatorViewStyleWhiteLarge;
    activityIndicatorView.hidesWhenStopped = YES;
    [self.view addSubview:activityIndicatorView ];
    self.activityIndicator = activityIndicatorView;
}

- (IBAction)choosePhoto:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = NO;
    picker.delegate = self;
    [self.navigationController presentViewController:picker animated:YES completion:^{
        
    }];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo{
    

    if (image) {
        self.countImage++;
        if (self.countImage ==1) {
            self.imageV1.image = image;
            
            UIAlertView *alert  = [[UIAlertView alloc] initWithTitle:nil message:@"再选一张" delegate:nil
                                                   cancelButtonTitle:@"确定"  otherButtonTitles:nil, nil];
            [alert show];
        }else{
            self.imageV2.image = image;
          
            self.countImage =0;
            
            [self dismissViewControllerAnimated:YES completion:nil];
            //合并
            self.baseImageView.image = nil;
            [self.activityIndicator startAnimating ];//启动
       
            __weak ViewController *weak = self;;
            __block UIImage *result;
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
               
                NSArray *images = [NSArray arrayWithObjects:weak.imageV1.image,weak.imageV2.image, nil];
                result = [opencvImageProc stitcherImage:images];
                
               
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weak.activityIndicator stopAnimating ];//停止
                    self.baseImageView.image = result;
                    if (!result) {
                        UIAlertView *alert  = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"拼接图片失败" delegate:nil
                                                               cancelButtonTitle:@"确定"  otherButtonTitles:nil, nil];
                        [alert show];
                    }
                });
            });
          
            

            
        }
    }
    

//    UIImage *new=[self drawNewImage:image withRect:CGRectMake(0, 0, new.size.width, new.size.height)];
//    [self.baseImageView setImage:new];
//    if ([self weixinScreenShoot:new]) {
//       UIAlertView *alert  = [[UIAlertView alloc] initWithTitle:@"识别成功" message:@"微信" delegate:nil
//                         cancelButtonTitle:@"确定"  otherButtonTitles:nil, nil];
//        [alert show];
//    }else{
//    
//        UIAlertView *alert  = [[UIAlertView alloc] initWithTitle:@"识别失败" message:@"未知应用" delegate:nil
//                                        cancelButtonTitle:@"确定"  otherButtonTitles:nil, nil];
//        [alert show];
//    }
}






- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *)drawNewImage:(UIImage *)image withRect:(CGRect)rect{

    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
    UIImage *thumbScale = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGSize newSize = CGSizeMake(thumbScale.size.width,thumbScale.size.height);//（需要裁剪的size大小）
    UIGraphicsBeginImageContext(newSize);
    [thumbScale drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
-(BOOL) weixinScreenShoot:(UIImage *)image{
    
    NSString *imagename  = @"temple5s";
    if (image.size.width !=320) {
            imagename =@"temple6plus";
    }
    BOOL sucess = NO;
    for (int i = 1; i <3; i++) {
        NSString *templeName = [NSString stringWithFormat:@"%@%d",imagename,i];
        UIImage *imagetemple = [self drawNewImage:[UIImage imageNamed:templeName] withRect:CGRectMake(0, 0, image.size.width, image.size.height)];
        if (!imagetemple) {
            return NO;
        }
        UIImage *target =self.baseImageView.image;
        UIImage *result=  [opencvImageProc matchTemple:target temple:imagetemple];
        if (result) {
            self.baseImageView.image = result;
            sucess = YES;
        }
    }
    return sucess;
}
@end
