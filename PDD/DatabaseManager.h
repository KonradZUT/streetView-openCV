//
//  DatabaseManager.h
//  PDD
//
//  Created by Konrad Gnoinski on 16/12/14.
//  Copyright (c) 2014 Konrad Gnoinski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PointOfView.h"

@import GoogleMaps;

@interface DatabaseManager : NSObject

+ (PointOfView *)insertPointOfViewWithLocation: (CLLocation*)location heading: (CLLocationDirection)heading dataID: (NSString *)dataID;
+ (NSArray *)allPointsOfView;
+ (void)removeAllPointsOfView;
+ (NSArray *)pointsOfViewCloseToLocation:(CLLocation *)location distance:(CLLocationDistance *) distance;

@end
