#import "NSObject+HYPTesting.h"

@implementation NSObject (HYPTesting)

+ (BOOL)isUnitTesting
{
    NSDictionary *environment = [NSProcessInfo processInfo].environment;
    NSString *serviceNameValue = environment[@"XPC_SERVICE_NAME"];
    NSString *injectBundleValue = environment[@"XCInjectBundle"];
    BOOL runningOnTravis = (environment[@"TRAVIS"] != nil);

    return ([serviceNameValue.pathExtension isEqualToString:@"xctest"] ||
            [serviceNameValue isEqualToString:@"0"] ||
            [injectBundleValue.pathExtension isEqualToString:@"xctest"] ||
            [injectBundleValue isEqualToString:@"0"] ||
            runningOnTravis);
}

@end
