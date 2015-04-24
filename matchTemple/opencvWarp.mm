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
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/core/core_c.h>
#import <Foundation/Foundation.h>
#import <opencv2/ml/ml.hpp>
using namespace cv;
using namespace  std;
int N = 21;

void removerNest(const Mat& imagesrc, vector<vector<cv::Point> >& squares);
bool imageRecognition(const Mat &image);
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

// finds a cosine of angle between vectors
// from pt0->pt1 and from pt0->pt2
static double angle( cv::Point pt1, cv::Point pt2,cv::Point pt0 )
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

bool isexist(const vector<vector<cv::Point> >& squares,const vector<cv::Point>& approx ){
    //    return false;
    const cv::Point p0 = approx[0];//左上
    const cv::Point p1 = approx[1];//左下
    const cv::Point p2 = approx[2];//右下
    const cv::Point p3 = approx[3];//右上
    int xmax1 = MAX( MAX(p0.x, p1.x),MAX(p2.x, p3.x));
    int xmin1 = MIN( MIN(p0.x, p1.x),MIN(p2.x, p3.x));
    
    int ymax1 = MAX( MAX(p0.y, p1.y),MAX(p2.y, p3.y));
    int ymin1 = MIN( MIN(p0.y, p1.y),MIN(p2.y, p3.y));
    
    float maxoffset = 16;
    for( size_t i = 0; i < squares.size(); i++ )
    {
        const vector<cv::Point> item = squares[i];
        const cv::Point pp0 = item[0];//左上
        const cv::Point pp1 = item[1];//左下
        const cv::Point pp2 = item[2];//右下
        const cv::Point pp3 = item[3];//右上
        int xmax2 = MAX( MAX(pp0.x, pp1.x),MAX(pp2.x, pp3.x));
        int xmin2 = MIN( MIN(pp0.x, pp1.x),MIN(pp2.x, pp3.x));
        int ymax2 = MAX( MAX(pp0.y, pp1.y),MAX(pp2.y, pp3.y));
        int ymin2 = MIN( MIN(pp0.y, pp1.y),MIN(pp2.y, pp3.y));
        
        double distance1 = pow((xmax1-xmax2),2)+pow(ymax1-ymax2, 2);
        double distance2 = pow((xmin1-xmin2),2)+pow(ymin1-ymin2, 2);
        if (distance1 <maxoffset && distance2<maxoffset) {
            return true;
        }
    }
    
    
    
    return false;
}


bool issquareImage(const Mat &image, const vector<cv::Point> &square)
{
    const cv::Point p0 = square[0];//左上
    const cv::Point p1 = square[1];//左下
    const cv::Point p2 = square[2];//右下
    const cv::Point p3 = square[3];//右上
    
    int xmax = MAX( MAX(p0.x, p1.x),MAX(p2.x, p3.x));
    int xmin = MIN( MIN(p0.x, p1.x),MIN(p2.x, p3.x));
    int ymax = MAX( MAX(p0.y, p1.y),MAX(p2.y, p3.y));
    int ymin = MIN( MIN(p0.y, p1.y),MIN(p2.y, p3.y));
    int cols = abs( xmax- xmin+1);
    int rows = abs(ymax - ymin+1);
    
    Mat subMat = image(cv::Rect(cv::Point(xmin,ymin),cv::Size(cols,rows)));
   
    return imageRecognition(subMat);
   }

void findSquares( const Mat& image, vector<vector<cv::Point> >& squares )
{
    squares.clear();
    

    Mat pyr, timg, gray0(image.size(), CV_8U), gray;
    
    // down-scale and upscale the image to filter out the noise
    pyrDown(image, pyr, cv::Size(image.cols/2, image.rows/2));
    pyrUp(pyr, timg, image.size());
//    timg = image;
    vector<vector<cv::Point> > contours;
    
    // find squares in every color plane of the image
    for( int c = 0; c <3; c++ )
    {
        int ch[] = {c, 0};
        mixChannels(&timg, 1, &gray0, 1, ch, 1);
        // try several threshold levels
        for( int l = 0; l < N; l++ )
        {
            // hack: use Canny instead of zero threshold level.
            // Canny helps to catch squares with gradient shading
            if( l == 0 )
            {
                // apply Canny. Take the upper threshold from slider
                // and set the lower to 0 (which forces edges merging)
                Canny(gray0, gray, 0, 50, 3);
                //dilate canny output to remove potential
                // holes between edge segments
                dilate(gray, gray, Mat(), cv::Point(-1,-1));
            }
            else
            {
                // apply threshold if l!=0:
                //     tgray(x,y) = gray(x,y) < (l+1)*255/N ? 255 : 0
                gray = gray0 >= (l+1)*255/N;
                
            }
            // find contours and store them all as a list
            findContours(gray, contours, RETR_LIST, CHAIN_APPROX_SIMPLE);
            vector<cv::Point> approx;
            
            // test each contour
            for( size_t i = 0; i < contours.size(); i++ )
            {
                // approximate contour with accuracy proportional
                // to the contour perimeter
                approxPolyDP(Mat(contours[i]), approx, arcLength(Mat(contours[i]), true)*0.02, true);
                
                // square contours should have 4 vertices after approximation
                // relatively large area (to filter out noisy contours)
                // and be convex.
                // Note: absolute value of an area is used because
                // area may be positive or negative - in accordance with the
                // contour orientation
                if( approx.size() ==4 &&
                   fabs(contourArea(Mat(approx))) >1000 &&
                   isContourConvex(Mat(approx)) )
                {
                    double maxCosine = 0;
                    
                    for( int j = 2; j < 5; j++ )
                    {
                        // find the maximum cosine of the angle between joint edges
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }
                    
                    // if cosines of all angles are small
                    // (all angles are ~90 degree) then write quandrange
                    // vertices to resultant sequence
                    bool exsit =  isexist(squares, approx);//去重复
                    
                    if( maxCosine < 0.1&&!exsit){//直角 &&未重复
//                        if (issquareImage(image, approx)) {
                            squares.push_back(approx);
//                        }
                    }
                    
                }
            }
        }
    }
    
    removerNest(image, squares);
}




