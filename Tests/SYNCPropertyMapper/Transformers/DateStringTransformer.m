#import "DateStringTransformer.h"

@implementation DateStringTransformer

+ (Class) transformedValueClass {
    return [NSDate class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (nullable id)transformedValue:(nullable id)value {
    if ([value isKindOfClass:[NSString class]]) {
        // in this example string should be of "/Date(1460537233000)/" format
        NSString *intStr = [[(NSString*)value stringByReplacingOccurrencesOfString:@"/Date(" withString:@""] stringByReplacingOccurrencesOfString:@")/" withString:@""];
        NSInteger timestampMS = [intStr integerValue];
        float timestamp = timestampMS / 1000.0;
        NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:timestamp];
        return date;
    } else {
        return value;
    }
}

@end
