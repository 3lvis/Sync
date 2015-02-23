@import CoreData;

@interface NSManagedObject (ANDYObjectIDs)

+ (NSDictionary *)andy_dictionaryOfIDsAndFetchedIDsInContext:(NSManagedObjectContext *)context
                                               usingLocalKey:(NSString *)localKey
                                               forEntityName:(NSString *)entityName;

+ (NSDictionary *)andy_dictionaryOfIDsAndFetchedIDsUsingPredicate:(NSPredicate *)predicate
                                                      andLocalKey:(NSString *)localKey
                                                        inContext:(NSManagedObjectContext *)context
                                                    forEntityName:(NSString *)entityName;

@end
