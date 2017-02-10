@import CoreData;
@import XCTest;

#import "NSManagedObject+SYNCPropertyMapperHelpers.h"
#import "Company+CoreDataClass.h"
#import "Market+CoreDataClass.h"
#import "User+CoreDataClass.h"
#import "Note+CoreDataClass.h"
#import "KeyPath+CoreDataClass.h"

@import DATAStack;

@interface PrivateTests : XCTestCase

@end

@implementation PrivateTests

- (id)entityNamed:(NSString *)entityName {
    return [NSEntityDescription insertNewObjectForEntityForName:entityName
                                         inManagedObjectContext:self.managedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext {
    DATAStack *dataStack = [[DATAStack alloc] initWithModelName:@"Model"
                                                         bundle:[NSBundle bundleForClass:[self class]]
                                                      storeType:DATAStackStoreTypeInMemory];
    return dataStack.mainContext;
}

- (void)testAttributeDescriptionForKeyA {
    Company *company = [self entityNamed:@"Company"];
    NSAttributeDescription *attributeDescription;

    attributeDescription = [company attributeDescriptionForRemoteKey:@"name"];
    XCTAssertEqualObjects(attributeDescription.name, @"name");

    attributeDescription = [company attributeDescriptionForRemoteKey:@"id"];
    XCTAssertEqualObjects(attributeDescription.name, @"remoteID");
}

- (void)testAttributeDescriptionForKeyB {
    Market *market = [self entityNamed:@"Market"];
    NSAttributeDescription *attributeDescription;

    attributeDescription = [market attributeDescriptionForRemoteKey:@"id"];
    XCTAssertEqualObjects(attributeDescription.name, @"uniqueId");

    attributeDescription = [market attributeDescriptionForRemoteKey:@"other_attribute"];
    XCTAssertEqualObjects(attributeDescription.name, @"otherAttribute");
}

- (void)testAttributeDescriptionForKeyC {
    User *user = [self entityNamed:@"User"];
    NSAttributeDescription *attributeDescription;

    attributeDescription = [user attributeDescriptionForRemoteKey:@"age_of_person"];
    XCTAssertEqualObjects(attributeDescription.name, @"age");

    attributeDescription = [user attributeDescriptionForRemoteKey:@"driver_identifier_str"];
    XCTAssertEqualObjects(attributeDescription.name, @"driverIdentifier");

    attributeDescription = [user attributeDescriptionForRemoteKey:@"not_found_key"];
    XCTAssertNil(attributeDescription);
}

- (void)testAttributeDescriptionForKeyD {
    KeyPath *keyPath = [self entityNamed:@"KeyPath"];
    NSAttributeDescription *attributeDescription;

    attributeDescription = [keyPath attributeDescriptionForRemoteKey:@"snake_parent.value_one"];
    XCTAssertEqualObjects(attributeDescription.name, @"snakeCaseDepthOne");

    attributeDescription = [keyPath attributeDescriptionForRemoteKey:@"snake_parent.depth_one.depth_two"];
    XCTAssertEqualObjects(attributeDescription.name, @"snakeCaseDepthTwo");

    attributeDescription = [keyPath attributeDescriptionForRemoteKey:@"camelParent.valueOne"];
    XCTAssertEqualObjects(attributeDescription.name, @"camelCaseDepthOne");

    attributeDescription = [keyPath attributeDescriptionForRemoteKey:@"camelParent.depthOne.depthTwo"];
    XCTAssertEqualObjects(attributeDescription.name, @"camelCaseDepthTwo");
}

- (void)testRemoteKeyForAttributeDescriptionA {
    Company *company = [self entityNamed:@"Company"];
    NSAttributeDescription *attributeDescription;

    attributeDescription = company.entity.propertiesByName[@"name"];
    XCTAssertEqualObjects([company remoteKeyForAttributeDescription:attributeDescription], @"name");

    attributeDescription = company.entity.propertiesByName[@"remoteID"];
    XCTAssertEqualObjects([company remoteKeyForAttributeDescription:attributeDescription], @"id");
}

- (void)testRemoteKeyForAttributeDescriptionB {
    Market *market = [self entityNamed:@"Market"];
    NSAttributeDescription *attributeDescription;

    attributeDescription = market.entity.propertiesByName[@"uniqueId"];
    XCTAssertEqualObjects([market remoteKeyForAttributeDescription:attributeDescription], @"id");

    attributeDescription = market.entity.propertiesByName[@"otherAttribute"];
    XCTAssertEqualObjects([market remoteKeyForAttributeDescription:attributeDescription], @"other_attribute");
}

- (void)testRemoteKeyForAttributeDescriptionC {
    User *user = [self entityNamed:@"User"];
    NSAttributeDescription *attributeDescription;

    attributeDescription = user.entity.propertiesByName[@"age"];    ;
    XCTAssertEqualObjects([user remoteKeyForAttributeDescription:attributeDescription], @"age_of_person");

    attributeDescription = user.entity.propertiesByName[@"driverIdentifier"];
    XCTAssertEqualObjects([user remoteKeyForAttributeDescription:attributeDescription], @"driver_identifier_str");

    XCTAssertNil([user remoteKeyForAttributeDescription:nil]);
}

- (void)testRemoteKeyForAttributeDescriptionD {
    KeyPath *keyPath = [self entityNamed:@"KeyPath"];
    NSAttributeDescription *attributeDescription;

    attributeDescription = keyPath.entity.propertiesByName[@"snakeCaseDepthOne"];
    XCTAssertEqualObjects([keyPath remoteKeyForAttributeDescription:attributeDescription], @"snake_parent.value_one");

    attributeDescription = keyPath.entity.propertiesByName[@"snakeCaseDepthTwo"];
    XCTAssertEqualObjects([keyPath remoteKeyForAttributeDescription:attributeDescription], @"snake_parent.depth_one.depth_two");

    attributeDescription = keyPath.entity.propertiesByName[@"camelCaseDepthOne"];
    XCTAssertEqualObjects([keyPath remoteKeyForAttributeDescription:attributeDescription], @"camelParent.valueOne");

    attributeDescription = keyPath.entity.propertiesByName[@"camelCaseDepthTwo"];
    XCTAssertEqualObjects([keyPath remoteKeyForAttributeDescription:attributeDescription], @"camelParent.depthOne.depthTwo");
}

- (void)testDestroyKey {
    Note *note = [self entityNamed:@"Note"];
    NSAttributeDescription *attributeDescription;

    attributeDescription = note.entity.propertiesByName[@"destroy"];    ;
    XCTAssertEqualObjects([note remoteKeyForAttributeDescription:attributeDescription], @"_destroy");

    attributeDescription = note.entity.propertiesByName[@"destroy"];
    XCTAssertEqualObjects([note remoteKeyForAttributeDescription:attributeDescription usingRelationshipType:SYNCPropertyMapperRelationshipTypeArray], @"destroy");
}

@end
