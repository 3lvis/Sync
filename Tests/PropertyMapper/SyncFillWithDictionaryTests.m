@import CoreData;
@import XCTest;
@import Sync;

#import "PropertyMapper.h"
#import "SyncTestValueTransformer.h"

@interface NSKeyedUnarchiver (Sync)
+ (nullable id)unarchiveArrayFromData:(NSData *)data;
+ (nullable id)unarchiveDictionaryFromData:(NSData *)data;
@end

@implementation NSKeyedUnarchiver (Sync)
+ (nullable id)unarchiveArrayFromData:(NSData *)data {
    NSError *unarchivingError = nil;
    NSArray *array = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSArray class] fromData:data error:&unarchivingError];
    if (unarchivingError != nil) {
        NSLog(@"NSKeyedUnarchiver (Sync) unarchivingError %@", [unarchivingError localizedDescription]);
    }
    return array;
}

+ (nullable id)unarchiveDictionaryFromData:(NSData *)data {
    NSError *unarchivingError = nil;
    NSDictionary *dictionary = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSDictionary class] fromData:data error:&unarchivingError];
    if (unarchivingError != nil) {
        NSLog(@"NSKeyedUnarchiver (Sync) unarchivingError %@", [unarchivingError localizedDescription]);
    }
    return dictionary;
}
@end

@interface SyncFillWithDictionaryTests : XCTestCase

@property (nonatomic) NSDate *testDate;

@end

@implementation SyncFillWithDictionaryTests

- (NSDate *)testDate {
    if (!_testDate) {
        _testDate = [NSDate date];
    }

    return _testDate;
}

#pragma mark - Set up

- (DataStack *)dataStack {
    return [[DataStack alloc] initWithModelName:@"Model"
                                         bundle:[NSBundle bundleForClass:[self class]]
                                      storeType:DataStackStoreTypeInMemory];
}

- (id)entityNamed:(NSString *)entityName inContext:(NSManagedObjectContext *)context {
    return [NSEntityDescription insertNewObjectForEntityForName:entityName
                                         inManagedObjectContext:context];
}

- (NSManagedObject *)userUsingDataStack:(DataStack *)dataStack {
    NSManagedObject *user = [self entityNamed:@"User" inContext:dataStack.mainContext];
    [user setValue:@25 forKey:@"age"];
    [user setValue:self.testDate forKey:@"birthDate"];
    [user setValue:@235 forKey:@"contractID"];
    [user setValue:@"ABC8283" forKey:@"driverIdentifier"];
    [user setValue:@"John" forKey:@"firstName"];
    [user setValue:@"Sid" forKey:@"lastName"];
    [user setValue:@"John Description" forKey:@"userDescription"];
    [user setValue:@111 forKey:@"remoteID"];
    [user setValue:@"Manager" forKey:@"userType"];
    [user setValue:self.testDate forKey:@"createdAt"];
    [user setValue:self.testDate forKey:@"updatedAt"];
    [user setValue:@30 forKey:@"numberOfAttendes"];
    [user setValue:@"raw" forKey:@"rawSigned"];

    NSData *hobbies = [NSKeyedArchiver archivedDataWithRootObject:@[@"Football",
                                                                    @"Soccer",
                                                                    @"Code",
                                                                    @"More code"] requiringSecureCoding:false error:nil];
    [user setValue:hobbies forKey:@"hobbies"];

    NSData *expenses = [NSKeyedArchiver archivedDataWithRootObject:@{@"cake" : @12.50,
                                                                     @"juice" : @0.50} requiringSecureCoding:false error:nil];
    [user setValue:expenses forKey:@"expenses"];

    NSManagedObject *note = [self noteWithID:@1 inContext:dataStack.mainContext];
    [note setValue:user forKey:@"user"];

    note = [self noteWithID:@14 inContext:dataStack.mainContext];
    [note setValue:user forKey:@"user"];
    [note setValue:@YES forKey:@"destroy"];

    note = [self noteWithID:@7 inContext:dataStack.mainContext];
    [note setValue:user forKey:@"user"];

    NSManagedObject *company = [self companyWithID:@1 andName:@"Facebook" inContext:dataStack.mainContext];
    [company setValue:user forKey:@"user"];
    
    return user;
}

- (NSManagedObject *)noteWithID:(NSNumber *)remoteID
                      inContext:(NSManagedObjectContext *)context {
    NSManagedObject *note = [self entityNamed:@"Note" inContext:context];
    [note setValue:remoteID forKey:@"remoteID"];
    [note setValue:[NSString stringWithFormat:@"This is the text for the note %@", remoteID] forKey:@"text"];

    return note;
}