cv::Mat imagecalcHist (const Mat &image){
    
    cv::Mat GrayImage;
    //色彩空间转换，将源彩色图像img转化成目标灰色图像imag1
    cv::cvtColor(image, GrayImage,CV_BGR2GRAY );
    
    /// 设定bin数目
    int histSize = 256;
    
    /// 设定取值范围 ( R,G,B) )
    float range[] = { 0, 256 } ;
    const float* histRange = { range };
    
    bool uniform = true;
    bool accumulate = false;
    
    Mat gary_hist;
    
    /// 计算直方图:
    calcHist(&GrayImage, 1, 0, Mat(), gary_hist, 1, &histSize, &histRange,uniform,accumulate);
    Mat gary_histout(gary_hist.rows,gary_hist.cols,CV_32F);
    normalize(gary_hist,gary_histout,0,1,NORM_MINMAX,-1,Mat());
    return gary_hist;
    
}

bool imageRecognition(const Mat &image){
   
    if(image.rows<30 && image.cols<30){
        return false;
    }
    CvNormalBayesClassifier testNbc;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"result" ofType:@"txt"];

    const CFIndex CASCADE_NAME_LEN = 2048;
    char *CASCADE_NAME = (char *) malloc(CASCADE_NAME_LEN);
    CFStringGetFileSystemRepresentation( (CFStringRef)path, CASCADE_NAME, CASCADE_NAME_LEN);

    testNbc.load(CASCADE_NAME);
    free(CASCADE_NAME);
    
    Mat gary_hist = imagecalcHist(image);
    Mat testSample;
    transpose(gary_hist, testSample);
    float flag = testNbc.predict(testSample);//进行测试

    if (flag<0.9) {
        return false;
    }else{
        return true;
    }
}


//// the function draws all the squares in the image
void removerNest(const Mat& imagesrc, vector<vector<cv::Point> >& squares )
{
    vector<vector<cv::Point>> result ;
    for( size_t i = 0; i < squares.size(); i++ )
    {
        
        const vector<cv::Point> item1 = squares[i];
        const cv::Point p0 = item1[0];//左上
        const cv::Point p1 = item1[1];//左下
        const cv::Point p2 = item1[2];//右下
        const cv::Point p3 = item1[3];//右上
        int xmax1 = MAX( MAX(p0.x, p1.x),MAX(p2.x, p3.x));
        int xmin1 = MIN( MIN(p0.x, p1.x),MIN(p2.x, p3.x));
        int ymax1 = MAX( MAX(p0.y, p1.y),MAX(p2.y, p3.y));
        int ymin1 = MIN( MIN(p0.y, p1.y),MIN(p2.y, p3.y));
        int cols1 = abs( xmax1- xmin1+1);
        int rows1 = abs(ymax1 - ymin1+1);
        
        Mat image ;
        imagesrc.copyTo(image);
        
        for (size_t  j = 0; j<squares.size(); j++) {
            //
            const vector<cv::Point> item2 = squares[j];
            const cv::Point pp0 = item2[0];//左上
            const cv::Point pp1 = item2[1];//左下
            const cv::Point pp2 = item2[2];//右下
            const cv::Point pp3 = item2[3];//右上
            int xmax2 = MAX( MAX(pp0.x, pp1.x),MAX(pp2.x, pp3.x));
            int xmin2 = MIN( MIN(pp0.x, pp1.x),MIN(pp2.x, pp3.x));
            int ymax2 = MAX( MAX(pp0.y, pp1.y),MAX(pp2.y, pp3.y));
            int ymin2 = MIN( MIN(pp0.y, pp1.y),MIN(pp2.y, pp3.y));
            int cols2 = abs( xmax2- xmin2+1);
            int rows2 = abs(ymax2 - ymin2+1);
            
            //存在子矩形
            if (xmin1< xmin2 && ymin1<ymin2 && xmax1>xmax2 && ymax1 >ymax2 &&i!=j) {
                image(cv::Rect(cv::Point(xmin2,ymin2),cv::Size(cols2,rows2))).setTo(Scalar(255,255,255));
            }
        }
        
        Mat subMat = image(cv::Rect(cv::Point(xmin1,ymin1),cv::Size(cols1,rows1)));
    
        if(imageRecognition(subMat)){
            result.push_back(item1);
        }
        
    }
    
    squares = result;
    
}

