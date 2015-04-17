@import CoreData;

@class DATAStack;

static NSString * const SyncCustomPrimaryKey = @"hyper.isPrimaryKey";
static NSString * const SyncCustomRemoteKey = @"hyper.remoteKey";

@interface NSEntityDescription (Sync)

- (NSString *)sync_remoteKey;
- (NSString *)sync_localKey;

@end

@interface NSManagedObject (Sync)

- (void)sync_processRelationshipsUsingDictionary:(NSDictionary *)objectDict
                                       andParent:(NSManagedObject *)parent
                                       dataStack:(DATAStack *)dataStack;

@end

@interface Sync : NSObject

+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
      dataStack:(DATAStack *)dataStack
     completion:(void (^)(NSError *error))completion;

+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
      predicate:(NSPredicate *)predicate
      dataStack:(DATAStack *)dataStack
     completion:(void (^)(NSError *error))completion;

+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
         parent:(NSManagedObject *)parent
      dataStack:(DATAStack *)dataStack
     completion:(void (^)(NSError *error))completion;

@end
