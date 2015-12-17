//
//  ViewController.m
//  GPSandHeading
//
//  Created by Konrad Gnoinski on 11/12/15.
//  Copyright © 2015 Konrad Gnoinski. All rights reserved.
//

#import "StreetViewSensorsViewController.h"
#import "KGPointOfView.h"
#import "DownloadViewController.h"
#import "ImageProcessor.h"
#import "DatabaseManager.h"
#import "PointOfView.h"

@import GoogleMaps;


@interface StreetViewSensorsViewController () <CLLocationManagerDelegate, GMSPanoramaViewDelegate>

// Layout
@property (weak, nonatomic)     IBOutlet    UILabel         *latitudeValue;
@property (weak, nonatomic)     IBOutlet    UILabel         *longitudeValue;
@property (weak, nonatomic)     IBOutlet    UILabel         *accurency;
@property (weak, nonatomic)     IBOutlet    UILabel         *heading;
@property (weak, nonatomic)     IBOutlet    UIImageView     *imageView;
@property (weak, nonatomic)     IBOutlet    UIView          *panoramaView;

// Camera Capture
@property (strong, nonatomic)   AVCaptureSession            *session;
@property (strong, nonatomic)   dispatch_queue_t            sessionQueue;
@property (strong, nonatomic)   AVCaptureStillImageOutput   *stillCameraOutput;
@property (strong, nonatomic)   AVCaptureVideoPreviewLayer  *previewLayer;
@property (strong, nonatomic)   UIImage                     *capturedImage;

// Location
@property (nonatomic, strong)   GMSPanoramaView             *panorama;
@property (nonatomic, strong)   CLLocation                  *currentLocation;
@property (readwrite)           CLLocationDirection         currentHeading;  //could possibly be stored as ID object, may contain other usefull info
#warning check if contains more usefull data in heading

@property (nonatomic, strong)   ImageProcessor              *imageProcessor;
//Events
- (IBAction)takePicture:(id)sender;
- (IBAction)reset:(id)sender;

@end

@implementation StreetViewSensorsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self startUpdatingLocation];
    [self startUpdatingHeading];
    [self initCamera];
    [self initPanoramaView];
    self.imageProcessor = [[ImageProcessor alloc] init];
}

-(void) initPanoramaView{
    self.panorama = [[GMSPanoramaView alloc] init];
    self.panorama.delegate = self;
    self.panorama.orientationGestures = YES;
    self.panorama.navigationGestures = NO;
    self.panorama.navigationLinksHidden = YES;
    [self.panoramaView addSubview: self.panorama];
}


-(void)initCamera{
    self.session = [[AVCaptureSession alloc] init];
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetiFrame960x540]) {
        [self.session setSessionPreset:AVCaptureSessionPresetiFrame960x540]; //requested capture quality
    }
    
    AVCaptureDevice *backCameraDevice;//camera selection
    NSArray *availableCameraDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in availableCameraDevices) {
        if (device.position == AVCaptureDevicePositionBack) {
            backCameraDevice = device;
        }
    }
    
    if (backCameraDevice){
        //error no back camera found
    }
    
    NSError *error;
    AVCaptureDeviceInput *possibleCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice: backCameraDevice error: &error];
    if (possibleCameraInput) {
        if([self.session canAddInput:possibleCameraInput]) {
            [self.session addInput:possibleCameraInput]; //add camera input to session
        }
    }
    
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authorizationStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted){
                [self startUpdatingCamera];
            }
            else {
                // user denied camera access
            }
        }];
    }
    
    if (authorizationStatus == AVAuthorizationStatusAuthorized) {
        [self startUpdatingCamera];
    }
    
    if (authorizationStatus == AVAuthorizationStatusDenied || AVAuthorizationStatusRestricted){
        //error
    }
}

