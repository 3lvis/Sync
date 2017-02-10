@import CoreData;
@import XCTest;

#import "SYNCPropertyMapper.h"
#import "OrderedUser+CoreDataClass.h"
#import "OrderedNote+CoreDataClass.h"
#import "Company+CoreDataClass.h"
#import "Market+CoreDataClass.h"
#import "Attribute+CoreDataClass.h"
#import "Apartment+CoreDataClass.h"
#import "Building+CoreDataClass.h"
#import "Room+CoreDataClass.h"
#import "Park+CoreDataClass.h"
#import "Recursive+CoreDataClass.h"
#import "User+CoreDataClass.h"
#import "Note+CoreDataClass.h"
#import "KeyPath+CoreDataClass.h"
#import "HYPTestValueTransformer.h"

@import DATAStack;

@interface HYPFillWithDictionaryTests : XCTestCase

@property (nonatomic) NSDate *testDate;

@end

@implementation HYPFillWithDictionaryTests

- (NSDate *)testDate {
    if (!_testDate) {
        _testDate = [NSDate date];
    }

    return _testDate;
}

#pragma mark - Set up

- (DATAStack *)dataStack {
    return [[DATAStack alloc] initWithModelName:@"Model"
                                         bundle:[NSBundle bundleForClass:[self class]]
                                      storeType:DATAStackStoreTypeInMemory];
}

- (id)entityNamed:(NSString *)entityName inContext:(NSManagedObjectContext *)context {
    return [NSEntityDescription insertNewObjectForEntityForName:entityName
                                         inManagedObjectContext:context];
}

- (User *)userUsingDataStack:(DATAStack *)dataStack {
    User *user = [self entityNamed:@"User" inContext:dataStack.mainContext];
    user.age = @25;
    user.birthDate = self.testDate;
    user.contractID = @235;
    user.driverIdentifier = @"ABC8283";
    user.firstName = @"John";
    user.lastName = @"Hyperseed";
    user.userDescription = @"John Description";
    user.remoteID = @111;
    user.userType = @"Manager";
    user.createdAt = self.testDate;
    user.updatedAt = self.testDate;
    user.numberOfAttendes = @30;
    user.hobbies = [NSKeyedArchiver archivedDataWithRootObject:@[@"Football",
                                                                 @"Soccer",
                                                                 @"Code",
                                                                 @"More code"]];
    user.expenses = [NSKeyedArchiver archivedDataWithRootObject:@{@"cake" : @12.50,
                                                                  @"juice" : @0.50}];

    Note *note = [self noteWithID:@1 inContext:dataStack.mainContext];
    note.user = user;

    note = [self noteWithID:@14 inContext:dataStack.mainContext];
    note.user = user;
    note.destroy = @YES;

    note = [self noteWithID:@7 inContext:dataStack.mainContext];
    note.user = user;

    Company *company = [self companyWithID:@1 andName:@"Facebook" inContext:dataStack.mainContext];
    company.user = user;

    return user;
}

- (Note *)noteWithID:(NSNumber *)remoteID
           inContext:(NSManagedObjectContext *)context {
    Note *note = [self entityNamed:@"Note" inContext:context];
    note.remoteID = remoteID;
    note.text = [NSString stringWithFormat:@"This is the text for the note %@", remoteID];

    return note;
}

- (Company *)companyWithID:(NSNumber *)remoteID
                   andName:(NSString *)name
                 inContext:(NSManagedObjectContext *)context {
    Company *company = [self entityNamed:@"Company" inContext:context];
    company.remoteID = remoteID;
    company.name = name;

    return company;
}

#pragma mark - hyp_fillWithDictionary