- (NSManagedObject *)companyWithID:(NSNumber *)remoteID
                           andName:(NSString *)name
                         inContext:(NSManagedObjectContext *)context {
    NSManagedObject *company = [self entityNamed:@"Company" inContext:context];
    [company setValue:remoteID forKey:@"remoteID"];
    [company setValue:name forKey:@"name"];
    
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
                             @"custom_transformer_string" : @"Foo &amp; bar",
                             @"uuid": @"E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
                             @"uri": @"https://www.apple.com/"
                             };
    
    [NSValueTransformer setValueTransformer:[[SyncTestValueTransformer alloc] init] forName:@"SyncTestValueTransformer"];
    
    DataStack *dataStack = [self dataStack];
    NSManagedObject *attributes = [self entityNamed:@"Attribute" inContext:dataStack.mainContext];
    [attributes hyp_fillWithDictionary:values];

    XCTAssertEqualObjects([attributes valueForKey:@"integerString"], @16);
    XCTAssertEqualObjects([attributes valueForKey:@"integer16"], @16);
    XCTAssertEqualObjects([attributes valueForKey:@"integer32"], @32);
    XCTAssertEqualObjects([attributes valueForKey:@"integer64"], @64);

    XCTAssertEqualObjects([attributes valueForKey:@"decimalString"], [NSDecimalNumber decimalNumberWithString:@"12.2"]);
    XCTAssertEqualObjects(NSStringFromClass([[attributes valueForKey:@"decimalString"] class]), NSStringFromClass([NSDecimalNumber class]));
    XCTAssertNotEqualObjects(NSStringFromClass([[attributes valueForKey:@"decimalString"] class]), NSStringFromClass([NSNumber class]));

    XCTAssertEqualObjects([attributes valueForKey:@"decimal"], [NSDecimalNumber decimalNumberWithString:@"12.2"]);
    XCTAssertEqualObjects(NSStringFromClass([[attributes valueForKey:@"decimal"] class]), NSStringFromClass([NSDecimalNumber class]));
    XCTAssertNotEqualObjects(NSStringFromClass([[attributes valueForKey:@"decimal"] class]), NSStringFromClass([NSNumber class]));

    XCTAssertEqualObjects([attributes valueForKey:@"doubleValueString"], @12.2);
    XCTAssertEqualObjects([attributes valueForKey:@"doubleValue"], @12.2);
    XCTAssertEqualWithAccuracy([[attributes valueForKey:@"floatValueString"] longValue], [@12 longValue], 1.0);
    XCTAssertEqualWithAccuracy([[attributes valueForKey:@"floatValue"] longValue], [@12 longValue], 1.0);
    XCTAssertEqualObjects([attributes valueForKey:@"string"], @"string");
    XCTAssertEqualObjects([attributes valueForKey:@"boolean"], @YES);
    XCTAssertEqualObjects([attributes valueForKey:@"binaryData"], [NSKeyedArchiver archivedDataWithRootObject:@"Data" requiringSecureCoding:false error:nil]);
    XCTAssertNil([attributes valueForKey:@"transformable"]);
    XCTAssertEqualObjects([attributes valueForKey:@"customTransformerString"], @"Foo & bar");
    XCTAssertEqualObjects([attributes valueForKey:@"uuid"], [[NSUUID alloc] initWithUUIDString:@"E621E1F8-C36C-495A-93FC-0C247A3E6E5F"]);
    XCTAssertEqualObjects([attributes valueForKey:@"uri"], [[NSURL alloc] initWithString:@"https://www.apple.com/"]);
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
                             @"customTransformerString" : @"Foo &amp; bar",
                             @"uuid": @"E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
                             @"uri": @"https://www.apple.com/"
                             };
    
    [NSValueTransformer setValueTransformer:[[SyncTestValueTransformer alloc] init] forName:@"SyncTestValueTransformer"];
    
    DataStack *dataStack = [self dataStack];
    NSManagedObject *attributes = [self entityNamed:@"Attribute" inContext:dataStack.mainContext];
    [attributes hyp_fillWithDictionary:values];
    
    XCTAssertEqualObjects([attributes valueForKey:@"integerString"], @16);
    XCTAssertEqualObjects([attributes valueForKey:@"integer16"], @16);
    XCTAssertEqualObjects([attributes valueForKey:@"integer32"], @32);
    XCTAssertEqualObjects([attributes valueForKey:@"integer64"], @64);

    XCTAssertEqualObjects([attributes valueForKey:@"decimalString"], [NSDecimalNumber decimalNumberWithString:@"12.2"]);
    XCTAssertEqualObjects(NSStringFromClass([[attributes valueForKey:@"decimalString"] class]), NSStringFromClass([NSDecimalNumber class]));
    XCTAssertNotEqualObjects(NSStringFromClass([[attributes valueForKey:@"decimalString"] class]), NSStringFromClass([NSNumber class]));

    XCTAssertEqualObjects([attributes valueForKey:@"decimal"], [NSDecimalNumber decimalNumberWithString:@"12.2"]);
    XCTAssertEqualObjects(NSStringFromClass([[attributes valueForKey:@"decimal"] class]), NSStringFromClass([NSDecimalNumber class]));
    XCTAssertNotEqualObjects(NSStringFromClass([[attributes valueForKey:@"decimal"] class]), NSStringFromClass([NSNumber class]));

    XCTAssertEqualObjects([attributes valueForKey:@"doubleValueString"], @12.2);
    XCTAssertEqualObjects([attributes valueForKey:@"doubleValue"], @12.2);
    XCTAssertEqualWithAccuracy([[attributes valueForKey:@"floatValueString"] longValue], [@12 longValue], 1.0);
    XCTAssertEqualWithAccuracy([[attributes valueForKey:@"floatValue"] longValue], [@12 longValue], 1.0);
    XCTAssertEqualObjects([attributes valueForKey:@"string"], @"string");
    XCTAssertEqualObjects([attributes valueForKey:@"boolean"], @YES);
    XCTAssertEqualObjects([attributes valueForKey:@"binaryData"], [NSKeyedArchiver archivedDataWithRootObject:@"Data" requiringSecureCoding:false error:nil]);    
    XCTAssertNil([attributes valueForKey:@"transformable"]);
    XCTAssertEqualObjects([attributes valueForKey:@"customTransformerString"], @"Foo & bar");
    XCTAssertEqualObjects([attributes valueForKey:@"uuid"], [[NSUUID alloc] initWithUUIDString:@"E621E1F8-C36C-495A-93FC-0C247A3E6E5F"]);
    XCTAssertEqualObjects([attributes valueForKey:@"uri"], [[NSURL alloc] initWithString:@"https://www.apple.com/"]);
}

