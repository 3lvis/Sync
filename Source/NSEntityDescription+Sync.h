@import CoreData;

static NSString * const SyncDefaultLocalPrimaryKey = @"remoteID";
static NSString * const SyncDefaultRemotePrimaryKey = @"id";

static NSString * const SyncCustomPrimaryKey = @"hyper.isPrimaryKey";
static NSString * const SyncCustomRemoteKey = @"hyper.remoteKey";

@interface NSEntityDescription (Sync)

- (NSString *)sync_remoteKey;
- (NSString *)sync_localKey;
- (NSAttributeDescription *)sync_primaryKeyAttribute;

@end
