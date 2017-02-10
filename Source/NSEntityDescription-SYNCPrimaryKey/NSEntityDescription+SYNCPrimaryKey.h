@import CoreData;

NS_ASSUME_NONNULL_BEGIN

static NSString * const SYNCDefaultLocalPrimaryKey = @"id";
static NSString * const SYNCDefaultLocalCompatiblePrimaryKey = @"remoteID";

static NSString * const SYNCDefaultRemotePrimaryKey = @"id";

static NSString * const SYNCCustomLocalPrimaryKey = @"hyper.isPrimaryKey";
static NSString * const SYNCCustomLocalPrimaryKeyValue = @"YES";
static NSString * const SYNCCustomLocalPrimaryKeyAlternativeValue = @"true";

static NSString * const SYNCCustomRemoteKey = @"hyper.remoteKey";

@interface NSEntityDescription (SYNCPrimaryKey)

/**
 Returns the Core Data attribute used as the primary key. By default it will look for the attribute named `id`.
 You can mark any attribute as primary key by adding `hyper.isPrimaryKey` and the value `YES` to the Core Data model userInfo.

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
