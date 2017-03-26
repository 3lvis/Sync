@import CoreData;
@import XCTest;
@import Sync;

#import "PropertyMapper.h"
#import "SyncTestValueTransformer.h"


@interface SyncDictionaryTests : XCTestCase

@property (nonatomic) NSDate *testDate;

@end

@implementation SyncDictionaryTests

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
                                                                    @"More code"]];
    [user setValue:hobbies forKey:@"hobbies"];

    NSData *expenses = [NSKeyedArchiver archivedDataWithRootObject:@{@"cake" : @12.50,
                                                                     @"juice" : @0.50}];
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

- (NSManagedObject *)orderedNoteWithID:(NSNumber *)remoteID
           inContext:(NSManagedObjectContext *)context {
    NSManagedObject *note = [self entityNamed:@"OrderedNote" inContext:context];
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
    comparedDictionary[@"last_name"] = @"Sid";
    comparedDictionary[@"number_of_attendes"] = @30;
    comparedDictionary[@"type"] = @"Manager";
    comparedDictionary[@"updated_at"] = resultDateString;
    comparedDictionary[@"signed"] = @"raw";

    return [comparedDictionary copy];
}

- (void)testDictionaryNoRelationships {
    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
    NSDictionary *dictionary = [user hyp_dictionaryUsingRelationshipType:SyncPropertyMapperRelationshipTypeNone];
    NSDictionary *comparedDictionary = [self userDictionaryWithNoRelationships];
    XCTAssertEqualObjects(dictionary, [comparedDictionary copy]);
}

- (void)testDictionaryArrayRelationships {
    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
    NSDictionary *dictionary = [user hyp_dictionaryUsingRelationshipType:SyncPropertyMapperRelationshipTypeArray];
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
    DataStack *dataStack = [[DataStack alloc] initWithModelName:@"Ordered"
                                                         bundle:[NSBundle bundleForClass:[self class]]
                                                      storeType:DataStackStoreTypeInMemory];

    NSManagedObject *user = [self entityNamed:@"OrderedUser" inContext:dataStack.mainContext];
    [user setValue:@"raw" forKey:@"rawSigned"];

    [user setValue:@"raw" forKey:@"rawSigned"];
    [user setValue:@25 forKey:@"age"];
    [user setValue:self.testDate forKey:@"birthDate"];
    [user setValue:@235 forKey:@"contractID"];
    [user setValue:@"ABC8283" forKey:@"driverIdentifier"];
    [user setValue:@"John" forKey:@"firstName"];
    [user setValue:@"Sid" forKey:@"lastName"];
    [user setValue:@"John Description" forKey:@"orderedUserDescription"];
    [user setValue:@111 forKey:@"remoteID"];
    [user setValue:@"Manager" forKey:@"orderedUserType"];
    [user setValue:self.testDate forKey:@"createdAt"];
    [user setValue:self.testDate forKey:@"updatedAt"];
    [user setValue:@30 forKey:@"numberOfAttendes"];

    NSData *hobbies = [NSKeyedArchiver archivedDataWithRootObject:@[@"Football",
                                                                    @"Soccer",
                                                                    @"Code",
                                                                    @"More code"]];
    [user setValue:hobbies forKey:@"hobbies"];

    NSData *expenses = [NSKeyedArchiver archivedDataWithRootObject:@{@"cake" : @12.50,
                                                                     @"juice" : @0.50}];
    [user setValue:expenses forKey:@"expenses"];

    NSManagedObject *note = [self orderedNoteWithID:@1 inContext:dataStack.mainContext];
    [note setValue:user forKey:@"user"];

    note = [self orderedNoteWithID:@14 inContext:dataStack.mainContext];
    [note setValue:user forKey:@"user"];
    [note setValue:@YES forKey:@"destroy"];

    note = [self orderedNoteWithID:@7 inContext:dataStack.mainContext];
    [note setValue:user forKey:@"user"];

    NSDictionary *dictionary = [user hyp_dictionaryUsingRelationshipType:SyncPropertyMapperRelationshipTypeArray];
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
    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
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
    DataStack *dataStack = [self dataStack];

    NSManagedObject *building = [self entityNamed:@"Building" inContext:dataStack.mainContext];
    [building setValue:@1 forKey:@"remoteID"];

    NSManagedObject *park = [self entityNamed:@"Park" inContext:dataStack.mainContext];
    [park setValue:@1 forKey:@"remoteID"];

    NSMutableSet *parks = [building valueForKey:@"parks"];
    [parks addObject:park];
    [building setValue:parks forKey:@"parks"];

    NSManagedObject *apartment = [self entityNamed:@"Apartment" inContext:dataStack.mainContext];
    [apartment setValue:@1 forKey:@"remoteID"];

    NSManagedObject *room = [self entityNamed:@"Room" inContext:dataStack.mainContext];
    [room setValue:@1 forKey:@"remoteID"];

    NSMutableSet *rooms = [apartment valueForKey:@"rooms"];
    [rooms addObject:room];
    [apartment setValue:rooms forKey:@"rooms"];

    NSMutableSet *apartments = [building valueForKey:@"apartments"];
    [apartments addObject:apartment];
    [building setValue:apartments forKey:@"apartments"];

    NSDictionary *buildingDictionary = [building hyp_dictionaryUsingRelationshipType:SyncPropertyMapperRelationshipTypeArray];
    NSMutableDictionary *compared = [NSMutableDictionary new];
    NSArray *roomsArray = @[@{@"id" : @1}];
    NSArray *apartmentsArray = @[@{@"id" : @1,
                              @"rooms" : roomsArray}];
    NSArray *parksArray = @[@{@"id" : @1}];
    compared[@"id"] = @1;
    compared[@"apartments"] = apartmentsArray;
    compared[@"parks"] = parksArray;

    XCTAssertEqualObjects(buildingDictionary, compared);
}

