//
//  UIImage+OpenCV.h
//  opencvtest
//
//  Created by Engin Kurutepe on 26/01/15.
//  Copyright (c) 2015 Fifteen Jugglers Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/imgproc_c.h>
#endif

@interface UIImage (OpenCV)


+(UIImage *)imageWithCVMat:(const cv::Mat&)cvMat;
-(id)initWithCVMat:(const cv::Mat&)cvMat;

@property(nonatomic, readonly) cv::Mat CVMat;
@property (nonatomic,readonly) cv::Mat CVMatRGB;
@property(nonatomic, readonly) cv::Mat CVGrayscaleMat;
@end
