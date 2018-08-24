#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "NSDate+PropertyMapper.h"
#import "Inflections.h"
#import "NSEntityDescription+PrimaryKey.h"
#import "NSManagedObject+PropertyMapperHelpers.h"
#import "PropertyMapper.h"
#import "Sync.h"
#import "NSPropertyDescription+Sync.h"

FOUNDATION_EXPORT double SyncVersionNumber;
FOUNDATION_EXPORT const unsigned char SyncVersionString[];

