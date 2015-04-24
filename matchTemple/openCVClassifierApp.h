//
//  openCVClassifierApp.h
//  matchTemple
//
//  Created by cici on 15/4/22.
//  Copyright (c) 2015年 xl. All rights reserved.
//
#import <opencv2/ml/ml.hpp>
#import <strings.h>
#import <opencv2/opencv.hpp>
#import <opencv2/nonfree/nonfree.hpp>
#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/core/core_c.h>
#include <stdio.h>

std::string bayesClassifierApp(cv::Mat &image);

cv::Mat creatTestMat(cv::Mat &image);


cv::Mat imageCalcHist(cv::Mat &gary_hist);