//// the function draws all the squares in the image
void drawSquares( Mat& imagesrc, const vector<vector<cv::Point> >& squares )
{
    for( size_t i = 0; i < squares.size(); i++ )
    {
        const cv::Point* p = &squares[i][0];
        
        int n = (int)squares[i].size();
        polylines(imagesrc, &p, &n, 1, true, Scalar(0,255,0),3,8,0);
    }

}
bool compare1 (const cv::Rect  &a, const cv::Rect  &b)
{
    cv::Rect rect = a;
    float a1 = rect.width* rect.height;
    
    cv::Rect rect2 = b;
    
    float b1 = rect2.width* rect2.height;
    return (a1-b1)>0;
}

bool insertRect(const cv::Rect&big ,const cv::Rect &small){
    
    if (big.x<=small.x && big.y<=small.y
        &&big.width+big.x>=small.width+small.x
        &&big.height+big.y>=small.height+small.y) {
        return true;
    }else
        return false;
    
}

void findSquare2( const Mat& image){
    
    //
    Mat gray;
    cvtColor(image, gray, CV_BGR2GRAY);
    Mat threshold;
    adaptiveThreshold(gray, threshold, 255, ADAPTIVE_THRESH_MEAN_C,THRESH_BINARY_INV, 3, 5);
    std::vector<vector<cv::Point> > contours;//不规则轮廓
    std::vector<cv::Rect> result;//筛选后的矩形
    dilate(threshold, threshold, Mat(), cv::Point(-1,-1));
    
    findContours(threshold, contours, RETR_LIST, CHAIN_APPROX_SIMPLE);
    
    vector<vector<cv::Point>> drawVector;
    for( int i = 0; i < contours.size(); i++ ){
        cv::Rect rect = boundingRect(contours[i]);
        vector<cv::Point> v;
        v.push_back (cv::Point(rect.x,rect.y));
        v.push_back (cv::Point(rect.x+rect.width,rect.y));
        v.push_back (cv::Point(rect.x+rect.width,rect.y+rect.height));
        v.push_back (cv::Point(rect.x,rect.y+rect.height));
        drawVector.push_back(v);
        if (fabs(contourArea(contours[i]))>100) {
            result.push_back(rect);
        }
    }
    
    std::sort(result.begin(), result.end(), compare1);//从大到小排序
    vector<cv::Rect> imageVector;
    vector<cv::Rect> textVector;
    
    
    vector<cv::Rect>::iterator it;
    for(it = result.begin();it!=result.end();it++){
        
        cv::Rect rectBig = *it;
        Mat copyImage;
        
        image.copyTo(copyImage);
        vector<cv::Rect>::iterator it2;
        
        if (imageRecognition(copyImage(rectBig))) {
            imageVector.push_back(rectBig);
        }else{
            textVector.push_back(rectBig);
        }
        
        
        for (it2 = it+1;it2!=result.end();it2++) {
            cv::Rect rectSmall = *it2;
            if (insertRect(rectBig,rectSmall)) {
                
                if( !imageRecognition(copyImage(rectSmall))){
                    result.erase(it2);
                    it2--;
                }else{
                    //合并
                    for (int k = 0; k<imageVector.size(); k++) {
                        cv::Rect imageR= imageVector.at(k);
                        if (insertRect(imageR, rectSmall)) {
                            result.erase(it2);
                            it2--;
                            break;
                        }
                    }
                    
                }
            }
        }
    }
    vector<vector<cv::Point> > imageVectorPoint;
    vector<vector<cv::Point> > textVectorPoint;
    for( int i = 0; i < imageVector.size(); i++ ){
        vector<cv::Point> v;
        cv::Rect rect = imageVector[i];
        v.push_back (cv::Point(rect.x,rect.y));
        v.push_back (cv::Point(rect.x+rect.width,rect.y));
        v.push_back (cv::Point(rect.x+rect.width,rect.y+rect.height));
        v.push_back (cv::Point(rect.x,rect.y+rect.height));
        imageVectorPoint.push_back(v);
        drawContours(image, imageVectorPoint, i, Scalar(255,0,255), 2);
        
    }
    for( int i = 0; i < textVector.size(); i++ ){
        vector<cv::Point> v;
        cv::Rect rect = textVector[i];
        v.push_back (cv::Point(rect.x,rect.y));
        v.push_back (cv::Point(rect.x,rect.y+rect.height));
        v.push_back (cv::Point(rect.x+rect.width,rect.y+rect.height));
        v.push_back (cv::Point(rect.x+rect.width,rect.y));
        textVectorPoint.push_back(v);
        drawContours(image, textVectorPoint, i, Scalar(0,255,255), 2);
    }
}



//***//分类器区分