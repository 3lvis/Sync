#import "NSEntityDescription+SyncPrimaryKey.h"

#import "NSString+SyncInflections.h"
#import "NSPropertyDescription+Sync.h"

@implementation NSEntityDescription (SyncPrimaryKey)

- (nonnull NSAttributeDescription *)sync_primaryKeyAttribute {
    __block NSAttributeDescription *primaryKeyAttribute;

    [self.propertiesByName enumerateKeysAndObjectsUsingBlock:^(NSString *key,
                                                               NSAttributeDescription *attributeDescription,
                                                               BOOL *stop) {
        // TODO: Update here
        NSString *isPrimaryKey = attributeDescription.userInfo[SyncCustomLocalPrimaryKey];
        BOOL hasCustomPrimaryKey = (isPrimaryKey &&
                                    ([isPrimaryKey isEqualToString:SyncCustomLocalPrimaryKeyValue] || [isPrimaryKey isEqualToString:SyncCustomLocalPrimaryKeyAlternativeValue]) );
        if (hasCustomPrimaryKey) {
            primaryKeyAttribute = attributeDescription;
            *stop = YES;
        }

        if ([key isEqualToString:SyncDefaultLocalPrimaryKey] || [key isEqualToString:SyncDefaultLocalCompatiblePrimaryKey]) {
            primaryKeyAttribute = attributeDescription;
        }
    }];

    return primaryKeyAttribute;
}

- (nonnull NSString *)sync_localPrimaryKey {
    NSAttributeDescription *primaryAttribute = [self sync_primaryKeyAttribute];
    NSString *localKey = primaryAttribute.name;

    return localKey;
}

- (nonnull NSString *)sync_remotePrimaryKey {
    NSAttributeDescription *primaryKeyAttribute = [self sync_primaryKeyAttribute];
    NSString *remoteKey = primaryKeyAttribute.customKey;

    if (!remoteKey) {
        if ([primaryKeyAttribute.name isEqualToString:SyncDefaultLocalPrimaryKey] || [primaryKeyAttribute.name isEqualToString:SyncDefaultLocalCompatiblePrimaryKey]) {
            remoteKey = SyncDefaultRemotePrimaryKey;
        } else {
            remoteKey = [primaryKeyAttribute.name hyp_snakeCase];
        }

    }

    return remoteKey;
}

@end
