//
//  opencvImageProc.m
//  matchTemple
//
//  Created by cici on 15/3/2.
//  Copyright (c) 2015年 xl. All rights reserved.
//



#import "opencvImageProc.h"
#import "opencvWarp.h"
#import "opencv2/highgui/cap_ios.h"
#ifdef __cplusplus
#import <opencv2/opencv.hpp>
//#import <opencv2/features2d.hpp>
#import <opencv2/nonfree/nonfree.hpp>
#endif
#ifdef __cplusplus

#endif
//#import <opencv2/imgcodecs/ios.h>
#import <opencv2/highgui/ios.h>

#import "UIImage+OpenCV.h"
#import <opencv2/highgui/highgui_c.h>
#import <opencv2/imgproc/imgproc_c.h>


using namespace cv;
@implementation opencvImageProc


+ (UIImage *)matchTemple :(UIImage *)image temple:(UIImage *)temple {

    IplImage *pimage = [opencvImageProc convertToIplImage:image];
    IplImage *timage = [opencvImageProc convertToIplImage:temple];
    CvPoint minLoc =  [opencvImageProc CompareTempleImage:timage withImage:pimage];
    if (minLoc.x == pimage->width ||minLoc.y ==pimage ->height) {
        return nil;
    }else{
        cvRectangle(pimage, cvPoint(minLoc.x, minLoc.y), cvPoint(minLoc.x+timage->width, minLoc.y+timage->height), CV_RGB(0,255,0),1);
        return  [opencvImageProc convertToUIImage:pimage];
    }
}

//图片匹配
+(BOOL)ComparePPKImage:(IplImage*)mIplImage withTempleImage:(IplImage*)mTempleImage
{
 
    CvPoint minLoc =[opencvImageProc CompareTempleImage:mTempleImage withImage:mIplImage];
    if (minLoc.x==mIplImage->width || minLoc.y==mIplImage->height) {
        return false;
    }
    return true;
}


/// 基于模板图片的标记识别
+(CvPoint)CompareTempleImage:(IplImage*)templeIpl withImage:(IplImage*)mIplImage
{
    IplImage *src = mIplImage;
    IplImage *templat = templeIpl;
    IplImage *result;
    int srcW, srcH, templatW, templatH, resultH, resultW;
    srcW = src->width;
    srcH = src->height;
    templatW = templat->width;
    templatH = templat->height;
    resultW = srcW - templatW + 1;
    resultH = srcH - templatH + 1;
    result = cvCreateImage(cvSize(resultW, resultH), 32, 1);
    cvMatchTemplate(src, templat, result, CV_TM_SQDIFF_NORMED);
    double minValue, maxValue;
    CvPoint minLoc, maxLoc;
    cvMinMaxLoc(result, &minValue, &maxValue, &minLoc, &maxLoc);
    if (minValue >0.12) {
 
        NSLog(@"失败%lf",minValue);
               return cvPoint(srcW,srcH);
    }
        NSLog(@"成功%lf",minValue);
    return minLoc;
    
}


+(IplImage*)cropIplImage:(IplImage*)srcIpl withStartPoint:(CvPoint)mPoint withWidth:(int)width withHeight:(int)height
{
    //裁剪后的图片
    IplImage *cropImage;
    cvSetImageROI(srcIpl, cvRect(mPoint.x, mPoint.y, width, height));
    cropImage = cvCreateImage(cvGetSize(srcIpl), IPL_DEPTH_8U, 3);
    cvCopy(srcIpl, cropImage);
    cvResetImageROI(srcIpl);
    return cropImage;
}

// 多通道彩色图片的直方图比对
+(double)CompareHist:(IplImage*)image1 withParam2:(IplImage*)image2
{
    int hist_size = 256;
    IplImage *gray_plane = cvCreateImage(cvGetSize(image1), 8, 1);
    cvCvtColor(image1, gray_plane, CV_BGR2GRAY);
    CvHistogram *gray_hist = cvCreateHist(1, &hist_size, CV_HIST_ARRAY);
    cvCalcHist(&gray_plane, gray_hist);
    
    IplImage *gray_plane2 = cvCreateImage(cvGetSize(image2), 8, 1);
    cvCvtColor(image2, gray_plane2, CV_BGR2GRAY);
    CvHistogram *gray_hist2 = cvCreateHist(1, &hist_size, CV_HIST_ARRAY);
    cvCalcHist(&gray_plane2, gray_hist2);
    double rst =cvCompareHist(gray_hist, gray_hist2, CV_COMP_BHATTACHARYYA);  
    printf("对比结果=%f\n",rst);
    return rst;
}


// 单通道彩色图片的直方图
+(double)CompareHistSignle:(IplImage*)image1 withParam2:(IplImage*)image2
{
    int hist_size = 256;
    CvHistogram *gray_hist = cvCreateHist(1, &hist_size, CV_HIST_ARRAY);
    cvCalcHist(&image1, gray_hist);
    
    CvHistogram *gray_hist2 = cvCreateHist(1, &hist_size, CV_HIST_ARRAY);
    cvCalcHist(&image2, gray_hist2);
    
    return cvCompareHist(gray_hist, gray_hist2, CV_COMP_BHATTACHARYYA);
}


/// UIImage类型转换为IPlImage类型
+(IplImage*)convertToIplImage:(UIImage*)image
{
    CGImageRef imageRef = image.CGImage;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    IplImage *iplImage = cvCreateImage(cvSize(image.size.width, image.size.height), IPL_DEPTH_8U, 4);
    CGContextRef contextRef = CGBitmapContextCreate(iplImage->imageData, iplImage->width, iplImage->height, iplImage->depth, iplImage->widthStep, colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, image.size.width, image.size.height), imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    IplImage *ret = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplImage, ret, CV_RGB2BGR);
    cvReleaseImage(&iplImage);
    return ret;
}

/// IplImage类型转换为UIImage类型
+(UIImage*)convertToUIImage:(IplImage*)image
{
    cvCvtColor(image, image, CV_BGR2RGB);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(image->width, image->height, image->depth, image->depth * image->nChannels, image->widthStep, colorSpace, kCGImageAlphaNone | kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return ret;
}




+(UIImage *)stitcherImage:(NSArray *)arrayImages{
    
    __block std::vector<Mat> images;
    cv::Mat pano;
    [arrayImages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
       
        UIImage *image = obj;
        cv::Mat mat = [image CVMat];
        cv::Mat dst;
        cvtColor(mat, dst, CV_RGBA2RGB);
        
        
        images.push_back(dst);
    }];
    
    stitchingImage(images,pano);

    UIImage *result = MatToUIImage(pano);
    return result;
}

+(UIImage *)fetchImage:(UIImage*)templet{

    float scale = 1;
    cv::Mat src ;
    UIImageToMat(templet, src);
    cv::Mat dsc;
    cv::resize(src, dsc,cv::Size(src.cols*scale,src.rows*scale));
    
//
    
    cv::vector<vector<cv::Point> > squares;
    
    //找出矩形区域
    findSquares(dsc, squares);
    //画出矩形区域
    drawSquares(dsc, squares);
    
    UIImage *image = MatToUIImage(dsc);
    
    return image;

}
@end
