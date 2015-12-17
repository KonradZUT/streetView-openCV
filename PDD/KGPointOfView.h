//
//  KGPointOfView.h
//  PDD
//
//  Created by Konrad Gnoinski on 21/11/15.
//  Copyright © 2015 Konrad Gnoinski. All rights reserved.
//

#import <Foundation/Foundation.h>

@import GoogleMaps;

@interface KGPointOfView : NSObject

@property (nonatomic, strong)   CLLocation *        location;
@property (nonatomic, strong)   GMSPanoramaCamera * camera;
@property BOOL                                      isLoaded;

@end
