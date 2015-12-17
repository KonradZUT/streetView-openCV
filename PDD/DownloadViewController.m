//
//  ViewController.m
//  PDD
//
//  Created by Konrad Gnoinski on 17/11/15.
//  Copyright © 2015 Konrad Gnoinski. All rights reserved.
//

#import "DownloadViewController.h"
#import <malloc/malloc.h>
#import <objc/runtime.h>
#import "KGPointOfView.h"
#import "ImageProcessor.h"
#import "DatabaseManager.h"

@import GoogleMaps;

@interface DownloadViewController ()<GMSPanoramaViewDelegate>

//Street View
@property (nonatomic, strong)   GMSPanoramaView *           panorama;
@property (nonatomic, strong)   NSMutableArray *            pointsOfView;
@property (nonatomic, strong)   ImageProcessor *            imageProcessor;
@property (nonatomic, strong)   NSTimer *                   timer;

@end

int point = 0;
BOOL shouldTakeImage = NO;

@implementation DownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"Documents Directory: %@", [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject]);
    self.imageProcessor = [[ImageProcessor alloc] init];
//    double lat = 50.10324;
//    double lng = 14.390529;
//    self.startingPoint = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
    self.pointsOfView = [[NSMutableArray alloc] init];
    
    [self spiral:4];
    
    self.panorama = [[GMSPanoramaView alloc] init];
    
    self.panorama.delegate = self;
    self.panorama.orientationGestures = YES;
    self.panorama.navigationGestures = NO;
    self.panorama.navigationLinksHidden = YES;
    self.panorama.streetNamesHidden = YES;
    self.view = self.panorama;
    
    [self moveToLocation];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(moveToLocation) userInfo:nil repeats:YES];
}


-(void) spiral: (int) area {
    int x,y,dx,dy,X,Y,t;
    KGPointOfView *point;
    X = Y = t = area;
    x = y = dx =0;
    dy = -1;
    int maxI = t*t;
    for(int i =0; i < maxI; i++){
        if ((-X/2 <= x) && (x <= X/2) && (-Y/2 <= y) && (y <= Y/2)){
            //NSLog(@"%d, %d", x,y);
            for (int i=0; i<=330; i+=30) {
                point = [[KGPointOfView alloc]init];
                point.location = [[CLLocation alloc] initWithLatitude:self.startingPoint.coordinate.latitude + 0.0003f*x longitude:self.startingPoint.coordinate.longitude + 0.0005f*y];
                point.camera = [GMSPanoramaCamera cameraWithHeading:i pitch:10 zoom:0];
                [self.pointsOfView addObject:point];
            }
            NSLog(@"%f,%f",point.location.coordinate.latitude, point.location.coordinate.longitude);
        }
        if( (x == y) || ((x < 0) && (x == -y)) || ((x > 0) && (x == 1-y))){
            t = dx;
            dx = -dy;
            dy = t;
        }
        x += dx;
        y += dy;
    }
}

-(void)moveToLocation{
    if ([self.pointsOfView count] != point) {
    
        KGPointOfView *pointOfView = [self.pointsOfView objectAtIndex: point];
        
        [self captureView:pointOfView];
        
        [self.panorama moveNearCoordinate:pointOfView.location.coordinate];
        self.panorama.camera = pointOfView.camera;
        point++;
    }else{
        [self performSelectorOnMainThread:@selector(stopTimer) withObject:nil waitUntilDone:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (UIImage *)captureView:(KGPointOfView *) point {
    GMSPanoramaView *panormaa = (GMSPanoramaView *)self.view;
    
    unsigned int count;
    Ivar *ivars = class_copyIvarList([GMSPanoramaView class], &count);
    for (unsigned int i = 0; i < count; i++) {
        Ivar ivar = ivars[i];
        
        const char *name = ivar_getName(ivar);
        const char *type = ivar_getTypeEncoding(ivar);
        ptrdiff_t offset = ivar_getOffset(ivar);
        
        if (strncmp(type, "i", 1) == 0) {
            int intValue = *(int*)((uintptr_t)panormaa + offset);
            //            NSLog(@"%s = %i", name, intValue);
        } else if (strncmp(type, "f", 1) == 0) {
            float floatValue = *(float*)((uintptr_t)panormaa + offset);
            //            NSLog(@"%s = %f", name, floatValue);
        } else if (strncmp(type, "@", 1) == 0) {
            id value = object_getIvar(panormaa, ivar);
            //            NSLog(@"%s = %@", name, value);
            if ([@"_loadingIndicator" isEqualToString:[NSString stringWithUTF8String:name]]){
                if (!value) {
                    CGRect rect = CGRectMake(0, 8, self.view.bounds.size.width, self.view.bounds.size.height-26);
                    
                    UIGraphicsBeginImageContext(rect.size);
                    CGContextRef context = UIGraphicsGetCurrentContext();
                    [self.view.layer renderInContext:context];
                    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    
                    
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString *imagePath = [NSString stringWithFormat:@"%f,%f,%d", point.location.coordinate.latitude, point.location.coordinate.longitude, (int)point.camera.orientation.heading];
                    imagePath = [imagePath stringByReplacingOccurrencesOfString:@"." withString:@""];
                    imagePath = [imagePath stringByAppendingString:@".xml"];
                    
                    [self.imageProcessor detectKeypoints:img withFeatureDetector:CVFeatureDetectorTypeAKAZE storeAS:imagePath];
                    [DatabaseManager insertPointOfViewWithLocation:point.location heading:point.camera.orientation.heading dataID:imagePath];
                }
            }
        }
    }
    
    free(ivars);
    return nil;
}

- (void) stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

@end
