@import CoreData;

@interface NSManagedObject (Sync)

+ (NSManagedObject *)sync_safeObjectInContext:(NSManagedObjectContext *)context
                                   entityName:(NSString *)entityName
                                     remoteID:(id)remoteID
                                       parent:(NSManagedObject *)parent
                       parentRelationshipName:(NSString *)relationshipName;

- (NSManagedObject *)sync_copyInContext:(NSManagedObjectContext *)context;

- (NSArray *)sync_relationships;

@end
