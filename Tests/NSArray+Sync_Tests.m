@import XCTest;

#import "NSArray+Sync.h"
#import "BaseTestCase.h"

@interface NSArray_Sync_Tests : BaseTestCase

@end

@implementation NSArray_Sync_Tests

#pragma mark Bug 125 => https://github.com/hyperoslo/Sync/issues/125

/*- (void)testChangesPreprocessing {
    NSDictionary *formDictionary = [self objectsFromJSON:@"bug-125-light.json"];
    NSString *uri = formDictionary[@"uri"];

    DATAStack *dataStack = [self dataStackWithModelName:@"Bug125"];

    NSDictionary *preprocessed = [@[formDictionary] preprocessForEntityNamed:@"Form"
                                                              usingPredicate:[NSPredicate predicateWithFormat:@"uri == %@", uri]
                                                                      parent:nil
                                                                   dataStack:dataStack].firstObject;

    XCTAssertEqualObjects(preprocessed, formDictionary);
}*/

@end
