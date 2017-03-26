@import Foundation;
@import CoreData;

FOUNDATION_EXPORT double SyncVersionNumber;

FOUNDATION_EXPORT const unsigned char SyncVersionString[];

#import "SyncPropertyMapper.h"
#import "NSEntityDescription+SyncPrimaryKey.h"
#import "NSManagedObject+SyncPropertyMapperHelpers.h"
#import "NSPropertyDescription+Sync.h"
