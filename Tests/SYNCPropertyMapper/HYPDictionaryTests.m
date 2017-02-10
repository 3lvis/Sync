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
#import "HYPTestValueTransformer.h"

@import DATAStack;

@interface HYPDictionaryTests : XCTestCase

@property (nonatomic) NSDate *testDate;

@end

@implementation HYPDictionaryTests

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
    user.rawSigned = @"raw";
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

- (OrderedNote *)orderedNoteWithID:(NSNumber *)remoteID
           inContext:(NSManagedObjectContext *)context {
    OrderedNote *note = [self entityNamed:@"OrderedNote" inContext:context];
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

#pragma mark - hyp_dictionary

- (NSDictionary *)userDictionaryWithNoRelationships {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
    NSString *resultDateString = [formatter stringFromDate:self.testDate];

    NSMutableDictionary *comparedDictionary = [NSMutableDictionary new];
    comparedDictionary[@"age_of_person"] = @25;
    comparedDictionary[@"birth_date"] = resultDateString;
    comparedDictionary[@"contract_id"] = @235;
    comparedDictionary[@"created_at"] = resultDateString;
    comparedDictionary[@"description"] = @"John Description";
    comparedDictionary[@"driver_identifier_str"] = @"ABC8283";
    comparedDictionary[@"expenses"] = [NSKeyedArchiver archivedDataWithRootObject:@{@"cake" : @12.50,
                                                                                    @"juice" : @0.50}];
    comparedDictionary[@"first_name"] = @"John";
    comparedDictionary[@"hobbies"] = [NSKeyedArchiver archivedDataWithRootObject:@[@"Football",
                                                                                   @"Soccer",
                                                                                   @"Code",
                                                                                   @"More code"]];
    comparedDictionary[@"id"] = @111;
    comparedDictionary[@"ignored_parameter"] = [NSNull null];
    comparedDictionary[@"last_name"] = @"Hyperseed";
    comparedDictionary[@"number_of_attendes"] = @30;
    comparedDictionary[@"type"] = @"Manager";
    comparedDictionary[@"updated_at"] = resultDateString;
    comparedDictionary[@"signed"] = @"raw";

    return [comparedDictionary copy];
}

- (void)testDictionaryNoRelationships {
    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    NSDictionary *dictionary = [user hyp_dictionaryUsingRelationshipType:SYNCPropertyMapperRelationshipTypeNone];
    NSDictionary *comparedDictionary = [self userDictionaryWithNoRelationships];
    XCTAssertEqualObjects(dictionary, [comparedDictionary copy]);
}

- (void)testDictionaryArrayRelationships {
    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    NSDictionary *dictionary = [user hyp_dictionaryUsingRelationshipType:SYNCPropertyMapperRelationshipTypeArray];
    NSMutableDictionary *comparedDictionary = [[self userDictionaryWithNoRelationships] mutableCopy];
    comparedDictionary[@"company"] = @{@"id" : @1,
                                       @"name" : @"Facebook"};

    NSArray *notes = dictionary[@"notes"];
    NSSortDescriptor *nameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
    NSArray *sortedNotes = [notes sortedArrayUsingDescriptors:[NSArray arrayWithObject:nameDescriptor]];
    NSMutableDictionary *mutableDictionary = [dictionary mutableCopy];
    mutableDictionary[@"notes"] = sortedNotes;
    dictionary = [mutableDictionary copy];

    NSDictionary *note1 = @{@"destroy" : [NSNull null],
                            @"id" : @1,
                            @"text" : @"This is the text for the note 1"};
    NSDictionary *note2 = @{@"destroy" : [NSNull null],
                            @"id" : @7,
                            @"text" : @"This is the text for the note 7"};
    NSDictionary *note3 = @{@"destroy" : @1,
                            @"id" : @14,
                            @"text" : @"This is the text for the note 14"};
    comparedDictionary[@"notes"] = @[note1, note2, note3];

    XCTAssertEqualObjects(dictionary, [comparedDictionary copy]);
}

- (void)testDictionaryArrayRelationshipsOrdered {
    DATAStack *dataStack = [[DATAStack alloc] initWithModelName:@"Ordered"
                                                         bundle:[NSBundle bundleForClass:[self class]]
                                                      storeType:DATAStackStoreTypeInMemory];

    OrderedUser *user = [self entityNamed:@"OrderedUser" inContext:dataStack.mainContext];
    user.rawSigned = @"raw";
    user.age = @25;
    user.birthDate = self.testDate;
    user.contractID = @235;
    user.driverIdentifier = @"ABC8283";
    user.firstName = @"John";
    user.lastName = @"Hyperseed";
    user.orderedUserDescription = @"John Description";
    user.remoteID = @111;
    user.orderedUserType = @"Manager";
    user.createdAt = self.testDate;
    user.updatedAt = self.testDate;
    user.numberOfAttendes = @30;
    user.hobbies = [NSKeyedArchiver archivedDataWithRootObject:@[@"Football",
                                                                 @"Soccer",
                                                                 @"Code",
                                                                 @"More code"]];
    user.expenses = [NSKeyedArchiver archivedDataWithRootObject:@{@"cake" : @12.50,
                                                                  @"juice" : @0.50}];

    OrderedNote *note = [self orderedNoteWithID:@1 inContext:dataStack.mainContext];
    note.user = user;

    note = [self orderedNoteWithID:@14 inContext:dataStack.mainContext];
    note.user = user;
    note.destroy = @YES;

    note = [self orderedNoteWithID:@7 inContext:dataStack.mainContext];
    note.user = user;

    NSDictionary *dictionary = [user hyp_dictionaryUsingRelationshipType:SYNCPropertyMapperRelationshipTypeArray];
    NSMutableDictionary *comparedDictionary = [[self userDictionaryWithNoRelationships] mutableCopy];

    NSArray *notes = dictionary[@"notes"];
    NSSortDescriptor *nameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
    NSArray *sortedNotes = [notes sortedArrayUsingDescriptors:[NSArray arrayWithObject:nameDescriptor]];
    NSMutableDictionary *mutableDictionary = [dictionary mutableCopy];
    mutableDictionary[@"notes"] = sortedNotes;
    dictionary = [mutableDictionary copy];

    NSDictionary *note1 = @{@"destroy" : [NSNull null],
                            @"id" : @1,
                            @"text" : @"This is the text for the note 1"};
    NSDictionary *note2 = @{@"destroy" : [NSNull null],
                            @"id" : @7,
                            @"text" : @"This is the text for the note 7"};
    NSDictionary *note3 = @{@"destroy" : @1,
                            @"id" : @14,
                            @"text" : @"This is the text for the note 14"};
    comparedDictionary[@"notes"] = @[note1, note2, note3];

    XCTAssertEqualObjects(dictionary, [comparedDictionary copy]);

    NSString *description = (NSString *)dictionary[@"description"];
    XCTAssertEqualObjects(description, @"John Description");

    NSString *type = (NSString *)dictionary[@"type"];
    XCTAssertEqualObjects(type, @"Manager");
}

- (void)testDictionaryNestedRelationships {
    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    NSDictionary *dictionary = [user hyp_dictionary];
    NSMutableDictionary *comparedDictionary = [[self userDictionaryWithNoRelationships] mutableCopy];
    comparedDictionary[@"company_attributes"] = @{@"id" : @1,
                                                  @"name" : @"Facebook"};

    NSDictionary *notesDictionary = dictionary[@"notes_attributes"];
    NSArray *notes = notesDictionary.allValues;
    NSSortDescriptor *nameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
    NSArray *sortedNotes = [notes sortedArrayUsingDescriptors:[NSArray arrayWithObject:nameDescriptor]];
    NSMutableDictionary *mutableDictionary = [dictionary mutableCopy];
    mutableDictionary[@"notes_attributes"] = sortedNotes;
    dictionary = [mutableDictionary copy];

    NSDictionary *note1 = @{@"_destroy" : [NSNull null],
                            @"id" : @1,
                            @"text" : @"This is the text for the note 1"};
    NSDictionary *note2 = @{@"_destroy" : [NSNull null],
                            @"id" : @7,
                            @"text" : @"This is the text for the note 7"};
    NSDictionary *note3 = @{@"_destroy" : @1,
                            @"id" : @14,
                            @"text" : @"This is the text for the note 14"};
    comparedDictionary[@"notes_attributes"] = @[note1, note2, note3];

    XCTAssertEqualObjects(dictionary, comparedDictionary);
}

- (void)testDictionaryDeepRelationships {
    DATAStack *dataStack = [self dataStack];

    Building *building = [self entityNamed:@"Building" inContext:dataStack.mainContext];
    building.remoteID = @1;

    Park *park = [self entityNamed:@"Park" inContext:dataStack.mainContext];
    park.remoteID = @1;
    [building addParksObject:park];

    Apartment *apartment = [self entityNamed:@"Apartment" inContext:dataStack.mainContext];
    apartment.remoteID = @1;

    Room *room = [self entityNamed:@"Room" inContext:dataStack.mainContext];
    room.remoteID = @1;
    [apartment addRoomsObject:room];

    [building addApartmentsObject:apartment];

    NSDictionary *buildingDictionary = [building hyp_dictionaryUsingRelationshipType:SYNCPropertyMapperRelationshipTypeArray];
    NSMutableDictionary *compared = [NSMutableDictionary new];
    NSArray *rooms = @[@{@"id" : @1}];
    NSArray *apartments = @[@{@"id" : @1,
                              @"rooms" : rooms}];
    NSArray *parks = @[@{@"id" : @1}];
    compared[@"id"] = @1;
    compared[@"apartments"] = apartments;
    compared[@"parks"] = parks;

    XCTAssertEqualObjects(buildingDictionary, compared);
}

- (void)testDictionaryValuesKindOfClass {
    DATAStack *dataStack = [self dataStack];
    User *user = [self userUsingDataStack:dataStack];
    NSDictionary *dictionary = [user hyp_dictionary];

    XCTAssertTrue([dictionary[@"age_of_person"] isKindOfClass:[NSNumber class]]);

    XCTAssertTrue([dictionary[@"birth_date"] isKindOfClass:[NSString class]]);

    XCTAssertTrue([dictionary[@"contract_id"] isKindOfClass:[NSNumber class]]);

    XCTAssertTrue([dictionary[@"created_at"] isKindOfClass:[NSString class]]);

    XCTAssertTrue([dictionary[@"description"] isKindOfClass:[NSString class]]);

    XCTAssertTrue([dictionary[@"driver_identifier_str"] isKindOfClass:[NSString class]]);

    XCTAssertTrue([dictionary[@"expenses"] isKindOfClass:[NSData class]]);

    XCTAssertTrue([dictionary[@"first_name"] isKindOfClass:[NSString class]]);

    XCTAssertTrue([dictionary[@"hobbies"] isKindOfClass:[NSData class]]);

    XCTAssertTrue([dictionary[@"id"] isKindOfClass:[NSNumber class]]);

    XCTAssertNil(dictionary[@"ignore_transformable"]);

    XCTAssertTrue([dictionary[@"ignored_parameter"] isKindOfClass:[NSNull class]]);

    XCTAssertTrue([dictionary[@"last_name"] isKindOfClass:[NSString class]]);

    XCTAssertTrue([dictionary[@"notes_attributes"] isKindOfClass:[NSDictionary class]]);

    XCTAssertTrue([dictionary[@"number_of_attendes"] isKindOfClass:[NSNumber class]]);

    XCTAssertTrue([dictionary[@"type"] isKindOfClass:[NSString class]]);

    XCTAssertTrue([dictionary[@"updated_at"] isKindOfClass:[NSString class]]);
}

- (void)testRecursive {
    DATAStack *dataStack = [self dataStack];

    Recursive *megachild = [self entityNamed:@"Recursive" inContext:dataStack.mainContext];
    megachild.remoteID = @"megachild";

    Recursive *grandchild = [self entityNamed:@"Recursive" inContext:dataStack.mainContext];
    grandchild.remoteID = @"grandchild";
    [grandchild addRecursivesObject:megachild];
    megachild.recursive = grandchild;

    Recursive *child = [self entityNamed:@"Recursive" inContext:dataStack.mainContext];
    child.remoteID = @"child";
    [child addRecursivesObject:grandchild];
    grandchild.recursive = child;

    Recursive *parent = [self entityNamed:@"Recursive" inContext:dataStack.mainContext];
    parent.remoteID = @"Parent";
    [parent addRecursivesObject:child];
    child.recursive = parent;

    NSDictionary *dictionary = [parent hyp_dictionaryUsingRelationshipType:SYNCPropertyMapperRelationshipTypeArray];
    NSArray *megachildArray = @[@{@"id" : @"megachild", @"recursives": @[]}];
    NSArray *grandchildArray = @[@{@"id" : @"grandchild", @"recursives": megachildArray}];
    NSArray *childArray = @[@{@"id" : @"child", @"recursives": grandchildArray}];
    NSDictionary *parentDictionary = @{@"id" : @"Parent", @"recursives" : childArray};
    XCTAssertEqualObjects(dictionary, parentDictionary);
}

@end
