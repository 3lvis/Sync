#import "NSPropertyDescription+Sync.h"

#import "NSEntityDescription+SyncPrimaryKey.h"

@implementation NSPropertyDescription (Sync)

- (BOOL)isCustomPrimaryKey {
    NSString *keyName = self.userInfo[SyncCustomLocalPrimaryKey];
    if (keyName == nil) {
        keyName = self.userInfo[SyncCompatibilityCustomLocalPrimaryKey];
    }

    BOOL hasCustomPrimaryKey = (keyName &&
                                ([keyName isEqualToString:SyncCustomLocalPrimaryKeyValue] || [keyName isEqualToString:SyncCustomLocalPrimaryKeyAlternativeValue]) );

    return hasCustomPrimaryKey;
}

- (NSString *)customKey {
    NSString *keyName = self.userInfo[SyncCustomRemoteKey];
    if (keyName == nil) {
        keyName = self.userInfo[SyncCompatibilityCustomRemoteKey];
    }

    return keyName;
}

@end
