//
//  UIImage+OpenCV.h
//  PDD
//
//  Created by Konrad Gnoinski on 30/11/14.
//  Copyright (c) 2014 Konrad Gnoinski. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif


@interface UIImage (OpenCV)

+ (UIImage *)imageFromCVMat:(cv::Mat)mat;

- (cv::Mat)cvMatRepresentationColor;
- (cv::Mat)cvMatRepresentationGray;

@end