- (void)testFillManagedObjectWithDictionary {
    NSDictionary *values = @{@"first_name" : @"Jane",
                             @"last_name"  : @"Sid"};

    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    XCTAssertEqualObjects([user valueForKey:@"firstName"], values[@"first_name"]);
}

- (void)testUpdatingExistingValueWithNull {
    NSDictionary *values = @{@"first_name" : @"Jane",
                             @"last_name"  : @"Sid"};

    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    NSDictionary *updatedValues = @{@"first_name" : [NSNull new],
                                    @"last_name"  : @"Sid"};

    [user hyp_fillWithDictionary:updatedValues];

    XCTAssertNil([user valueForKey:@"firstName"]);
}

- (void)testAgeNumber {
    NSDictionary *values = @{@"age" : @24};

    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    XCTAssertEqualObjects([user valueForKey:@"age"], values[@"age"]);
}

- (void)testAgeString {
    NSDictionary *values = @{@"age" : @"24"};

    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    NSNumberFormatter *formatter = [NSNumberFormatter new];
    NSNumber *age = [formatter numberFromString:values[@"age"]];

    XCTAssertEqualObjects([user valueForKey:@"age"], age);
}

- (void)testBornDate {
    NSDictionary *values = @{@"birth_date" : @"1989-02-14T00:00:00+00:00"};

    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.dateFormat = @"yyyy-MM-dd";
    dateFormat.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    NSDate *date = [dateFormat dateFromString:@"1989-02-14"];

    XCTAssertEqualObjects([user valueForKey:@"birthDate"], date);
}

- (void)testUpdate {
    NSDictionary *values = @{@"first_name" : @"Jane",
                             @"last_name"  : @"Sid",
                             @"age" : @30};

    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    NSDictionary *updatedValues = @{@"first_name" : @"Jeanet"};

    [user hyp_fillWithDictionary:updatedValues];

    XCTAssertEqualObjects([user valueForKey:@"firstName"], updatedValues[@"first_name"]);

    XCTAssertEqualObjects([user valueForKey:@"lastName"], values[@"last_name"]);
}

- (void)testUpdateIgnoringEqualValues {
    NSDictionary *values = @{@"first_name" : @"Jane",
                             @"last_name"  : @"Sid",
                             @"age" : @30};

    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    [user.managedObjectContext save:nil];

    NSDictionary *updatedValues = @{@"first_name" : @"Jane",
                                    @"last_name"  : @"Sid",
                                    @"age" : @30};

    [user hyp_fillWithDictionary:updatedValues];

    XCTAssertFalse(user.hasChanges);
}

- (void)testAcronyms {
    NSDictionary *values = @{@"contract_id" : @100};

    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    XCTAssertEqualObjects([user valueForKey:@"contractID"], @100);
}

