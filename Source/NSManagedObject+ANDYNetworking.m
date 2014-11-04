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
                  predicate:(NSPredicate *)predicate
                 completion:(void (^)())completion
{
    [ANDYDataManager performInBackgroundContext:^(NSManagedObjectContext *context) {
        [self processChanges:changes
             usingEntityName:entityName
                   predicate:predicate
                      parent:nil
                   inContext:context
                  completion:completion];
    }];
}

+ (void)andy_processChanges:(NSArray *)changes
            usingEntityName:(NSString *)entityName
                  predicate:(NSPredicate *)predicate
                     parent:(NSManagedObject *)parent
                  inContext:(NSManagedObjectContext *)context
                 completion:(void (^)())completion;
{
    [self processChanges:changes
         usingEntityName:entityName
               predicate:predicate
                  parent:parent
               inContext:context
              completion:completion];
}

+ (void)processChanges:(NSArray *)changes
       usingEntityName:(NSString *)entityName
             predicate:(NSPredicate *)predicate
                parent:(NSManagedObject *)parent
             inContext:(NSManagedObjectContext *)context
            completion:(void (^)())completion
{
    [[self class] andy_mapChanges:changes
                   usingPredicate:predicate
                        inContext:context
                    forEntityName:entityName
                         inserted:^(NSDictionary *objectDict) {

                             NSManagedObject *created = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                                      inManagedObjectContext:context];
                             [created hyp_fillWithDictionary:objectDict];

                             [created processRelationshipsUsingDictionary:objectDict andParent:parent];

                         } updated:^(NSDictionary *objectDict, NSManagedObject *object) {

                             [object hyp_fillWithDictionary:objectDict];

                         }];

    NSError *error = nil;
    [context save:&error];
    if (error) NSLog(@"ANDYNetworking (error while saving %@): %@", entityName, [error description]);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) completion();
    });
}

- (void)processRelationshipsUsingDictionary:(NSDictionary *)objectDict
                                  andParent:(NSManagedObject *)parent
{
    NSMutableArray *relationships = [NSMutableArray array];

    for (id propertyDescription in [self.entity properties]) {

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
            NSPredicate *childPredicate = [NSPredicate predicateWithFormat:@"%@ = %@", inverseEntityName, self];

            [[self class] processChanges:childs
                         usingEntityName:childEntityName
                               predicate:childPredicate
                                  parent:self
                               inContext:self.managedObjectContext
                              completion:nil];
        } else if (parent) {
            [self setValue:parent forKey:relationship.name];
        }
    }
}

@end
