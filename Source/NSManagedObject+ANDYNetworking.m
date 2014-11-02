//
//  NSManagedObject+ANDYNetworking.m
//
//  Copyright (c) 2014 Elvis Nuñez. All rights reserved.
//

#import "NSManagedObject+ANDYNetworking.h"

#import "NSDictionary+ANDYSafeValue.h"
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
                   predicate:predicate parent:nil inContext:context completion:completion];
    }];
}

+ (void)andy_processChanges:(NSArray *)changes
            usingEntityName:(NSString *)entityName
                   localKey:(NSString *)localKey
                  remoteKey:(NSString *)remoteKey
                  predicate:(NSPredicate *)predicate
                     parent:(NSManagedObject *)parent
                  inContext:(NSManagedObjectContext *)context
                 completion:(void (^)())completion;
{
    [self processChanges:changes usingEntityName:entityName localKey:localKey remoteKey:remoteKey
               predicate:predicate parent:parent inContext:context completion:completion];
}

+ (void)processChanges:(NSArray *)changes
       usingEntityName:(NSString *)entityName
              localKey:(NSString *)localKey
             remoteKey:(NSString *)remoteKey
             predicate:(NSPredicate *)predicate
                parent:(NSManagedObject *)parent
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

                             NSMutableArray *relationships = [NSMutableArray array];

                             for (id propertyDescription in [created.entity properties]) {

                                 if ([propertyDescription isKindOfClass:[NSRelationshipDescription class]]) {
                                     [relationships addObject:propertyDescription];
                                 }
                             }

                             for (NSRelationshipDescription *relationship in relationships) {
                                 if (relationship.isToMany) {
                                     NSArray *childs = [objectDict andy_valueForKey:relationship.name];
                                     if (!childs) continue;

                                     NSString *childEntityName = relationship.destinationEntity.name;
                                     NSString *inverseEntityName = relationship.inverseRelationship.name;
                                     NSPredicate *childPredicate = [NSPredicate predicateWithFormat:@"%@ = %@", inverseEntityName, created];
                                     [[self class] processChanges:childs
                                                  usingEntityName:childEntityName
                                                         localKey:@"id"
                                                        remoteKey:@"id"
                                                        predicate:childPredicate
                                                           parent:created
                                                        inContext:context
                                                       completion:nil];
                                 } else if (parent) {
                                     [created setValue:parent forKey:relationship.name];
                                 }
                             }

                         } updated:^(NSDictionary *objectDict, NSManagedObject *object) {

                             [object hyp_fillWithDictionary:objectDict];

                         }];

    [context save:nil];

    if (completion) completion();
}

@end