- (void)testDictionaryValuesKindOfClass {
    DataStack *dataStack = [self dataStack];
    NSManagedObject *user = [self userUsingDataStack:dataStack];
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
    DataStack *dataStack = [self dataStack];

    NSManagedObject *megachild = [self entityNamed:@"Recursive" inContext:dataStack.mainContext];
    [megachild setValue:@"megachild" forKey:@"remoteID"];

    NSManagedObject *grandchild = [self entityNamed:@"Recursive" inContext:dataStack.mainContext];
    [grandchild setValue:@"grandchild" forKey:@"remoteID"];

    NSMutableSet *recursives = [grandchild valueForKey:@"recursives"];
    [recursives addObject:megachild];
    [grandchild setValue:recursives forKey:@"recursives"];
    [megachild setValue:grandchild forKey:@"recursive"];

    NSManagedObject *child = [self entityNamed:@"Recursive" inContext:dataStack.mainContext];
    [child setValue:@"child" forKey:@"remoteID"];

    recursives = [child valueForKey:@"recursives"];
    [recursives addObject:grandchild];
    [child setValue:recursives forKey:@"recursives"];
    [grandchild setValue:child forKey:@"recursive"];

    NSManagedObject *parent = [self entityNamed:@"Recursive" inContext:dataStack.mainContext];
    [parent setValue:@"Parent" forKey:@"remoteID"];

    recursives = [parent valueForKey:@"recursives"];
    [recursives addObject:child];
    [parent setValue:recursives forKey:@"recursives"];
    [child setValue:parent forKey:@"recursive"];

    NSDictionary *dictionary = [parent hyp_dictionaryUsingRelationshipType:SyncPropertyMapperRelationshipTypeArray];
    NSArray *megachildArray = @[@{@"id" : @"megachild", @"recursives": @[]}];
    NSArray *grandchildArray = @[@{@"id" : @"grandchild", @"recursives": megachildArray}];
    NSArray *childArray = @[@{@"id" : @"child", @"recursives": grandchildArray}];
    NSDictionary *parentDictionary = @{@"id" : @"Parent", @"recursives" : childArray};
    XCTAssertEqualObjects(dictionary, parentDictionary);
}

@end