- (void)testAllAttributes {
    NSDictionary *values = @{@"integer_string" : @"16",
                             @"integer16" : @16,
                             @"integer32" : @32,
                             @"integer64" : @64,
                             @"decimal_string" : @"12.2",
                             @"decimal" : @12.2,
                             @"double_value_string": @"12.2",
                             @"double_value": @12.2,
                             @"float_value_string" : @"12.2",
                             @"float_value" : @12.2,
                             @"string" : @"string",
                             @"boolean" : @YES,
                             @"binary_data" : @"Data",
                             @"transformable" : @"Ignore me, too",
                             @"custom_transformer_string" : @"Foo &amp; bar"};
    
    [NSValueTransformer setValueTransformer:[[HYPTestValueTransformer alloc] init] forName:@"HYPTestValueTransformer"];
    
    DATAStack *dataStack = [self dataStack];
    Attribute *attributes = [self entityNamed:@"Attribute" inContext:dataStack.mainContext];
    [attributes hyp_fillWithDictionary:values];

    XCTAssertEqualObjects(attributes.integerString, @16);
    XCTAssertEqualObjects(attributes.integer16, @16);
    XCTAssertEqualObjects(attributes.integer32, @32);
    XCTAssertEqualObjects(attributes.integer64, @64);

    XCTAssertEqualObjects(attributes.decimalString, [NSDecimalNumber decimalNumberWithString:@"12.2"]);
    XCTAssertEqualObjects(NSStringFromClass([attributes.decimalString class]), NSStringFromClass([NSDecimalNumber class]));
    XCTAssertNotEqualObjects(NSStringFromClass([attributes.decimalString class]), NSStringFromClass([NSNumber class]));

    XCTAssertEqualObjects(attributes.decimal, [NSDecimalNumber decimalNumberWithString:@"12.2"]);
    XCTAssertEqualObjects(NSStringFromClass([attributes.decimal class]), NSStringFromClass([NSDecimalNumber class]));
    XCTAssertNotEqualObjects(NSStringFromClass([attributes.decimal class]), NSStringFromClass([NSNumber class]));

    XCTAssertEqualObjects(attributes.doubleValueString, @12.2);
    XCTAssertEqualObjects(attributes.doubleValue, @12.2);
    XCTAssertEqualWithAccuracy(attributes.floatValueString.longValue, [@12 longValue], 1.0);
    XCTAssertEqualWithAccuracy(attributes.floatValue.longValue, [@12 longValue], 1.0);
    XCTAssertEqualObjects(attributes.string, @"string");
    XCTAssertEqualObjects(attributes.boolean, @YES);
    XCTAssertEqualObjects(attributes.binaryData, [NSKeyedArchiver archivedDataWithRootObject:@"Data"]);
    XCTAssertNil(attributes.transformable);
    XCTAssertEqualObjects(attributes.customTransformerString, @"Foo & bar");
}

- (void)testAllAttributesInCamelCase {
    NSDictionary *values = @{@"integerString" : @"16",
                             @"integer16" : @16,
                             @"integer32" : @32,
                             @"integer64" : @64,
                             @"decimalString" : @"12.2",
                             @"decimal" : @12.2,
                             @"doubleValueString": @"12.2",
                             @"doubleValue": @12.2,
                             @"floatValueString" : @"12.2",
                             @"floatValue" : @12.2,
                             @"string" : @"string",
                             @"boolean" : @YES,
                             @"binaryData" : @"Data",
                             @"transformable" : @"Ignore me, too",
                             @"customTransformerString" : @"Foo &amp; bar"};
    
    [NSValueTransformer setValueTransformer:[[HYPTestValueTransformer alloc] init] forName:@"HYPTestValueTransformer"];
    
    DATAStack *dataStack = [self dataStack];
    Attribute *attributes = [self entityNamed:@"Attribute" inContext:dataStack.mainContext];
    [attributes hyp_fillWithDictionary:values];
    
    XCTAssertEqualObjects(attributes.integerString, @16);
    XCTAssertEqualObjects(attributes.integer16, @16);
    XCTAssertEqualObjects(attributes.integer32, @32);
    XCTAssertEqualObjects(attributes.integer64, @64);
    
    XCTAssertEqualObjects(attributes.decimalString, [NSDecimalNumber decimalNumberWithString:@"12.2"]);
    XCTAssertEqualObjects(NSStringFromClass([attributes.decimalString class]), NSStringFromClass([NSDecimalNumber class]));
    XCTAssertNotEqualObjects(NSStringFromClass([attributes.decimalString class]), NSStringFromClass([NSNumber class]));
    
    XCTAssertEqualObjects(attributes.decimal, [NSDecimalNumber decimalNumberWithString:@"12.2"]);
    XCTAssertEqualObjects(NSStringFromClass([attributes.decimal class]), NSStringFromClass([NSDecimalNumber class]));
    XCTAssertNotEqualObjects(NSStringFromClass([attributes.decimal class]), NSStringFromClass([NSNumber class]));
    
    XCTAssertEqualObjects(attributes.doubleValueString, @12.2);
    XCTAssertEqualObjects(attributes.doubleValue, @12.2);
    XCTAssertEqualWithAccuracy(attributes.floatValueString.longValue, [@12 longValue], 1.0);
    XCTAssertEqualWithAccuracy(attributes.floatValue.longValue, [@12 longValue], 1.0);
    XCTAssertEqualObjects(attributes.string, @"string");
    XCTAssertEqualObjects(attributes.boolean, @YES);
    XCTAssertEqualObjects(attributes.binaryData, [NSKeyedArchiver archivedDataWithRootObject:@"Data"]);
    XCTAssertNil(attributes.transformable);
    XCTAssertEqualObjects(attributes.customTransformerString, @"Foo & bar");
}

