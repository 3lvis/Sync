#import "NSPropertyDescription+Sync.h"

#import "NSEntityDescription+PrimaryKey.h"
#import "NSManagedObject+PropertyMapperHelpers.h"

static NSString * const SyncCustomLocalPrimaryKey = @"sync.isPrimaryKey";
static NSString * const SyncCompatibilityCustomLocalPrimaryKey = @"hyper.isPrimaryKey";
static NSString * const SyncCustomLocalPrimaryKeyValue = @"YES";
static NSString * const SyncCustomLocalPrimaryKeyAlternativeValue = @"true";

static NSString * const SyncCustomRemoteKey = @"sync.remoteKey";
static NSString * const SyncCompatibilityCustomRemoteKey = @"hyper.remoteKey";

static NSString * const PropertyMapperNonExportableKey = @"sync.nonExportable";
static NSString * const PropertyMapperCompatibilityNonExportableKey = @"hyper.nonExportable";

static NSString * const PropertyMapperCustomValueTransformerKey = @"sync.valueTransformer";
static NSString * const PropertyMapperCompatibilityCustomValueTransformerKey = @"hyper.valueTransformer";

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

- (BOOL)shouldExportAttribute {
    NSString *nonExportableKey = self.userInfo[PropertyMapperNonExportableKey];
    if (nonExportableKey == nil) {
        nonExportableKey = self.userInfo[PropertyMapperCompatibilityNonExportableKey];
    }

    BOOL shouldExportAttribute = (nonExportableKey == nil);

    return shouldExportAttribute;
}

- (NSString *)customTransformerName {
    NSString *keyName = self.userInfo[PropertyMapperCustomValueTransformerKey];
    if (keyName == nil) {
        keyName = self.userInfo[PropertyMapperCompatibilityCustomValueTransformerKey];
    }

    return keyName;
}

@end
