@import CoreData;

@interface NSManagedObject (Sync)

+ (NSManagedObject *)sync_safeObjectInContext:(NSManagedObjectContext *)context
                                   entityName:(NSString *)entityName
                                     remoteID:(id)remoteID
                                       parent:(NSManagedObject *)parent
                       parentRelationshipName:(NSString *)relationshipName
                                        error:(NSError **)error;

- (NSManagedObject *)sync_copyInContext:(NSManagedObjectContext *)context
                                  error:(NSError **)error;

- (NSArray *)sync_relationships;

@end