- (void)startUpdatingCamera{
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession: self.session]; //live preview
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.imageView.layer addSublayer:self.previewLayer];
    
    self.sessionQueue = dispatch_queue_create("com.example.camera.capture\_session", DISPATCH_QUEUE_SERIAL);
    dispatch_async(self.sessionQueue, ^{
        if (![self.session isRunning])
            [self.session startRunning];//sesion runs on side thread, to prevent blocking interface
    });
    
    self.stillCameraOutput = [[AVCaptureStillImageOutput alloc] init];
    if ([self.session canAddOutput:self.stillCameraOutput]) {
        [self.session addOutput: self.stillCameraOutput];
    }
    AVCaptureConnection *previewLayerConnection=self.previewLayer.connection;
    [previewLayerConnection setVideoOrientation:(AVCaptureVideoOrientation)[[UIDevice currentDevice] orientation]];
}


- (void)startUpdatingLocation
{
    if (nil == locationManager)
        locationManager = [[CLLocationManager alloc] init];
    
    [locationManager requestAlwaysAuthorization];
    
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    
    [locationManager startUpdatingLocation];
}

- (void)startUpdatingHeading
{
    locationManager.distanceFilter = 1000;
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    [locationManager startUpdatingLocation];
    
    if ([CLLocationManager headingAvailable]) {
        locationManager.headingFilter = 5;
        [locationManager startUpdatingHeading];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    self.latitudeValue.text = [[NSNumber numberWithDouble:location.coordinate.latitude] stringValue]; //nsstrings are to get more precise value than float
    self.longitudeValue.text = [[NSNumber numberWithDouble:location.coordinate.longitude] stringValue];
    self.accurency.text = [NSString stringWithFormat:@"%f", location.horizontalAccuracy];
    self.currentLocation = location;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    if (newHeading.headingAccuracy < 0)
        return;
    
    // Use the true heading if it is valid.
    CLLocationDirection heading = fmodf(((newHeading.trueHeading > 0) ?
                                       newHeading.trueHeading : newHeading.magneticHeading) + 90, 360);
    
    self.heading.text = [NSString stringWithFormat:@"%f",heading];
    self.currentHeading = heading;
}

- (IBAction)takePicture:(id)sender {
    dispatch_async(self.sessionQueue, ^{//runs on other thread, to prevent blocking UI
        AVCaptureConnection *connection = [self.stillCameraOutput connectionWithMediaType:AVMediaTypeVideo];
        
        if([connection isVideoOrientationSupported])
        {
            [connection setVideoOrientation:(AVCaptureVideoOrientation)[[UIDevice currentDevice] orientation]];
        }
        
        
        [self.stillCameraOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                if (error == nil) {
                    NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation: imageDataSampleBuffer]; //no other format possible directly
                    
#warning Ask if it is possible to use some capture parameters to improve image matching
                    
                    self.capturedImage = [UIImage imageWithData:imageData];
                    // the sample buffer also contains the metadata, in case we want to modify it
                    NSDictionary *metadata = CFBridgingRelease(CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate));
//                    CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)).takeUnretainedValue()
                    self.imageView.image = self.capturedImage;
                    [self.previewLayer removeFromSuperlayer];
                
                    [self moveToCurrentLocation];
                }else {
                    NSLog(@"error while capturing still image: \(error)");
                }
            }];
    });
}

-(void) moveToCurrentLocation{
    [self.imageProcessor setQueryImage:self.capturedImage withFeatureDetector:CVFeatureDetectorTypeAKAZE];
    
    NSArray *points = [DatabaseManager allPointsOfView];
    PointOfView *point = [self.imageProcessor findClosestStreetViewMatch:points withFeatureDetector:CVFeatureDetectorTypeAKAZE];
    
    
    [self.panorama moveNearCoordinate:CLLocationCoordinate2DMake([point.locationLat doubleValue], [point.locationLong doubleValue])];
    self.panorama.camera = [GMSPanoramaCamera cameraWithHeading:[point.heading doubleValue]
                                                          pitch:-10
                                                           zoom:1];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"segueToDownload"]) {
        DownloadViewController *destViewController = segue.destinationViewController;
        // set whatever you want here in your destination view controller
        destViewController.startingPoint = self.currentLocation;
    }
}

- (IBAction)reset:(id)sender {
    [self.imageView.layer addSublayer:self.previewLayer];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    // AUTOGENERATED - do not touch
    [self.previewLayer setFrame: self.imageView.bounds];
    [self.panorama setFrame: self.panoramaView.bounds];
}

@end











