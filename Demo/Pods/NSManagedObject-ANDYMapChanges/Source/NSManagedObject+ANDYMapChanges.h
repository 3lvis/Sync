//
//  NSManagedObject+ANDYMapChanges.h
//
//  Copyright (c) 2014 Elvis Nuñez. All rights reserved.
//

@import CoreData;

@interface NSManagedObject (ANDYMapChangesPrivate)

+ (NSMutableDictionary *)dictionaryOfIDsAndFetchedIDsInContext:(NSManagedObjectContext *)context
                                                 usingLocalKey:(NSString *)localKey
                                                 forEntityName:(NSString *)entityName;

+ (NSMutableDictionary *)dictionaryOfIDsAndFetchedIDsUsingPredicate:(NSPredicate *)predicate
                                                        andLocalKey:(NSString *)localKey
                                                          inContext:(NSManagedObjectContext *)context
                                                      forEntityName:(NSString *)entityName;

@end

@interface NSManagedObject (ANDYMapChanges)

+ (void)andy_mapChanges:(NSArray *)changes
              inContext:(NSManagedObjectContext *)context
          forEntityName:(NSString *)entityName
               inserted:(void (^)(NSDictionary *objectDict))inserted
                updated:(void (^)(NSDictionary *objectDict, NSManagedObject *object))updated;

+ (void)andy_mapChanges:(NSArray *)changes
               localKey:(NSString *)localKey
              remoteKey:(NSString *)remoteKey
         usingPredicate:(NSPredicate *)predicate
              inContext:(NSManagedObjectContext *)context
          forEntityName:(NSString *)entityName
               inserted:(void (^)(NSDictionary *objectDict))inserted
                updated:(void (^)(NSDictionary *objectDict, NSManagedObject *object))updated;

@end
