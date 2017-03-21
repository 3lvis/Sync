#import "NSPropertyDescription+Sync.h"

#import "NSEntityDescription+SyncPrimaryKey.h"

@implementation NSPropertyDescription (Sync)

- (NSString *)customKey {
    NSString *keyName = self.userInfo[SyncCustomRemoteKey];
    if (keyName == nil) {
        keyName = self.userInfo[SyncCompatibilityCustomRemoteKey];
    }

    return keyName;
}

@end