- (void)testFillManagedObjectWithDictionary {
    NSDictionary *values = @{@"first_name" : @"Jane",
                             @"last_name"  : @"Hyperseed"};

    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    XCTAssertEqualObjects([user valueForKey:@"firstName"], values[@"first_name"]);
}

- (void)testUpdatingExistingValueWithNull {
    NSDictionary *values = @{@"first_name" : @"Jane",
                             @"last_name"  : @"Hyperseed"};

    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    NSDictionary *updatedValues = @{@"first_name" : [NSNull new],
                                    @"last_name"  : @"Hyperseed"};

    [user hyp_fillWithDictionary:updatedValues];

    XCTAssertNil([user valueForKey:@"firstName"]);
}

- (void)testAgeNumber {
    NSDictionary *values = @{@"age" : @24};

    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    XCTAssertEqualObjects([user valueForKey:@"age"], values[@"age"]);
}

- (void)testAgeString {
    NSDictionary *values = @{@"age" : @"24"};

    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    NSNumberFormatter *formatter = [NSNumberFormatter new];
    NSNumber *age = [formatter numberFromString:values[@"age"]];

    XCTAssertEqualObjects([user valueForKey:@"age"], age);
}

- (void)testBornDate {
    NSDictionary *values = @{@"birth_date" : @"1989-02-14T00:00:00+00:00"};

    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.dateFormat = @"yyyy-MM-dd";
    dateFormat.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    NSDate *date = [dateFormat dateFromString:@"1989-02-14"];

    XCTAssertEqualObjects([user valueForKey:@"birthDate"], date);
}

- (void)testUpdate {
    NSDictionary *values = @{@"first_name" : @"Jane",
                             @"last_name"  : @"Hyperseed",
                             @"age" : @30};

    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    NSDictionary *updatedValues = @{@"first_name" : @"Jeanet"};

    [user hyp_fillWithDictionary:updatedValues];

    XCTAssertEqualObjects([user valueForKey:@"firstName"], updatedValues[@"first_name"]);

    XCTAssertEqualObjects([user valueForKey:@"lastName"], values[@"last_name"]);
}

- (void)testUpdateIgnoringEqualValues {
    NSDictionary *values = @{@"first_name" : @"Jane",
                             @"last_name"  : @"Hyperseed",
                             @"age" : @30};

    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    [user.managedObjectContext save:nil];

    NSDictionary *updatedValues = @{@"first_name" : @"Jane",
                                    @"last_name"  : @"Hyperseed",
                                    @"age" : @30};

    [user hyp_fillWithDictionary:updatedValues];

    XCTAssertFalse(user.hasChanges);
}

- (void)testAcronyms {
    NSDictionary *values = @{@"contract_id" : @100};

    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    XCTAssertEqualObjects([user valueForKey:@"contractID"], @100);
}

- (void)testArrayStorage {
    NSDictionary *values = @{@"hobbies" : @[@"football",
                                            @"soccer",
                                            @"code"]};

    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    XCTAssertEqualObjects([NSKeyedUnarchiver unarchiveObjectWithData:user.hobbies][0], @"football");

    XCTAssertEqualObjects([NSKeyedUnarchiver unarchiveObjectWithData:user.hobbies][1], @"soccer");

    XCTAssertEqualObjects([NSKeyedUnarchiver unarchiveObjectWithData:user.hobbies][2], @"code");
}

- (void)testDictionaryStorage {
    NSDictionary *values = @{@"expenses" : @{@"cake" : @12.50,
                                             @"juice" : @0.50}};

    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    XCTAssertEqualObjects([NSKeyedUnarchiver unarchiveObjectWithData:user.expenses][@"cake"], @12.50);

    XCTAssertEqualObjects([NSKeyedUnarchiver unarchiveObjectWithData:user.expenses][@"juice"], @0.50);
}

