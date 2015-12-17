//
//  ImageProcessor.mm
//  PDD
//
//  Created by Konrad Gnoinski on 30/11/14.
//  Copyright (c) 2014 Konrad Gnoinski. All rights reserved.
//

#import "ImageProcessor.h"
#import "UIImage+OpenCV.h"


#ifdef __cplusplus
#include <opencv2/opencv.hpp>
#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/features2d/features2d.hpp>
#include <opencv2/calib3d/calib3d.hpp>
#include <opencv2/imgproc/imgproc_c.h>
#endif

#define nn_match_ratio 0.8f
#define inlier_threshold 2.5f

using namespace cv;

cv::Mat queryMat;
std::vector<KeyPoint> queryKeypoints;
@interface ImageProcessor ()

@property (nonatomic, strong) NSMutableDictionary *labelsDictionary;

@end

@implementation ImageProcessor

- (void) setQueryImage:(UIImage *)image withFeatureDetector:(CVFeatureDetectorType)detectorType
{
    NSDate *start = [NSDate date];
    Ptr<Feature2D> detector;

    switch (detectorType) {
        case CVFeatureDetectorTypeBRISK:
        default:
            detector = BRISK::create();
            break;
        case CVFeatureDetectorTypeORB:
            detector = ORB::create();
            break;
        case CVFeatureDetectorTypeKAZE:
            detector = KAZE::create();
            break;
        case CVFeatureDetectorTypeAKAZE:
            detector = AKAZE::create();
            break;
    }
    
    cv::Mat imageMat = [image cvMatRepresentationColor];
    detector->detectAndCompute(imageMat, noArray(), queryKeypoints, queryMat);
    NSLog(@"Time it took to detect and compute queryImage: %f", -[start timeIntervalSinceNow]);
}

- (void)detectKeypoints:(UIImage *)image withFeatureDetector:(CVFeatureDetectorType)detectorType storeAS:(NSString*) path
{
    cv::Mat imageMat = [image cvMatRepresentationColor];
    
    Ptr<Feature2D> detector;
    switch (detectorType) {
        case CVFeatureDetectorTypeBRISK:
        default:
            detector = BRISK::create();
            break;
        case CVFeatureDetectorTypeORB:
            detector = ORB::create();
            break;
        case CVFeatureDetectorTypeKAZE:
            detector = KAZE::create();
            break;
        case CVFeatureDetectorTypeAKAZE:
            detector = AKAZE::create();
            break;
    }
    
    Mat desc;
    std::vector<KeyPoint> keypoints;
    NSDate *start = [NSDate date];
    detector->detectAndCompute(imageMat, noArray(), keypoints, desc);
    NSLog(@"Time it took to detect and compute : %f", -[start timeIntervalSinceNow]);
    start = [NSDate date];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *fullPath = [[paths firstObject] stringByAppendingPathComponent:path];
    FileStorage fs([fullPath UTF8String], FileStorage::WRITE);
    fs << "desc" << desc;
    fs << "keypoints" << keypoints;
    fs.release();
    NSLog(@"Time it took to store : %f", -[start timeIntervalSinceNow]);
}

- (PointOfView *)findClosestStreetViewMatch:(NSArray *)streetView withFeatureDetector:(CVFeatureDetectorType)detectorType;
{
    NSDate *start = [NSDate date];
    int bestMatchScore = 0;
    PointOfView *bestPoint;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    for(PointOfView *point in streetView){
        
        Mat desc;
        std::vector<KeyPoint> keypoints;
        NSString *fullPath = [[paths firstObject] stringByAppendingPathComponent:point.dataID];
        FileStorage fs2([fullPath UTF8String], FileStorage::READ);
        
        fs2["desc"] >> desc;
        fs2["keypoints"] >> keypoints;
        fs2.release();

        BFMatcher matcher(NORM_HAMMING);
        std::vector< std::vector<DMatch> > nn_matches;
        matcher.knnMatch(desc, queryMat, nn_matches, 2);
        
        std::vector<KeyPoint> matched1, matched2, inliers1, inliers2;
        std::vector<DMatch> good_matches;
        for(size_t i = 0; i < nn_matches.size(); i++) {
            DMatch first = nn_matches[i][0];
            float dist1 = nn_matches[i][0].distance;
            float dist2 = nn_matches[i][1].distance;
            if(dist1 < nn_match_ratio * dist2) {
                matched1.push_back(keypoints[first.queryIdx]);
                matched2.push_back(queryKeypoints[first.trainIdx]);
            }
        }
        
        //NSLog(@"%f", -[start timeIntervalSinceNow]);
        
        for(unsigned i = 0; i < matched1.size(); i++) {
            Mat col = Mat::ones(3, 1, CV_64F);
            col.at<double>(0) = matched1[i].pt.x;
            col.at<double>(1) = matched1[i].pt.y;
            //col = homography * col;
            col /= col.at<double>(2);
            double dist = sqrt( pow(col.at<double>(0) - matched2[i].pt.x, 2) +
                               pow(col.at<double>(1) - matched2[i].pt.y, 2));
            if(dist < inlier_threshold) {
                int new_i = static_cast<int>(inliers1.size());
                inliers1.push_back(matched1[i]);
                inliers2.push_back(matched2[i]);
                good_matches.push_back(DMatch(new_i, new_i, 0));
            }
        }
        
        if (bestMatchScore < matched1.size()) {
            bestMatchScore = (int)matched1.size();
            bestPoint = point;
        }
        
        
        NSLog(@"%lu %lu %lu %lu",keypoints.size(), queryKeypoints.size(), matched1.size(), good_matches.size());
        //NSLog(@"%f", -[start timeIntervalSinceNow]);
        
        //cvtColor(srcMat, srcMat, CV_BGRA2BGR);
    //    cvtColor(queryMat, queryMat, CV_BGRA2BGR);
        //Mat res;
    //    drawMatches(srcMat, inliers1, queryMat, inliers2, good_matches, res);
        
        
        
    }
    NSLog(@"Time it took to check streetViewKeypoints %f", -[start timeIntervalSinceNow]);
    return bestPoint;
}

