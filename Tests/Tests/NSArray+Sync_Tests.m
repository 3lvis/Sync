@import XCTest;

#import "NSArray+Sync.h"
#import "BaseTestCase.h"

@interface NSArray_Sync_Tests : BaseTestCase

@end

@implementation NSArray_Sync_Tests

#pragma mark Bug 125 => https://github.com/hyperoslo/Sync/issues/125

- (void)testChangesPreprocessing {
    /*NSDictionary *formDictionary = [self objectsFromJSON:@"bug-125.json"];
    NSString *uri = formDictionary[@"uri"];

    DATAStack *dataStack = [self dataStackWithModelName:@"Bug125"];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Form"
                                              inManagedObjectContext:dataStack.disposableMainContext];

    NSDictionary *preprocessed = [@[formDictionary]preprocessForEntity:entity
                                                        usingPredicate:[NSPredicate predicateWithFormat:@"uri == %@", uri]
                                                                parent:nil
                                                             dataStack:dataStack].firstObject;


    NSDictionary *model = preprocessed[@"model"];

    NSArray *properties = model[@"properties"];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
    NSArray *sortedProperties = [properties sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
    NSMutableDictionary *mutableModel = [model mutableCopy];
    mutableModel[@"properties"] = sortedProperties;
    model = [mutableModel copy];

    NSMutableDictionary *mutableForm = [preprocessed mutableCopy];
    mutableForm[@"model"] = model;
    preprocessed = [mutableForm copy];

    XCTAssertEqualObjects(preprocessed, formDictionary);*/
}

@end
