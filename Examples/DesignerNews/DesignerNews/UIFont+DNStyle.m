#import "UIFont+DNStyle.h"

@implementation UIFont (DNStyle)

+ (UIFont *)headerFont
{
    return [UIFont fontWithName:@"Avenir-Medium" size:16.0f];;
}

+ (UIFont *)subtitleFont
{
    return [UIFont fontWithName:@"Avenir-Medium" size:13.0f];
}

+ (UIFont *)asideFont
{
    return [UIFont fontWithName:@"Avenir-Light" size:11.0f];
}

@end
