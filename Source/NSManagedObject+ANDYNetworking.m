//
//  NSManagedObject+ANDYNetworking.m
//
//  Copyright (c) 2014 Elvis Nuñez. All rights reserved.
//

#import "NSManagedObject+ANDYNetworking.h"

#import "NSManagedObject+HYPPropertyMapper.h"
#import "NSManagedObject+ANDYMapChanges.h"
#import "ANDYDataManager.h"

@implementation NSManagedObject (ANDYNetworking)

+ (void)andy_processChanges:(NSArray *)changes
            usingEntityName:(NSString *)entityName
                   localKey:(NSString *)localKey
                  remoteKey:(NSString *)remoteKey
                  predicate:(NSPredicate *)predicate
                 completion:(void (^)())completion
{
    [ANDYDataManager performInBackgroundContext:^(NSManagedObjectContext *context) {
        [self processChanges:changes usingEntityName:entityName localKey:localKey remoteKey:remoteKey
                   predicate:predicate inContext:context completion:completion];
    }];
}

+ (void)andy_processChanges:(NSArray *)changes
            usingEntityName:(NSString *)entityName
                   localKey:(NSString *)localKey
                  remoteKey:(NSString *)remoteKey
                  predicate:(NSPredicate *)predicate
                  inContext:(NSManagedObjectContext *)context
                 completion:(void (^)())completion
{
    [self processChanges:changes usingEntityName:entityName localKey:localKey remoteKey:remoteKey
               predicate:predicate inContext:context completion:completion];
}

+ (void)processChanges:(NSArray *)changes
       usingEntityName:(NSString *)entityName
              localKey:(NSString *)localKey
             remoteKey:(NSString *)remoteKey
             predicate:(NSPredicate *)predicate
             inContext:(NSManagedObjectContext *)context
            completion:(void (^)())completion
{
    [[self class] andy_mapChanges:changes
                         localKey:localKey
                        remoteKey:remoteKey
                   usingPredicate:predicate
                        inContext:context
                    forEntityName:entityName
                         inserted:^(NSDictionary *objectDict) {

                             NSManagedObject *created = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                                      inManagedObjectContext:context];
                             [created hyp_fillWithDictionary:objectDict];

                         } updated:^(NSDictionary *objectDict, NSManagedObject *object) {

                             [object hyp_fillWithDictionary:objectDict];

                         }];

    [context save:nil];

    if (completion) completion();
}

@end
