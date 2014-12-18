#import "NSManagedObject+ANDYMapChanges.h"

#import "NSManagedObject+ANDYObjectIDs.h"

@implementation NSManagedObject (ANDYMapChanges)

+ (void)andy_mapChanges:(NSArray *)changes
              inContext:(NSManagedObjectContext *)context
          forEntityName:(NSString *)entityName
               inserted:(void (^)(NSDictionary *objectDict))inserted
                updated:(void (^)(NSDictionary *objectDict, NSManagedObject *object))updated
{
    [self andy_mapChanges:changes
           usingPredicate:nil
                inContext:context
            forEntityName:entityName
                 inserted:inserted
                  updated:updated];
}

+ (void)andy_mapChanges:(NSArray *)changes
         usingPredicate:(NSPredicate *)predicate
              inContext:(NSManagedObjectContext *)context
          forEntityName:(NSString *)entityName
               inserted:(void (^)(NSDictionary *objectDict))inserted
                updated:(void (^)(NSDictionary *objectDict, NSManagedObject *object))updated
{
    [self andy_mapChanges:changes
                 localKey:[NSString stringWithFormat:@"%@ID", [entityName lowercaseString]]
                remoteKey:@"id"
           usingPredicate:predicate
                inContext:context
            forEntityName:entityName
                 inserted:inserted
                  updated:updated];
}

+ (void)andy_mapChanges:(NSArray *)changes
               localKey:(NSString *)localKey
              remoteKey:(NSString *)remoteKey
         usingPredicate:(NSPredicate *)predicate
              inContext:(NSManagedObjectContext *)context
          forEntityName:(NSString *)entityName
               inserted:(void (^)(NSDictionary *objectDict))inserted
                updated:(void (^)(NSDictionary *objectDict, NSManagedObject *object))updated
{
    NSDictionary *dictionaryIDAndObjectID = nil;

    if (predicate) {
        dictionaryIDAndObjectID = [self andy_dictionaryOfIDsAndFetchedIDsUsingPredicate:predicate
                                                                            andLocalKey:localKey
                                                                              inContext:context
                                                                          forEntityName:entityName];
    } else {
        dictionaryIDAndObjectID = [self andy_dictionaryOfIDsAndFetchedIDsInContext:context
                                                                     usingLocalKey:localKey
                                                                     forEntityName:entityName];
    }

    NSArray *fetchedObjectIDs = [dictionaryIDAndObjectID allKeys];
    NSMutableArray *remoteObjectIDs = [[changes valueForKey:remoteKey] mutableCopy];
    [remoteObjectIDs removeObject:[NSNull null]];

    NSMutableSet *intersection = [NSMutableSet setWithArray:remoteObjectIDs];
    [intersection intersectSet:[NSSet setWithArray:fetchedObjectIDs]];
    NSArray *updatedObjectIDs = [intersection allObjects];

    NSMutableArray *deletedObjectIDs = [NSMutableArray arrayWithArray:fetchedObjectIDs];
    [deletedObjectIDs removeObjectsInArray:remoteObjectIDs];

    NSMutableArray *insertedObjectIDs = [NSMutableArray arrayWithArray:remoteObjectIDs];
    [insertedObjectIDs removeObjectsInArray:fetchedObjectIDs];

    for (NSNumber *fetchedID in deletedObjectIDs) {
        NSManagedObjectID *objectID = [dictionaryIDAndObjectID objectForKey:fetchedID];
        if (objectID) {
            NSManagedObject *object = [context objectWithID:objectID];
            if (object) {
                [context deleteObject:object];
            }
        }
    }

    for (NSNumber *fetchedID in insertedObjectIDs) {
        [changes enumerateObjectsUsingBlock:^(NSDictionary *objectDict, NSUInteger idx, BOOL *stop) {
            if ([[objectDict objectForKey:remoteKey] isEqual:fetchedID]) {
                if (inserted) {
                    inserted(objectDict);
                }
            }
        }];
    }

    for (NSNumber *fetchedID in updatedObjectIDs) {
        [changes enumerateObjectsUsingBlock:^(NSDictionary *objectDict, NSUInteger idx, BOOL *stop) {
            if ([[objectDict objectForKey:remoteKey] isEqual:fetchedID]) {
                NSManagedObjectID *objectID = [dictionaryIDAndObjectID objectForKey:fetchedID];
                if (objectID) {
                    NSManagedObject *object = [context objectWithID:objectID];
                    if (object && updated) {
                        updated(objectDict, object);
                    }
                }
            }
        }];
    }
}

@end
