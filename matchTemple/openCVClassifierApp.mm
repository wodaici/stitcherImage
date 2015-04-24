//
//  openCVClassifierApp.m
//  matchTemple
//
//  Created by cici on 15/4/22.
//  Copyright (c) 2015年 xl. All rights reserved.
//

#import "openCVClassifierApp.h"
#import <Foundation/Foundation.h>
using namespace std;
using namespace cv;


bool isScreenShootImage(cv::Mat &image);
string appName(int flag){


    switch (flag) {
        case 0:
            return "不识别" ;
        case 1:
            return "微信";
            break;
        case 2:
            return "淘宝" ;
        case 3:
            return "QQ" ;
        case 4:
            return "网易新闻客户端" ;
        case 5:
            return "支付宝" ;
        case 6:
            return "美团" ;
        case 7:
            return "信息" ;
        case 8:
            return "Path" ;
        case 9:
            return "Safari" ;
        case 10:
            return "微博" ;
        default:
            return "不是iphone截图";
            break;
    }
}
cv::Mat imagecalcHistHSV (const Mat &image,const Mat &mask){
    
    int h_bins = 16, s_bins = 8,v_bins = 1;
    int hist_size[] = {h_bins,s_bins,v_bins};
    float h_ranges[] = {0,180};
    float s_ranges[] = {0,256};
    float v_ranges[] = {0,256};
    const float *ranges[]= {h_ranges,s_ranges,v_ranges};
    Mat hsvImage;
    cvtColor(image, hsvImage, COLOR_RGB2HSV);
    
    int channel[] = {0,1,2};
    cv::MatND histogram;
    calcHist(&hsvImage, 1, channel, mask, histogram, 3, hist_size, ranges,true,false);
    
    cv::Mat result(h_bins *s_bins *v_bins,1,CV_32FC1) ;
    
    for (int h= 0; h <h_bins; h++) {
        for (int s = 0; s<s_bins; s++) {
            for (int v =0 ; v<v_bins; v++) {
                int index = h*s_bins +s*v_bins +v;
                result.at<float>(index,0) =histogram.at<float>(h,s,v);
                
                
                
            }
        }
    }
    
    Mat out;
    normalize(result,out,0,1,NORM_MINMAX,-1,Mat());
    
    return out;
    
}
string bayesClassifierApp(cv::Mat &image){

    
    CvNormalBayesClassifier testNbc;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"result256_10_2" ofType:@"txt"];

    const CFIndex CASCADE_NAME_LEN = 2048;
    char *CASCADE_NAME = (char *) malloc(CASCADE_NAME_LEN);
    CFStringGetFileSystemRepresentation( (CFStringRef)path, CASCADE_NAME, CASCADE_NAME_LEN);
    testNbc.load(CASCADE_NAME);
    free(CASCADE_NAME);
    
    if (!isScreenShootImage(image)) {//最大10倍 960 ＊640
        return appName(-1);
    }else{
        Mat testSample =  creatTestMat(image);
        float flag = testNbc.predict(testSample);//进行测试
        testNbc.clear();
        return appName(flag);
    }
}

bool isScreenShootImage(cv::Mat &image){
    int width = image.cols;
    int height = image.rows;
    float r = height/width;
    float d = 0.01;
    float r1 = 960/640;
    float r2 = 1136/640;
    float r3 = 1334/750;
    float r4 = 2208/1242;
    if (abs(r-r1)<d ||abs(r-r2)<d||abs(r-r3)<d ||abs(r-r4)<d) {
        return YES;
    }else{
        return NO;
    }
    
}

cv::Mat creatTestMat(cv::Mat &image){

    
    Mat testSample(1, 128*2, CV_32FC1);//构建测试样本
    cv::Mat src = image;//rgb
    float scale = 0.5f;
    cv::Mat dsc;
    cv::resize(src, dsc,cv::Size(src.cols*scale,src.rows*scale));
    
    cv::Mat mask (dsc.rows,dsc.cols,CV_8U);
    mask.setTo(0);
    
    cv::Rect rect (0,0,dsc.cols,64);
    mask(rect).setTo(1);
    
    Mat histTop = imagecalcHistHSV(dsc,mask);
    mask.setTo(0);
    cv::Rect rect2(0,dsc.rows - 50,dsc.cols,50);
    mask(rect2).setTo(1);
    Mat histBottom = imagecalcHistHSV(dsc,mask);
    
    for (int i = 0; i<histTop.rows; i++) {
        testSample.at<float>(0,i) = histTop.at<float>(i,0);
    }
    
    for (int i = 0; i<histBottom.rows; i++) {
        testSample.at<float>(0,histTop.rows+i) = histBottom.at<float>(i,0);
    }
    return testSample;

}


cv::Mat imageCalcHist(Mat &gary_hist){
    
    
    // 创建直方图画布
    int histSize = MAX(gary_hist.rows, gary_hist.cols);
    int bin_w = 2;
    int hist_w = histSize*bin_w+10;
    int hist_h = 100;
    
    
    Mat histImage( hist_h, hist_w, CV_8UC3, Scalar( 0,0,0 ) );
    Mat gary_histout;
    normalize(gary_hist,gary_histout,hist_h,0,NORM_MINMAX,-1,Mat());
    
    /// 在直方图画布上画出直方图
    for( int i = 1; i <= histSize; i++ )
    {
        line( histImage, cv::Point( bin_w*(i-1)+5, hist_h - cvRound(gary_histout.at<float>(i-1)) ) ,
             cv::Point( bin_w*(i)+5, hist_h - cvRound(gary_histout.at<float>(i)) ),
             Scalar( 0, 0, 255), 2, 4,0 );
        
    }
    
    double tmpCountMinVal = 0, tmpCountMaxVal = 0;
    cv::Point minPoint, maxPoint;
    minMaxLoc(gary_histout, &tmpCountMinVal, &tmpCountMaxVal, &minPoint, &maxPoint);
    
 
    cout<<"max="<<maxPoint<<tmpCountMaxVal<<"  min="<<minPoint<<tmpCountMinVal<<endl;
    return  histImage;
    
}
