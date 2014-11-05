//
//  NSManagedObject+ANDYNetworking.h
//
//  Copyright (c) 2014 Elvis Nuñez. All rights reserved.
//

@import CoreData;

@interface NSManagedObject (ANDYNetworking)

+ (void)andy_processChanges:(NSArray *)changes
            usingEntityName:(NSString *)entityName
                 completion:(void (^)(NSError *error))completion;

+ (void)andy_processChanges:(NSArray *)changes
            usingEntityName:(NSString *)entityName
                  predicate:(NSPredicate *)predicate
                 completion:(void (^)(NSError *error))completion;

+ (void)andy_processChanges:(NSArray *)changes
            usingEntityName:(NSString *)entityName
                     parent:(NSManagedObject *)parent
                 completion:(void (^)(NSError *error))completion;

+ (void)andy_processChanges:(NSArray *)changes
            usingEntityName:(NSString *)entityName
                  predicate:(NSPredicate *)predicate
                     parent:(NSManagedObject *)parent
                  inContext:(NSManagedObjectContext *)context
                 completion:(void (^)(NSError *error))completion;

@end
