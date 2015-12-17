//
//  DatabaseManager.m
//  PDD
//
//  Created by Konrad Gnoinski on 16/12/14.
//  Copyright (c) 2014 Konrad Gnoinski. All rights reserved.
//

#import "DatabaseManager.h"
#import "CoreDataContext.h"

@implementation DatabaseManager

+ (PointOfView *)insertPointOfViewWithLocation: (CLLocation*)location heading: (CLLocationDirection)heading dataID: (NSString *)dataID
{
        PointOfView* pointOfView = [NSEntityDescription insertNewObjectForEntityForName:@"PointOfView" inManagedObjectContext:[CoreDataContext getInstance].managedObjectContext];
    
    
        pointOfView.locationLat = [NSNumber numberWithDouble: location.coordinate.latitude];
        pointOfView.locationLong = [NSNumber numberWithDouble: location.coordinate.longitude];
        pointOfView.heading = [NSNumber numberWithInt: (int)heading];
        pointOfView.dataID = dataID;
    
    
        [[CoreDataContext getInstance] saveContext];
        return pointOfView;
};

+ (NSArray *)allPointsOfView{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc]init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PointOfView" inManagedObjectContext:[CoreDataContext getInstance].managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError *error = nil;
    
    NSArray *fetchedObjects = [[CoreDataContext getInstance].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error != nil)
        NSLog(@"Unresolved error: %@, %@", error, [error userInfo]);
    return fetchedObjects;
}

+ (void)removeAllPointsOfView{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PointOfView" inManagedObjectContext:[CoreDataContext getInstance].managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError *error = nil;
    
    NSArray *fetchedObjects = [[CoreDataContext getInstance].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects != nil && error == nil) {
        for (NSManagedObject *object in fetchedObjects) {
            [[CoreDataContext getInstance].managedObjectContext deleteObject:object];
        }
    }else {
        NSLog(@"Unresolved error: %@, %@", error, [error userInfo]);
    }
    
    [[CoreDataContext getInstance] saveContext];
}

+ (NSArray *)pointsOfViewCloseToLocation:(CLLocation *)location distance:(CLLocationDistance *) distance{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PointOfView" inManagedObjectContext: [CoreDataContext getInstance].managedObjectContext];
    [fetchRequest setEntity:entity];
//    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"value=%@", value]];
#warning just fallen asllep/complete later
    NSError *error = nil;
    NSArray *fetchedObjects = [[CoreDataContext getInstance].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if(error==nil){
        if([fetchedObjects count] != 0)
        {
            return [fetchedObjects objectAtIndex:0];
        }
    }
    return nil;
}

@end
