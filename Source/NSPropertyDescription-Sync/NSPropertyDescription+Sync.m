#import "NSPropertyDescription+Sync.h"

#import "NSEntityDescription+SyncPrimaryKey.h"

static NSString * const SyncCustomLocalPrimaryKey = @"sync.isPrimaryKey";
static NSString * const SyncCompatibilityCustomLocalPrimaryKey = @"hyper.isPrimaryKey";
static NSString * const SyncCustomLocalPrimaryKeyValue = @"YES";
static NSString * const SyncCustomLocalPrimaryKeyAlternativeValue = @"true";

static NSString * const SyncCustomRemoteKey = @"sync.remoteKey";
static NSString * const SyncCompatibilityCustomRemoteKey = @"hyper.remoteKey";

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
