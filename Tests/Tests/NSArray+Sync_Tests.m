@import XCTest;

#import "NSArray+Sync.h"
#import "BaseTestCase.h"

@interface NSArray_Sync_Tests : BaseTestCase

@end

@implementation NSArray_Sync_Tests

#pragma mark Bug 125 => https://github.com/hyperoslo/Sync/issues/125

- (void)testNilRelationshipsAfterUpdating_Sync_1_0_10 {
    NSDictionary *formDictionary = [self objectsFromJSON:@"bug-125.json"];
    NSString *uri = formDictionary[@"uri"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Bug125"];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Form"
                                              inManagedObjectContext:dataStack.mainContext];

    NSDictionary *preprocessed = [@[formDictionary]preprocessForEntity:entity
                                                        usingPredicate:[NSPredicate predicateWithFormat:@"uri == %@", uri]
                                                             dataStack:dataStack].firstObject;
    XCTAssertEqualObjects(preprocessed, @{@"" : @""});
}

@end
