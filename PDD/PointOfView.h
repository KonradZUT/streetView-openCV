//
//  PointOfView.m
//  PDD
//
//  Created by Konrad Gnoinski on 16/12/15.
//  Copyright © 2015 Konrad Gnoinski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface PointOfView : NSManagedObject

@property (nonatomic, retain) NSString *dataID;
@property (nonatomic, retain) NSNumber *heading;
@property (nonatomic, retain) NSNumber *locationLat;
@property (nonatomic, retain) NSNumber *locationLong;

@end
