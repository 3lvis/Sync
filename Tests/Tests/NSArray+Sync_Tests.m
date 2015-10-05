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

    [Sync changes:@[formDictionary]
    inEntityNamed:@"Form"
        predicate:[NSPredicate predicateWithFormat:@"uri == %@", uri]
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([self countForEntity:@"Form"
                              inContext:dataStack.mainContext], 1);

    XCTAssertEqual([self countForEntity:@"Element"
                              inContext:dataStack.mainContext], 11);

    XCTAssertEqual([self countForEntity:@"SelectionItem"
                              inContext:dataStack.mainContext], 4);

    XCTAssertEqual([self countForEntity:@"Model"
                              inContext:dataStack.mainContext], 1);

    XCTAssertEqual([self countForEntity:@"ModelProperty"
                              inContext:dataStack.mainContext], 9);

    XCTAssertEqual([self countForEntity:@"Restriction"
                              inContext:dataStack.mainContext], 3);

    NSArray *array = [self fetchEntity:@"Form"
                             inContext:dataStack.mainContext];
    NSManagedObject *form = [array firstObject];
    NSManagedObject *element = [form valueForKey:@"element"];
    NSManagedObject *model = [form valueForKey:@"model"];
    XCTAssertNotNil(element);
    XCTAssertNotNil(model);
    
    [dataStack drop];
}

@end