- (void)testReservedWords {
    NSDictionary *values = @{@"id": @100,
                             @"description": @"This is the description?",
                             @"type": @"user type"};
    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    XCTAssertEqualObjects([user valueForKey:@"remoteID"], @100);
    XCTAssertEqualObjects([user valueForKey:@"userDescription"], @"This is the description?");
    XCTAssertEqualObjects([user valueForKey:@"userType"], @"user type");
}

- (void)testCreatedAt {
    NSDictionary *values = @{@"created_at" : @"2014-01-01T00:00:00+00:00",
                             @"updated_at" : @"2014-01-02",
                             @"number_of_attendes": @20};

    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.dateFormat = @"yyyy-MM-dd";
    dateFormat.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    NSDate *createdAt = [dateFormat dateFromString:@"2014-01-01"];
    NSDate *updatedAt = [dateFormat dateFromString:@"2014-01-02"];

    XCTAssertEqualObjects([user valueForKey:@"createdAt"], createdAt);

    XCTAssertEqualObjects([user valueForKey:@"updatedAt"], updatedAt);

    XCTAssertEqualObjects([user valueForKey:@"numberOfAttendes"], @20);
}

- (void)testCustomRemoteKeys {
    NSDictionary *values = @{@"age_of_person" : @20,
                             @"driver_identifier_str" : @"123",
                             @"signed" : @"salesman"};

    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    XCTAssertEqualObjects(user.age, @20);
    XCTAssertEqualObjects(user.driverIdentifier, @"123");
    XCTAssertEqualObjects(user.rawSigned, @"salesman");
}

- (void)testIgnoredTransformables {
    NSDictionary *values = @{@"ignoreTransformable" : @"I'm going to be ignored"};

    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    XCTAssertNil(user.ignoreTransformable);
}

- (void)testRegisteredTransformables {
    NSDictionary *values = @{@"registeredTransformable" : @"/Date(1451606400000)/"};
   
    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.dateFormat = @"yyyy-MM-dd";
    dateFormat.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    NSDate *date = [dateFormat dateFromString:@"2016-01-01"];
    XCTAssertNotNil(user.registeredTransformable);
    XCTAssertEqualObjects(user.registeredTransformable, date);
    XCTAssertTrue([user.registeredTransformable isKindOfClass:[NSDate class]]);
}

- (void)testCustomKey {
    DATAStack *dataStack = [self dataStack];

    NSDictionary *values = @{@"id": @"1",
                             @"other_attribute": @"Market 1"};
    
    Market *market = [self entityNamed:@"Market" inContext:dataStack.mainContext];

    [market hyp_fillWithDictionary:values];

    XCTAssertEqualObjects(market.uniqueId, @"1");
    XCTAssertEqualObjects(market.otherAttribute, @"Market 1");
}

- (void)testCustomKeyPathSnakeCase {
    DATAStack *dataStack = [self dataStack];

    NSDictionary *values = @{@"snake_parent": @{
                                     @"value_one": @"Value 1",
                                     @"depth_one": @{
                                             @"depth_two": @"Value 2" }
                                     }
                             };

    KeyPath *keyPaths = [self entityNamed:@"KeyPath" inContext:dataStack.mainContext];

    [keyPaths hyp_fillWithDictionary:values];

    XCTAssertEqualObjects(keyPaths.snakeCaseDepthOne, @"Value 1");
    XCTAssertEqualObjects(keyPaths.snakeCaseDepthTwo, @"Value 2");
}

- (void)testCustomKeyPathCamelCase {
    DATAStack *dataStack = [self dataStack];

    NSDictionary *values = @{@"camelParent": @{
                                     @"valueOne": @"Value 1",
                                     @"depthOne": @{
                                             @"depthTwo": @"Value 2" }
                                     }
                             };

    KeyPath *keyPaths = [self entityNamed:@"KeyPath" inContext:dataStack.mainContext];

    [keyPaths hyp_fillWithDictionary:values];

    XCTAssertEqualObjects(keyPaths.camelCaseDepthOne, @"Value 1");
    XCTAssertEqualObjects(keyPaths.camelCaseDepthTwo, @"Value 2");
}

@end
