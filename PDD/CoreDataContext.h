//
//  CoreDataContext.h
//  PDD
//
//  Created by Konrad Gnoinski on 16/12/14.
//  Copyright (c) 2014 Konrad Gnoinski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Questionaire;

@interface CoreDataContext : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;


+ (CoreDataContext *)getInstance;
- (void)saveContext;

@end
