//
//  openvcwarp.h
//  matchTemple
//
//  Created by cici on 15/3/6.
//  Copyright (c) 2015年 xl. All rights reserved.
//

#ifndef __matchTemple__openvcwarp__
#define __matchTemple__openvcwarp__

#include <stdio.h>
#import <opencv2/opencv.hpp>
#endif /* defined(__matchTemple__openvcwarp__) */
void stitchingImage(std::vector<cv::Mat>imgs,cv::Mat &pano);

void stitchingImage2(std::vector<cv::Mat>imgs,cv::Mat &pano);

bool issquareImage(const cv::Mat &image, const std::vector<cv::Point> &square);

void findSquares( const cv::Mat& image, std::vector<std::vector<cv::Point> >&squares);
void drawSquares( cv::Mat& imagesrc, const std::vector<std::vector<cv::Point> >& squares);
void findSquare2( const cv::Mat& image);