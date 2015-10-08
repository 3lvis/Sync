@import CoreData;

@class DATAStack;

@interface NSManagedObject (Sync)

+ (NSManagedObject *)sync_safeObjectInContext:(NSManagedObjectContext *)context
                                   entityName:(NSString *)entityName
                                     remoteID:(id)remoteID
                                       parent:(NSManagedObject *)parent
                       parentRelationshipName:(NSString *)relationshipName
                                        error:(NSError **)error;

- (NSManagedObject *)sync_copyInContext:(NSManagedObjectContext *)context
                                  error:(NSError **)error;

- (void)sync_processRelationshipsUsingDictionary:(NSDictionary *)objectDictionary
                                       andParent:(NSManagedObject *)parent
                                       dataStack:(DATAStack *)dataStack
                                           error:(NSError **)error;

- (void)sync_processToManyRelationship:(NSRelationshipDescription *)relationship
                       usingDictionary:(NSDictionary *)objectDictionary
                             andParent:(NSManagedObject *)parent
                             dataStack:(DATAStack *)dataStack;

- (void)sync_processToOneRelationship:(NSRelationshipDescription *)relationship
                      usingDictionary:(NSDictionary *)objectDictionary
                            andParent:(NSManagedObject *)parent
                            dataStack:(DATAStack *)dataStack
                                error:(NSError **)error;

@end