- (UIImage *)computeSimilarities:(UIImage *)srcImage queryImage:(UIImage *)queryImage withFeatureDetector:(CVFeatureDetectorType)detectorType
{
    cv::Mat srcMat   = [srcImage cvMatRepresentationColor];
    cv::Mat queryMat = [queryImage cvMatRepresentationColor];
    
    Ptr<Feature2D> detector;
    switch (detectorType) {
        case CVFeatureDetectorTypeBRISK:
        default:
            detector = BRISK::create();
            break;
        case CVFeatureDetectorTypeORB:
            detector = ORB::create();
            break;
        case CVFeatureDetectorTypeKAZE:
            detector = KAZE::create();
            break;
        case CVFeatureDetectorTypeAKAZE:
            detector = AKAZE::create();
            break;
    }
    
    Mat desc1, desc2;
    std::vector<KeyPoint> keypointsSRC, keypointsQuery;
    NSDate *start = [NSDate date];
    //detector->detectAndCompute(srcMat, noArray(), keypointsSRC, desc1);
    
    detector->detect(srcMat, keypointsSRC);
    NSLog(@"%f", -[start timeIntervalSinceNow]);
    detector->compute(srcMat, keypointsSRC, desc1);
    
    NSLog(@"%f", -[start timeIntervalSinceNow]);
    
    detector->detectAndCompute(queryMat, noArray(), keypointsQuery, desc2);
    
    
    NSLog(@"%f", -[start timeIntervalSinceNow]);
    
    
    BFMatcher matcher(NORM_HAMMING);
    std::vector< std::vector<DMatch> > nn_matches;
    matcher.knnMatch(desc1, desc2, nn_matches, 2);
    
    
    NSLog(@"%f", -[start timeIntervalSinceNow]);
    
    
    std::vector<KeyPoint> matched1, matched2, inliers1, inliers2;
    std::vector<DMatch> good_matches;
    for(size_t i = 0; i < nn_matches.size(); i++) {
        DMatch first = nn_matches[i][0];
        float dist1 = nn_matches[i][0].distance;
        float dist2 = nn_matches[i][1].distance;
        if(dist1 < nn_match_ratio * dist2) {
            matched1.push_back(keypointsSRC[first.queryIdx]);
            matched2.push_back(keypointsQuery[first.trainIdx]);
        }
    }
    
    //Mat homography = findHomography( srcMat, queryMat, CV_RANSAC );
    Mat homography = (Mat_<double>(3,3) << 0.76285898, -0.29922929, 225.67123, 0.33443473, 1.0143901, -76.999973, 0.00034663091, -0.000014364524, 1.0000000);
    
    NSLog(@"%f", -[start timeIntervalSinceNow]);
    
    for(unsigned i = 0; i < matched1.size(); i++) {
        Mat col = Mat::ones(3, 1, CV_64F);
        col.at<double>(0) = matched1[i].pt.x;
        col.at<double>(1) = matched1[i].pt.y;
        col = homography * col;
        col /= col.at<double>(2);
        double dist = sqrt( pow(col.at<double>(0) - matched2[i].pt.x, 2) +
                           pow(col.at<double>(1) - matched2[i].pt.y, 2));
        if(dist < inlier_threshold) {
            int new_i = static_cast<int>(inliers1.size());
            inliers1.push_back(matched1[i]);
            inliers2.push_back(matched2[i]);
            good_matches.push_back(DMatch(new_i, new_i, 0));
        }
    }
    
    NSLog(@"%f", -[start timeIntervalSinceNow]);
    
    cvtColor(srcMat, srcMat, CV_BGRA2BGR);
    cvtColor(queryMat, queryMat, CV_BGRA2BGR);
    Mat res;
    drawMatches(srcMat, inliers1, queryMat, inliers2, good_matches, res);
    
    double inlier_ratio = inliers1.size() * 1.0 / matched1.size();
    NSLog(@"A-KAZE Matching Results");
    NSLog(@"# Keypoints 1:                        %lu", keypointsSRC.size());
    NSLog(@"# Keypoints 2:                        %lu", keypointsQuery.size());
    NSLog(@"# Matches:                            %lu", matched1.size());
    NSLog(@"# Inliers:                            %lu", inliers1.size());
    NSLog(@"# Inliers Ratio:                      %f", inlier_ratio);
    
    return [UIImage imageFromCVMat:res];
    
}
@end
