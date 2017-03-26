@import CoreData;
@import XCTest;
@import Sync;

#import "NSEntityDescription+PrimaryKey.h"

@interface PrimaryKeyTests : XCTestCase

@end

@implementation PrimaryKeyTests

- (NSEntityDescription *)entityForName:(NSString *)name {
    DataStack *dataStack = [[DataStack alloc] initWithModelName:@"PrimaryKey"
                                                         bundle:[NSBundle bundleForClass:[self class]]
                                                      storeType:DataStackStoreTypeInMemory];

    return  [NSEntityDescription entityForName:name
                        inManagedObjectContext:dataStack.mainContext];

}

- (void)testPrimaryKeyAttribute {
    NSEntityDescription *entity = [self entityForName:@"User"];

    NSAttributeDescription *attribute = [entity sync_primaryKeyAttribute];
    XCTAssertEqualObjects(attribute.attributeValueClassName, @"NSNumber");
    XCTAssertEqual(attribute.attributeType, NSInteger32AttributeType);

    entity = [self entityForName:@"SimpleID"];
    attribute = [entity sync_primaryKeyAttribute];
    XCTAssertEqualObjects(attribute.attributeValueClassName, @"NSString");
    XCTAssertEqual(attribute.attributeType, NSStringAttributeType);
    XCTAssertEqualObjects(attribute.name, @"id");

    entity = [self entityForName:@"Note"];
    attribute = [entity sync_primaryKeyAttribute];
    XCTAssertEqualObjects(attribute.attributeValueClassName, @"NSNumber");
    XCTAssertEqual(attribute.attributeType, NSInteger16AttributeType);
    XCTAssertEqualObjects(attribute.name, @"uniqueID");

    entity = [self entityForName:@"Tag"];
    attribute = [entity sync_primaryKeyAttribute];
    XCTAssertEqualObjects(attribute.attributeValueClassName, @"NSString");
    XCTAssertEqual(attribute.attributeType, NSStringAttributeType);
    XCTAssertEqualObjects(attribute.name, @"randomId");

    entity = [self entityForName:@"NoID"];
    attribute = [entity sync_primaryKeyAttribute];
    XCTAssertNil(attribute);

    entity = [self entityForName:@"AlternativeID"];
    attribute = [entity sync_primaryKeyAttribute];
    XCTAssertEqualObjects(attribute.attributeValueClassName, @"NSString");
    XCTAssertEqual(attribute.attributeType, NSStringAttributeType);
    XCTAssertEqualObjects(attribute.name, @"alternativeID");
}

- (void)testLocalPrimaryKey {
    NSEntityDescription *entity = [self entityForName:@"User"];
    XCTAssertEqualObjects([entity sync_localPrimaryKey], @"remoteID");

    entity = [self entityForName:@"SimpleID"];
    XCTAssertEqualObjects([entity sync_localPrimaryKey], @"id");

    entity = [self entityForName:@"Note"];
    XCTAssertEqualObjects([entity sync_localPrimaryKey], @"uniqueID");

    entity = [self entityForName:@"Tag"];
    XCTAssertEqualObjects([entity sync_localPrimaryKey], @"randomId");

    entity = [self entityForName:@"NoID"];
    XCTAssertNil([entity sync_localPrimaryKey]);

    entity = [self entityForName:@"AlternativeID"];
    XCTAssertEqualObjects([entity sync_localPrimaryKey], @"alternativeID");

    entity = [self entityForName:@"Compatibility"];
    XCTAssertEqualObjects([entity sync_localPrimaryKey], @"custom");
}

- (void)testRemotePrimaryKey {
    NSEntityDescription *entity = [self entityForName:@"User"];
    XCTAssertEqualObjects([entity sync_remotePrimaryKey], @"id");

    entity = [self entityForName:@"SimpleID"];
    XCTAssertEqualObjects([entity sync_remotePrimaryKey], @"id");

    entity = [self entityForName:@"Note"];
    XCTAssertEqualObjects([entity sync_remotePrimaryKey], @"unique_id");

    entity = [self entityForName:@"Tag"];
    XCTAssertEqualObjects([entity sync_remotePrimaryKey], @"id");

    entity = [self entityForName:@"NoID"];
    XCTAssertNil([entity sync_remotePrimaryKey]);

    entity = [self entityForName:@"AlternativeID"];
    XCTAssertEqualObjects([entity sync_remotePrimaryKey], @"alternative_id");

    entity = [self entityForName:@"Compatibility"];
    XCTAssertEqualObjects([entity sync_remotePrimaryKey], @"greeting");
}

@end
