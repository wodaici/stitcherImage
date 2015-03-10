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