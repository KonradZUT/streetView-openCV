//
//  ViewController.m
//  PDDPhoneApp
//
//  Created by Konrad Gnoinski on 30/11/15.
//  Copyright © 2015 Konrad Gnoinski. All rights reserved.
//

#import "OpenCVViewController.h"
#import "ImageProcessor.h"

@interface OpenCVViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation OpenCVViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImage *srcImage   = [UIImage imageNamed:@"g1.png"];
    UIImage *queryImage = [UIImage imageNamed:@"g2.png"];
    
    ImageProcessor *imgProc = [[ImageProcessor alloc] init];
    self.imageView.image = [imgProc computeSimilarities:srcImage queryImage:queryImage withFeatureDetector:CVFeatureDetectorTypeAKAZE];
//    UIImage *openCVGrayImage = [imgProc detectKeypoints:srcImage withFeatureDetector:CVFeatureDetectorTypeAKAZE];
    
//    self.image2.image = openCVGrayImage;
    
    //NSArray* srcImageData = [imgProc detectKeypoints:srcImage withFeatureDetector:CVFeatureDetectorTypeAKAZE];
    //[imgProc compareImages:srcImageData queryImageIndex:nil withFeatureDetector:CVFeatureDetectorTypeAKAZE];
    //cv::Mat a = [UIImage cvMatRepresentationColor:openCVImage];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
