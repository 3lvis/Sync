@import Foundation;

@interface NSDictionary (ANDYSafeValue)

- (id)andy_valueForKey:(id)key;

- (void)andy_setValue:(id)value forKey:(id)key;

@end
