//
//  findImageVc.m
//  matchTemple
//
//  Created by cici on 15/3/19.
//  Copyright (c) 2015年 xl. All rights reserved.
//

#import "findImageVc.h"
#import "opencvImageProc.h"
@implementation findImageVc

-(void)viewDidAppear:(BOOL)animated{
    self.navigationController.hidesBarsOnTap = YES;
    

    [self.rootimage setFrame:self.view.bounds];
    [super viewDidAppear:animated];
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
    
    
    if (image) {
        
//        self.rootimage.image =  image;
        [self dismissViewControllerAnimated:YES
                                 completion:nil];
    
       
        __weak findImageVc *weak = self;
      dispatch_async(dispatch_get_global_queue(0, 0), ^{
          
        UIImage *result =[opencvImageProc fetchImage:image];
        dispatch_async(dispatch_get_main_queue(), ^{
        
            weak.rootimage.image = result;
        });

      });
    
    
    }

}

@end
