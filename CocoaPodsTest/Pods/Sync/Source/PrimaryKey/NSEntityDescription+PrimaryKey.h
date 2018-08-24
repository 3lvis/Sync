@import CoreData;

NS_ASSUME_NONNULL_BEGIN

static NSString * const SyncDefaultLocalPrimaryKey = @"id";
static NSString * const SyncDefaultLocalCompatiblePrimaryKey = @"remoteID";

static NSString * const SyncDefaultRemotePrimaryKey = @"id";

@interface NSEntityDescription (PrimaryKey)

/**
 Returns the Core Data attribute used as the primary key. By default it will look for the attribute named `id`.
 You can mark any attribute as primary key by adding `sync.isPrimaryKey` and the value `YES` to the Core Data model userInfo.

 @return The attribute description that represents the primary key.
 */
- (NSAttributeDescription *)sync_primaryKeyAttribute;

/**
 Returns the local primary key for the entity.

 @return The name of the attribute that represents the local primary key;.
 */
- (NSString *)sync_localPrimaryKey;

/**
 Returns the remote primary key for the entity.

 @return The name of the attribute that represents the remote primary key.
 */
- (NSString *)sync_remotePrimaryKey;

@end

NS_ASSUME_NONNULL_END
