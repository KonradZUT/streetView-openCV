//
//  ImageProcessor.h
//  PDD
//
//  Created by Konrad Gnoinski on 30/11/14.
//  Copyright (c) 2014 Konrad Gnoinski. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "PointOfView.h"


@interface ImageProcessor : NSObject

typedef NS_ENUM(NSUInteger, CVFeatureDetectorType) {
    CVFeatureDetectorTypeORB,
    CVFeatureDetectorTypeBRISK,
    CVFeatureDetectorTypeKAZE,
    CVFeatureDetectorTypeAKAZE,
};

- (UIImage *)computeSimilarities:(UIImage *)srcImage queryImage:(UIImage *)queryImage withFeatureDetector:(CVFeatureDetectorType)detectorType;

- (void)detectKeypoints:(UIImage *)image withFeatureDetector:(CVFeatureDetectorType)detectorType storeAS:(NSString*) name;

- (void) setQueryImage:(UIImage *)image withFeatureDetector:(CVFeatureDetectorType)detectorType;

- (PointOfView *)findClosestStreetViewMatch:(NSArray *)streetView withFeatureDetector:(CVFeatureDetectorType)detectorType;

@end
