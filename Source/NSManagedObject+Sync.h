@import CoreData;

@class DATAStack;

@interface NSManagedObject (Sync)

- (void)sync_processRelationshipsUsingDictionary:(NSDictionary *)objectDictionary
                                       andParent:(NSManagedObject *)parent
                                       dataStack:(DATAStack *)dataStack
                                           error:(NSError **)error;

- (void)sync_processToManyRelationship:(NSRelationshipDescription *)relationship
                       usingDictionary:(NSDictionary *)objectDictionary
                             andParent:(NSManagedObject *)parent
                             dataStack:(DATAStack *)dataStack;

@end
