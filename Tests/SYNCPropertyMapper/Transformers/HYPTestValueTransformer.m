#import "HYPTestValueTransformer.h"

@implementation HYPTestValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if (value == nil) return nil;
    
    NSString *stringValue = nil;
    
    if ([value isKindOfClass:[NSString class]]) {
        stringValue = (NSString *)value;
    } else {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Value (%@) is not of type NSString.", [value class]];
    }
    
    return [stringValue stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
}

- (id)reverseTransformedValue:(id)value {
    if (value == nil) return nil;
    
    NSString *stringValue = nil;
    
    if ([value isKindOfClass:[NSString class]]) {
        stringValue = (NSString *)value;
    } else {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Value (%@) is not of type NSString.", [value class]];
    }
    
    return [stringValue stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
}

@end
