#import "NSEntityDescription+Sync.h"

#import "NSString+HYPNetworking.h"

@implementation NSEntityDescription (Sync)

- (NSAttributeDescription *)sync_primaryKeyAttribute
{
    __block NSAttributeDescription *primaryKeyAttribute;

    [self.propertiesByName enumerateKeysAndObjectsUsingBlock:^(NSString *key,
                                                               NSAttributeDescription *attributeDescription,
                                                               BOOL *stop) {
        NSString *isPrimaryKey = attributeDescription.userInfo[SyncCustomPrimaryKey];
        BOOL hasCustomPrimaryKey = (isPrimaryKey &&
                                    [isPrimaryKey isEqualToString:@"YES"]);

        if (hasCustomPrimaryKey) {
            primaryKeyAttribute = attributeDescription;
            *stop = YES;
        }

        if ([key isEqualToString:SyncDefaultLocalPrimaryKey]) {
            primaryKeyAttribute = attributeDescription;
        }
    }];

    return primaryKeyAttribute;
}

- (NSString *)sync_localKey
{
    NSString *localKey;
    NSAttributeDescription *primaryAttribute = [self sync_primaryKeyAttribute];

    localKey = primaryAttribute.name;

    return localKey;
}

- (NSString *)sync_remoteKey
{
    NSAttributeDescription *primaryAttribute = [self sync_primaryKeyAttribute];
    NSString *remoteKey = primaryAttribute.userInfo[SyncCustomRemoteKey];

    if (!remoteKey) {
        if ([primaryAttribute.name isEqualToString:SyncDefaultLocalPrimaryKey]) {
            remoteKey = SyncDefaultRemotePrimaryKey;
        } else {
            remoteKey = [primaryAttribute.name hyp_remoteString];
        }

    }

    return remoteKey;
}

@end


