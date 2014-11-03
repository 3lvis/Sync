//
//  NSManagedObject+ANDYNetworking.h
//
//  Copyright (c) 2014 Elvis Nuñez. All rights reserved.
//

@import CoreData;

@interface NSManagedObject (ANDYNetworking)

+ (void)andy_processChanges:(NSArray *)changes
            usingEntityName:(NSString *)entityName
                   localKey:(NSString *)localKey
                  remoteKey:(NSString *)remoteKey
                  predicate:(NSPredicate *)predicate
                 completion:(void (^)())completion;

+ (void)andy_processChanges:(NSArray *)changes
            usingEntityName:(NSString *)entityName
                   localKey:(NSString *)localKey
                  remoteKey:(NSString *)remoteKey
                  predicate:(NSPredicate *)predicate
                     parent:(NSManagedObject *)parent
                  inContext:(NSManagedObjectContext *)context
                 completion:(void (^)())completion;

@end
