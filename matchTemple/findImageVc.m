//
//  findImageVc.m
//  matchTemple
//
//  Created by cici on 15/3/19.
//  Copyright (c) 2015年 xl. All rights reserved.
//

#import "findImageVc.h"
#import "opencvImageProc.h"

@interface findImageVc()
@property (nonatomic,strong) UIActivityIndicatorView *activityIndicator;
@end
@implementation findImageVc


-(void)viewDidAppear:(BOOL)animated{
    self.navigationController.hidesBarsOnTap = YES;
    [self.rootimage setFrame:self.view.bounds];
    [super viewDidAppear:animated];
    

}

-(void)viewDidLoad{

    [super viewDidLoad];
    UIActivityIndicatorView* activityIndicatorView = [ [ UIActivityIndicatorView  alloc ] initWithFrame:CGRectMake(0,0,30.0,30.0)];
    activityIndicatorView.center = self.view.center;
    activityIndicatorView.activityIndicatorViewStyle= UIActivityIndicatorViewStyleWhiteLarge;
    activityIndicatorView.hidesWhenStopped = YES;
    [self.view addSubview:activityIndicatorView ];
    self.activityIndicator = activityIndicatorView;
    
    if (self.isAppclassify) {
        self.title = @"app分类";
    }
    

}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"goView2"]) //"goView2"是SEGUE连线的标识
    {
        id theSegue = segue.destinationViewController;
        [theSegue setValue:@"这里是要传递的值" forKey:@"strTtile"];
    }
}

- (IBAction)addClicked:(id)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = NO;
    picker.delegate = self;
    [self.navigationController presentViewController:picker animated:YES completion:^{
        
    }];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo{
    
    
    if (image ) {
        
        self.rootimage.image =  image;
        [self dismissViewControllerAnimated:YES
                                 completion:nil];
       
        __weak findImageVc *weak = self;
        [self.activityIndicator startAnimating ];//启动
        
        if (self.isAppclassify) {
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSString *result =[opencvImageProc classiflerApp:image];
                dispatch_async(dispatch_get_main_queue(), ^{
                    
               
                    
                    [weak.activityIndicator stopAnimating];
                    weak.activityIndicator.hidden  = YES;
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"识别结果" message:result delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
                    [alert show];
                    
                });
                
            });

            
        }else{
          dispatch_async(dispatch_get_global_queue(0, 0), ^{
            UIImage *result =[opencvImageProc fetchImage:image];
            dispatch_async(dispatch_get_main_queue(), ^{
              
                weak.rootimage.image = result;
                [weak.activityIndicator stopAnimating];
                weak.activityIndicator.hidden  = YES;
            
            });

          });
        
        }
    }
    
    
    
    

}

@end
