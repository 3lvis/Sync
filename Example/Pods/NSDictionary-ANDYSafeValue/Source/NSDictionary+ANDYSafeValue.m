#import "NSDictionary+ANDYSafeValue.h"

@implementation NSDictionary (ANDYSafeValue)

- (id)andy_valueForKey:(id)key
{
    if (!key) return nil;

    id value = nil;

    @try {
        value = [self valueForKeyPath:key];
    }
    @catch (NSException *exception) {
        if (exception) return nil;
    }

    if (!value) return nil;

    if (value != [NSNull null] && [value isKindOfClass:[NSString class]] && [value length] == 0) return nil;

    if (value == [NSNull null]) return nil;

    return value;
}

- (void)andy_setValue:(id)value forKey:(id)key
{
    if (value && key && value != [NSNull null]) [self setValue:value forKey:key];
}

@end