- (void)testArrayStorage {
    NSDictionary *values = @{@"hobbies" : @[@"football",
                                            @"soccer",
                                            @"code"]};

    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];
    
    XCTAssertEqualObjects([NSKeyedUnarchiver unarchiveArrayFromData:[user valueForKey:@"hobbies"]][0], @"football");
    XCTAssertEqualObjects([NSKeyedUnarchiver unarchiveArrayFromData:[user valueForKey:@"hobbies"]][1], @"soccer");
    XCTAssertEqualObjects([NSKeyedUnarchiver unarchiveArrayFromData:[user valueForKey:@"hobbies"]][2], @"code");
}

- (void)testDictionaryStorage {
    NSDictionary *values = @{@"expenses" : @{@"cake" : @12.50,
                                             @"juice" : @0.50}};

    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    XCTAssertEqualObjects([NSKeyedUnarchiver unarchiveDictionaryFromData:[user valueForKey:@"expenses"]][@"cake"], @12.50);
    XCTAssertEqualObjects([NSKeyedUnarchiver unarchiveDictionaryFromData:[user valueForKey:@"expenses"]][@"juice"], @0.50);
}

- (void)testReservedWords {
    NSDictionary *values = @{@"id": @100,
                             @"description": @"This is the description?",
                             @"type": @"user type"};
    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    XCTAssertEqualObjects([user valueForKey:@"remoteID"], @100);
    XCTAssertEqualObjects([user valueForKey:@"userDescription"], @"This is the description?");
    XCTAssertEqualObjects([user valueForKey:@"userType"], @"user type");
}

- (void)testCreatedAt {
    NSDictionary *values = @{@"created_at" : @"2014-01-01T00:00:00+00:00",
                             @"updated_at" : @"2014-01-02",
                             @"number_of_attendes": @20};

    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
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

    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    XCTAssertEqualObjects([user valueForKey:@"age"], @20);
    XCTAssertEqualObjects([user valueForKey:@"driverIdentifier"], @"123");
    XCTAssertEqualObjects([user valueForKey:@"rawSigned"], @"salesman");
}

- (void)testIgnoredTransformables {
    NSDictionary *values = @{@"ignoreTransformable" : @"I'm going to be ignored"};

    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    XCTAssertNil([user valueForKey:@"ignoreTransformable"]);
}

- (void)testRegisteredTransformables {
    NSDictionary *values = @{@"registeredTransformable" : @"/Date(1451606400000)/"};
   
    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
    [user hyp_fillWithDictionary:values];

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.dateFormat = @"yyyy-MM-dd";
    dateFormat.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    NSDate *date = [dateFormat dateFromString:@"2016-01-01"];
    XCTAssertNotNil([user valueForKey:@"registeredTransformable"]);
    XCTAssertEqualObjects([user valueForKey:@"registeredTransformable"], date);
    XCTAssertTrue([[user valueForKey:@"registeredTransformable"] isKindOfClass:[NSDate class]]);
}

- (void)testCustomKey {
    DataStack *dataStack = [self dataStack];

    NSDictionary *values = @{@"id": @"1",
                             @"other_attribute": @"Market 1"};
    
    NSManagedObject *market = [self entityNamed:@"Market" inContext:dataStack.mainContext];

    [market hyp_fillWithDictionary:values];

    XCTAssertEqualObjects([market valueForKey:@"uniqueId"], @"1");
    XCTAssertEqualObjects([market valueForKey:@"otherAttribute"], @"Market 1");
}

- (void)testCustomKeyPathSnakeCase {
    DataStack *dataStack = [self dataStack];

    NSDictionary *values = @{@"snake_parent": @{
                                     @"value_one": @"Value 1",
                                     @"depth_one": @{
                                             @"depth_two": @"Value 2" }
                                     }
                             };

    NSManagedObject *keyPaths = [self entityNamed:@"KeyPath" inContext:dataStack.mainContext];

    [keyPaths hyp_fillWithDictionary:values];

    XCTAssertEqualObjects([keyPaths valueForKey:@"snakeCaseDepthOne"], @"Value 1");
    XCTAssertEqualObjects([keyPaths valueForKey:@"snakeCaseDepthTwo"], @"Value 2");
}

- (void)testCustomKeyPathCamelCase {
    DataStack *dataStack = [self dataStack];

    NSDictionary *values = @{@"camelParent": @{
                                     @"valueOne": @"Value 1",
                                     @"depthOne": @{
                                             @"depthTwo": @"Value 2" }
                                     }
                             };

    NSManagedObject *keyPaths = [self entityNamed:@"KeyPath" inContext:dataStack.mainContext];

    [keyPaths hyp_fillWithDictionary:values];

    XCTAssertEqualObjects([keyPaths valueForKey:@"camelCaseDepthOne"], @"Value 1");
    XCTAssertEqualObjects([keyPaths valueForKey:@"camelCaseDepthTwo"], @"Value 2");
}

@end
