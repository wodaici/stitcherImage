//
//  openvcwarp.cpp
//  matchTemple
//
//  Created by cici on 15/3/6.
//  Copyright (c) 2015年 xl. All rights reserved.
//

#include "opencvWarp.h"
//#include <opencv2/stitching.hpp>
#include <opencv2/stitching/stitcher.hpp>
#include <opencv2/highgui/highgui_c.h>
#import <opencv2/opencv.hpp>
//#import <opencv2/features2d.hpp>
#import <opencv2/nonfree/nonfree.hpp>
#import <opencv2/imgproc/imgproc_c.h>
using namespace cv;
using namespace  std;



void stitchingImage(vector<Mat>imgs,cv::Mat &pano){

    
    Stitcher stitcher = Stitcher::createDefault(false);
    stitcher.setRegistrationResol(1);//设置分辨率
    stitcher.setSeamEstimationResol(0.01);//缝隙估计融合参数 0.1
    stitcher.setCompositingResol(-1);//默认－1
    stitcher.setPanoConfidenceThresh(.6);
    stitcher.setWaveCorrection(false);//默认是true，为加速选false，表示跳过WaveCorrection步骤
    stitcher.setWaveCorrectKind(detail::WAVE_CORRECT_VERT);//波段修正(wave correction)功能（水平方向/垂直方向修正）
    
    
    //找特征点surf算法，此算法计算量大,但对刚体运动、缩放、环境影响等情况下较为稳定
//    cv::initModule_nonfree();
//    cv::Ptr<detail::SurfFeaturesFinder> featureFinder ( new detail::SurfFeaturesFinder());
//    stitcher.setFeaturesFinder(featureFinder);
    
    //找特征点ORB算法
    cv::Ptr<detail::OrbFeaturesFinder> featureFinder(new detail::OrbFeaturesFinder());
    stitcher.setFeaturesFinder(featureFinder);
    
    //Features matcher which finds two best matches for each feature and leaves the best one only if the ratio between descriptor distances is greater than the threshold match_conf.
    cv::Ptr<detail::BestOf2NearestMatcher> matcher ( new detail::BestOf2NearestMatcher(false, 0.2f));
    stitcher.setFeaturesMatcher(matcher);
    
    
    // Rotation Estimation,It takes features of all images, pairwise matches between all images and estimates rotations of all cameras.
    //Implementation of the camera parameters refinement algorithm which minimizes sum of the distances between the rays passing through the camera center and a feature,这个耗时短
    cv::Ptr<detail::BundleAdjusterRay> adjusterray (new  detail::BundleAdjusterRay());
    stitcher.setBundleAdjuster(adjusterray);
    
    cv::Ptr<detail::GraphCutSeamFinder> finder(new detail::GraphCutSeamFinder(detail::GraphCutSeamFinderBase::COST_COLOR));
    stitcher.setSeamFinder(finder);
//    stitcher.setSeamFinder(new detail::GraphCutSeamFinder(detail::GraphCutSeamFinderBase::COST_COLOR_GRAD));
//    stitcher.setSeamFinder(new detail::VoronoiSeamFinder);
//    stitcher.setSeamFinder(new detail::NoSeamFinder);
    
    
    //曝光补偿
//    cv::Ptr<detail::BlocksGainCompensator> compensator (new detail::BlocksGainCompensator());
//    stitcher.setExposureCompensator(compensator);//默认的就是这个
    //Exposure compensator which tries to remove exposure related artifacts by adjusting image intensities
//    stitcher.setExposureCompensator(new detail::GainCompensator());
    //Exposure compensator which tries to remove exposure related artifacts by adjusting image block intensities
//    stitcher.setExposureCompensator(new detail::BlocksGainCompensator());
    //不要曝光补偿
    stitcher.setExposureCompensator(new detail::NoExposureCompensator());
    
    
    //Image Blenders
//    stitcher.setBlender(new detail::MultiBandBlender(false));//默认的是这个
    
    //Simple blender which mixes images at its borders
    cv::Ptr<detail::FeatherBlender> blender (new detail::FeatherBlender());
    stitcher.setBlender(blender);//这个简单，耗时少
    
    //默认为球面
    cv::Ptr<PlaneWarper> cw( new PlaneWarper());
    stitcher.setWarper(cw);
    
    //去除navigationbar的影响
    cv::Mat mat = imgs[0];
    std::vector<cv::Rect> rect;
    cv::Rect item ;
    item.x = 0;
    item.y = 64*2;
    item.width = mat.cols;
    item.height = (mat.rows -item.y);
    rect.push_back(item);
    std::vector<std::vector<cv::Rect>> rois;
    
    rois.push_back(rect);
    rois.push_back(rect);
    
    Stitcher::Status status = stitcher.estimateTransform(imgs,rois);
    if (status != Stitcher::OK)
    {
        cout << "Can't stitch images, error code = " << int(status) << endl;
    }else{
        status = stitcher.composePanorama(pano);
        if (status != Stitcher::OK)
        {
            cout << "Can't stitch images, error code = " << int(status) << endl;
        }
    }
}