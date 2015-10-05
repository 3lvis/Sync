@import XCTest;

@import CoreData;

#import "Sync.h"
#import "NSJSONSerialization+ANDYJSONFile.h"
#import "DATAStack.h"
#import "NSManagedObject+HYPPropertyMapper.h"

@interface Tests : XCTestCase

@end

@implementation Tests

#pragma mark - Helpers

- (DATAStack *)dataStackWithModelName:(NSString *)modelName {
    DATAStack *dataStack = [[DATAStack alloc] initWithModelName:modelName
                                                         bundle:[NSBundle bundleForClass:[self class]]
                                                      storeType:DATAStackSQLiteStoreType];

    return dataStack;
}

- (id)objectsFromJSON:(NSString *)fileName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    id objects = [NSJSONSerialization JSONObjectWithContentsOfFile:fileName inBundle:bundle];

    return objects;
}

- (NSInteger)countForEntity:(NSString *)entity
                  inContext:(NSManagedObjectContext *)context {
    return [self countForEntity:entity
                      predicate:nil
                      inContext:context];
}

- (NSInteger)countForEntity:(NSString *)entity
                  predicate:(NSPredicate *)predicate
                  inContext:(NSManagedObjectContext *)context {
    NSError *error = nil;
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:entity];
    fetch.predicate = predicate;
    NSInteger count = [context countForFetchRequest:fetch error:&error];
    if (error) NSLog(@"countError: %@", [error description]);

    return count;
}

- (NSArray *)fetchEntity:(NSString *)entity
               inContext:(NSManagedObjectContext *)context {
    return [self fetchEntity:entity
                   predicate:nil
                   inContext:context];
}

- (NSArray *)fetchEntity:(NSString *)entity
               predicate:(NSPredicate *)predicate
               inContext:(NSManagedObjectContext *)context {
    return [self fetchEntity:entity
                   predicate:predicate
             sortDescriptors:nil
                   inContext:context];
}

- (NSArray *)fetchEntity:(NSString *)entity
         sortDescriptors:(NSArray *)sortDescriptors
               inContext:(NSManagedObjectContext *)context {
    return [self fetchEntity:entity
                   predicate:nil
             sortDescriptors:sortDescriptors
                   inContext:context];
}

- (NSArray *)fetchEntity:(NSString *)entity
               predicate:(NSPredicate *)predicate
         sortDescriptors:(NSArray *)sortDescriptors
               inContext:(NSManagedObjectContext *)context {

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entity];
    request.predicate = predicate;
    request.sortDescriptors = sortDescriptors;
    NSError *error = nil;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (error) NSLog(@"fetchError: %@", error);

    return objects;
}

#pragma mark - Tests

#pragma mark Contacts

- (void)testLoadAndUpdateUsers {
    NSArray *objectsA = [self objectsFromJSON:@"users_a.json"];

    DATAStack *dataStack = [self dataStackWithModelName:@"Contacts"];

    [Sync changes:objectsA
    inEntityNamed:@"User"
        dataStack:dataStack
       completion:nil];

    NSInteger count = [self countForEntity:@"User" inContext:dataStack.mainContext];
    XCTAssertEqual(count, 8);

    NSArray *objectsB = [self objectsFromJSON:@"users_b.json"];

    [Sync changes:objectsB
    inEntityNamed:@"User"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([self countForEntity:@"User"
                              inContext:dataStack.mainContext], 6);

    NSManagedObject *result = [[self fetchEntity:@"User"
                                       predicate:[NSPredicate predicateWithFormat:@"remoteID == %@", @7]
                                 sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"remoteID" ascending:YES]]
                                       inContext:dataStack.mainContext] firstObject];
    XCTAssertEqualObjects([result valueForKey:@"email"], @"secondupdated@ovium.com");

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.dateFormat = @"yyyy-MM-dd";
    dateFormat.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];

    NSDate *createdDate = [dateFormat dateFromString:@"2014-02-14"];
    XCTAssertEqualObjects([result valueForKey:@"createdAt"], createdDate);

    NSDate *updatedDate = [dateFormat dateFromString:@"2014-02-17"];
    XCTAssertEqualObjects([result valueForKey:@"updatedAt"], updatedDate);

    [dataStack drop];
}

- (void)testUsersAndCompanies {
    NSArray *objects = [self objectsFromJSON:@"users_company.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Contacts"];

    [Sync changes:objects
    inEntityNamed:@"User"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([self countForEntity:@"User"
                              inContext:dataStack.mainContext], 5);
    NSManagedObject *user = [[self fetchEntity:@"User"
                                     predicate:[NSPredicate predicateWithFormat:@"remoteID == %@", @0]
                               sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"remoteID" ascending:YES]]
                                     inContext:dataStack.mainContext] firstObject];
    XCTAssertEqualObjects([[user valueForKey:@"company"] valueForKey:@"name"], @"Apple");

    XCTAssertEqual([self countForEntity:@"Company"
                              inContext:dataStack.mainContext], 2);
    NSManagedObject *company = [[self fetchEntity:@"Company"
                                        predicate:[NSPredicate predicateWithFormat:@"remoteID = %@", @1]
                                  sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"remoteID" ascending:YES]]
                                        inContext:dataStack.mainContext] firstObject];
    XCTAssertEqualObjects([company valueForKey:@"name"], @"Facebook");

    [dataStack drop];
}

- (void)testCustomMappingAndCustomPrimaryKey {
    NSArray *objects = [self objectsFromJSON:@"images.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Contacts"];

    [Sync changes:objects
    inEntityNamed:@"Image"
        dataStack:dataStack
       completion:nil];

    NSArray *array = [self fetchEntity:@"Image"
                       sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"url" ascending:YES]]
                             inContext:dataStack.mainContext];
    XCTAssertEqual(array.count, 3);
    NSManagedObject *image = [array firstObject];
    XCTAssertEqualObjects([image valueForKey:@"url"], @"http://sample.com/sample0.png");

    [dataStack drop];
}

- (void)testRelationshipsB {
    NSArray *objects = [self objectsFromJSON:@"users_c.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Contacts"];

    [Sync changes:objects
    inEntityNamed:@"User"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([self countForEntity:@"User"
                              inContext:dataStack.mainContext], 4);
    NSArray *users = [self fetchEntity:@"User"
                             predicate:[NSPredicate predicateWithFormat:@"remoteID = %@", @6]
                             inContext:dataStack.mainContext];
    NSManagedObject *user = [users firstObject];
    XCTAssertEqualObjects([user valueForKey:@"name"], @"Shawn Merrill");

    NSManagedObject *location = [user valueForKey:@"location"];
    XCTAssertTrue([[location valueForKey:@"city"] isEqualToString:@"New York"]);
    XCTAssertTrue([[location valueForKey:@"street"] isEqualToString:@"Broadway"]);
    XCTAssertEqualObjects([location valueForKey:@"zipCode"], @10012);

    NSInteger profilePicturesCount = [self countForEntity:@"Image"
                                                predicate:[NSPredicate predicateWithFormat:@"user = %@", user]
                                                inContext:dataStack.mainContext];
    XCTAssertEqual(profilePicturesCount, 3);

    [dataStack drop];
}

#pragma mark Notes

- (void)testRelationshipsA {
    NSArray *objects = [self objectsFromJSON:@"users_notes.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Notes"];

    [Sync changes:objects
    inEntityNamed:@"User"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([self countForEntity:@"User"
                              inContext:dataStack.mainContext], 4);
    NSArray *users = [self fetchEntity:@"User"
                             predicate:[NSPredicate predicateWithFormat:@"remoteID = %@", @6]
                             inContext:dataStack.mainContext];
    NSManagedObject *user = [users firstObject];
    XCTAssertEqualObjects([user valueForKey:@"name"], @"Shawn Merrill");

    NSInteger notesCount = [self countForEntity:@"Note"
                                      predicate:[NSPredicate predicateWithFormat:@"user = %@", user]
                                      inContext:dataStack.mainContext];
    XCTAssertEqual(notesCount, 5);

    [dataStack drop];
}

- (void)testObjectsForParent {
    NSArray *objects = [self objectsFromJSON:@"notes_for_user_a.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Notes"];

    [dataStack performInNewBackgroundContext:^(NSManagedObjectContext *backgroundContext) {
        NSManagedObject *user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                              inManagedObjectContext:backgroundContext];
        [user setValue:@6 forKey:@"remoteID"];
        [user setValue:@"Shawn Merrill" forKey:@"name"];
        [user setValue:@"firstupdate@ovium.com" forKey:@"email"];

        NSError *userError = nil;
        [backgroundContext save:&userError];
        if (userError) NSLog(@"userError: %@", userError);

        [dataStack persistWithCompletion:nil];
    }];

    NSArray *users = [self fetchEntity:@"User"
                             predicate:[NSPredicate predicateWithFormat:@"remoteID = %@", @6]
                             inContext:dataStack.mainContext];
    if (users.count != 1) abort();

    [Sync changes:objects
    inEntityNamed:@"Note"
           parent:[users firstObject]
        dataStack:dataStack
       completion:nil];

    users = [self fetchEntity:@"User"
                    predicate:[NSPredicate predicateWithFormat:@"remoteID = %@", @6]
                    inContext:dataStack.mainContext];
    NSManagedObject *user = [users firstObject];
    XCTAssertEqualObjects([user valueForKey:@"name"], @"Shawn Merrill");

    NSInteger notesCount = [self countForEntity:@"Note"
                                      predicate:[NSPredicate predicateWithFormat:@"user = %@", user]
                                      inContext:dataStack.mainContext];
    XCTAssertEqual(notesCount, 5);

    [dataStack drop];
}

- (void)testTaggedNotesForUser {
    NSArray *objects = [self objectsFromJSON:@"tagged_notes.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Notes"];

    [Sync changes:objects
    inEntityNamed:@"Note"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([self countForEntity:@"Note"
                              inContext:dataStack.mainContext], 5);
    NSArray *notes = [self fetchEntity:@"Note"
                             predicate:[NSPredicate predicateWithFormat:@"remoteID = %@", @0]
                             inContext:dataStack.mainContext];
    NSManagedObject *note = [notes firstObject];
    XCTAssertEqual([[[note valueForKey:@"tags"] allObjects] count], 2,
                   @"Note with ID 0 should have 2 tags");

    XCTAssertEqual([self countForEntity:@"Tag"
                              inContext:dataStack.mainContext], 2);
    NSArray *tags = [self fetchEntity:@"Tag"
                            predicate:[NSPredicate predicateWithFormat:@"remoteID = %@", @1]
                            inContext:dataStack.mainContext];
    XCTAssertEqual(tags.count, 1);

    NSManagedObject *tag = [tags firstObject];
    XCTAssertEqual([[[tag valueForKey:@"notes"] allObjects] count], 4,
                   @"Tag with ID 1 should have 4 notes");

    [dataStack drop];
}

- (void)testCustomKeysInRelationshipsToMany {
    NSArray *objects = [self objectsFromJSON:@"custom_relationship_key_to_many.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Notes"];

    [Sync changes:objects
    inEntityNamed:@"User"
        dataStack:dataStack
       completion:nil];

    NSArray *array = [self fetchEntity:@"User"
                             inContext:dataStack.mainContext];
    NSManagedObject *user = [array firstObject];
    XCTAssertEqual([[[user valueForKey:@"notes"] allObjects] count], 3);

    [dataStack drop];
}

// Sync provides a predicate method to filter which methods would be synced
// this test checks that providing a predicate for "startTime > now" only syncs
// elements that start in the future.
- (void)testSyncWithPredicateAfterDate {
    DATAStack *dataStack = [self dataStackWithModelName:@"Notes"];

    NSDictionary *old1 = @{@"id" : @1, @"name" : @"Old 1", @"created_at" : @"2014-02-14T00:00:00+00:00"};
    NSDictionary *old2 = @{@"id" : @2, @"name" : @"Old 2", @"created_at" : @"2014-03-14T00:00:00+00:00"};
    NSArray *objects = @[old1, old2];

    [Sync changes:objects
    inEntityNamed:@"User"
        dataStack:dataStack
       completion:nil];

    NSArray *array = [self fetchEntity:@"User"
                             inContext:dataStack.mainContext];
    XCTAssertEqual(array.count, 2);

    NSDictionary *updatedOld2 = @{@"id" : @2, @"name" : @"Updated Old 2", @"created_at" : @"2014-03-14T00:00:00+00:00"};
    NSDictionary *new = @{@"id" : @3, @"name" : @"New 2", @"created_at" : @"2019-03-14T00:00:00+00:00"};
    NSArray *newObjects = @[updatedOld2, new];

    [Sync changes:newObjects
    inEntityNamed:@"User"
        predicate:[NSPredicate predicateWithFormat:@"createdAt > %@", [NSDate date]]
        dataStack:dataStack
       completion:nil];

    NSArray *updatedArray = [self fetchEntity:@"User"
                                    inContext:dataStack.mainContext];
    XCTAssertEqual(updatedArray.count, 3);

    [dataStack drop];
}

#pragma mark Recursive

- (void)testNumbersWithEmptyRelationship {
    NSArray *objects = [self objectsFromJSON:@"numbers.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Recursive"];

    [Sync changes:objects
    inEntityNamed:@"Number"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([self countForEntity:@"Number"
                              inContext:dataStack.mainContext], 6);

    [dataStack drop];
}

- (void)testRelationshipName {
    NSArray *objects = [self objectsFromJSON:@"numbers_in_collection.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Recursive"];

    [Sync changes:objects
    inEntityNamed:@"Number"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([self countForEntity:@"Collection"
                              inContext:dataStack.mainContext], 1);

    NSArray *numbers = [self fetchEntity:@"Number"
                               inContext:dataStack.mainContext];
    NSManagedObject *number = [numbers firstObject];
    XCTAssertNotNil([number valueForKey:@"parent"]);
    XCTAssertEqualObjects([[number valueForKey:@"parent"]  valueForKey:@"name"], @"Collection 1");

    [dataStack drop];
}

#pragma mark Social

- (void)testCustomPrimaryKey {
    NSArray *objects = [self objectsFromJSON:@"comments-no-id.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Social"];

    [Sync changes:objects
    inEntityNamed:@"Comment"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([self countForEntity:@"Comment"
                              inContext:dataStack.mainContext], 8);
    NSArray *comments = [self fetchEntity:@"Comment"
                                predicate:[NSPredicate predicateWithFormat:@"body = %@", @"comment 1"]
                                inContext:dataStack.mainContext];
    XCTAssertEqual(comments.count, 1);
    XCTAssertEqual([[[comments firstObject] valueForKey:@"comments"] count], 3);

    NSManagedObject *comment = [comments firstObject];
    XCTAssertEqualObjects([comment valueForKey:@"body"], @"comment 1");

    [dataStack drop];
}

- (void)testCustomPrimaryKeyInsideToManyRelationship {
    NSArray *objects = [self objectsFromJSON:@"stories-comments-no-ids.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Social"];

    [Sync changes:objects
    inEntityNamed:@"Story"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([self countForEntity:@"Story"
                              inContext:dataStack.mainContext], 3);
    NSArray *stories = [self fetchEntity:@"Story"
                               predicate:[NSPredicate predicateWithFormat:@"remoteID = %@", @0]
                               inContext:dataStack.mainContext];
    NSManagedObject *story = [stories firstObject];
    XCTAssertEqual([[story valueForKey:@"comments"] count], 3);

    XCTAssertEqual([self countForEntity:@"Comment"
                              inContext:dataStack.mainContext], 9);
    NSArray *comments = [self fetchEntity:@"Comment"
                                predicate:[NSPredicate predicateWithFormat:@"body = %@", @"comment 1"]
                                inContext:dataStack.mainContext];
    XCTAssertEqual(comments.count, 3);

    comments = [self fetchEntity:@"Comment"
                       predicate:[NSPredicate predicateWithFormat:@"body = %@ AND story = %@", @"comment 1", story]
                       inContext:dataStack.mainContext];
    XCTAssertEqual(comments.count, 1);
    NSManagedObject *comment = [comments firstObject];
    XCTAssertEqualObjects([comment valueForKey:@"body"], @"comment 1");
    XCTAssertEqualObjects([[comment valueForKey:@"story"] valueForKey:@"remoteID"], @0);
    XCTAssertEqualObjects([[comment valueForKey:@"story"] valueForKey:@"title"], @"story 1");

    [dataStack drop];
}

- (void)testCustomKeysInRelationshipsToOne {
    NSArray *objects = [self objectsFromJSON:@"custom_relationship_key_to_one.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Social"];

    [Sync changes:objects
    inEntityNamed:@"Story"
        dataStack:dataStack
       completion:nil];

    NSArray *array = [self fetchEntity:@"Story"
                             inContext:dataStack.mainContext];
    NSManagedObject *story = [array firstObject];
    XCTAssertNotNil([story valueForKey:@"summarize"]);

    [dataStack drop];
}

#pragma mark Markets

- (void)testMarketsAndItems {
    NSArray *objects = [self objectsFromJSON:@"markets_items.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Markets"];

    [Sync changes:objects
    inEntityNamed:@"Market"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([self countForEntity:@"Market"
                              inContext:dataStack.mainContext], 2);
    NSArray *markets = [self fetchEntity:@"Market"
                               predicate:[NSPredicate predicateWithFormat:@"uniqueId = %@", @"1"]
                               inContext:dataStack.mainContext];
    NSManagedObject *market = [markets firstObject];
    XCTAssertEqualObjects([market valueForKey:@"otherAttribute"], @"Market 1");
    XCTAssertEqual([[[market valueForKey:@"items"] allObjects] count], 1);

    XCTAssertEqual([self countForEntity:@"Item"
                              inContext:dataStack.mainContext], 1);
    NSArray *items = [self fetchEntity:@"Item"
                             predicate:[NSPredicate predicateWithFormat:@"uniqueId = %@", @"1"]
                             inContext:dataStack.mainContext];
    NSManagedObject *item = [items firstObject];
    XCTAssertEqualObjects([item valueForKey:@"otherAttribute"], @"Item 1");
    XCTAssertEqual([[[item valueForKey:@"markets"] allObjects] count], 2);

    [dataStack drop];
}

#pragma mark Organization

- (void)testOrganization {

    NSArray *json = [self objectsFromJSON:@"organizations-tree.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Organizations"];

    [Sync changes:json inEntityNamed:@"OrganizationUnit" dataStack:dataStack completion:nil];
    XCTAssertEqual([self countForEntity:@"OrganizationUnit"
                              inContext:dataStack.mainContext], 7);

    [Sync changes:json inEntityNamed:@"OrganizationUnit" dataStack:dataStack completion:nil];
    XCTAssertEqual([self countForEntity:@"OrganizationUnit"
                              inContext:dataStack.mainContext], 7);

    [dataStack drop];
}

#pragma mark Unique

/**
 *  C and A share the same collection of B, so in the first block
 *  2 entries of B get stored in A, in the second block this
 *  2 entries of B get updated and one entry of C gets added.
 */
- (void)testUniqueObject {
    NSArray *objects = [self objectsFromJSON:@"unique.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Unique"];

    [Sync changes:objects
    inEntityNamed:@"A"
        dataStack:dataStack
       completion:nil];
    XCTAssertEqual([self countForEntity:@"A"
                              inContext:dataStack.mainContext], 1);
    XCTAssertEqual([self countForEntity:@"B"
                              inContext:dataStack.mainContext], 2);
    XCTAssertEqual([self countForEntity:@"C"
                              inContext:dataStack.mainContext], 0);

    [Sync changes:objects
    inEntityNamed:@"C"
        dataStack:dataStack
       completion:nil];
    XCTAssertEqual([self countForEntity:@"A"
                              inContext:dataStack.mainContext], 1);
    XCTAssertEqual([self countForEntity:@"B"
                              inContext:dataStack.mainContext], 2);
    XCTAssertEqual([self countForEntity:@"C"
                              inContext:dataStack.mainContext], 1);

    [dataStack drop];
}

#pragma mark Patients => https://github.com/hyperoslo/Sync/issues/121

- (void)testPatients {
    NSArray *objects = [self objectsFromJSON:@"patients.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Patients"];

    [Sync changes:objects
    inEntityNamed:@"Patient"
        dataStack:dataStack
       completion:nil];
    XCTAssertEqual([self countForEntity:@"Patient"
                              inContext:dataStack.mainContext], 1);
    XCTAssertEqual([self countForEntity:@"Baseline"
                              inContext:dataStack.mainContext], 1);
    XCTAssertEqual([self countForEntity:@"Alcohol"
                              inContext:dataStack.mainContext], 1);
    XCTAssertEqual([self countForEntity:@"Fitness"
                              inContext:dataStack.mainContext], 1);
    XCTAssertEqual([self countForEntity:@"Weight"
                              inContext:dataStack.mainContext], 1);
    XCTAssertEqual([self countForEntity:@"Measure"
                              inContext:dataStack.mainContext], 1);

    [dataStack drop];
}

#pragma mark Bug 84 => https://github.com/hyperoslo/Sync/issues/84

- (void)testStaffAndfulfillers {
    NSArray *objects = [self objectsFromJSON:@"bug-number-84.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Bug84"];

    [Sync changes:objects
    inEntityNamed:@"MSStaff"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([self countForEntity:@"MSStaff"
                              inContext:dataStack.mainContext], 1);

    NSArray *staff = [self fetchEntity:@"MSStaff"
                             predicate:[NSPredicate predicateWithFormat:@"xid = %@", @"mstaff_F58dVBTsXznvMpCPmpQgyV"]
                             inContext:dataStack.mainContext];
    NSManagedObject *oneStaff = [staff firstObject];
    XCTAssertEqualObjects([oneStaff valueForKey:@"image"], @"a.jpg");
    XCTAssertEqual([[[oneStaff valueForKey:@"fulfillers"] allObjects] count], 2);

    NSInteger numberOffulfillers = [self countForEntity:@"MSFulfiller"
                                              inContext:dataStack.mainContext];
    XCTAssertEqual(numberOffulfillers, 2);

    NSArray *fulfillers = [self fetchEntity:@"MSFulfiller"
                                  predicate:[NSPredicate predicateWithFormat:@"xid = %@", @"ffr_AkAHQegYkrobp5xc2ySc5D"]
                                  inContext:dataStack.mainContext];
    NSManagedObject *fullfiller = [fulfillers firstObject];
    XCTAssertEqualObjects([fullfiller valueForKey:@"name"], @"New York");
    XCTAssertEqual([[[fullfiller valueForKey:@"staff"] allObjects] count], 1);

    [dataStack drop];
}

#pragma mark Bug 113 => https://github.com/hyperoslo/Sync/issues/113

- (void)testCustomPrimaryKeyBug113 {
    NSArray *objects = [self objectsFromJSON:@"bug-113-comments-no-id.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Bug113"];

    [Sync changes:objects
    inEntityNamed:@"AwesomeComment"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([self countForEntity:@"AwesomeComment"
                              inContext:dataStack.mainContext], 8);
    NSArray *comments = [self fetchEntity:@"AwesomeComment"
                                predicate:[NSPredicate predicateWithFormat:@"body = %@", @"comment 1"]
                                inContext:dataStack.mainContext];
    XCTAssertEqual(comments.count, 1);
    XCTAssertEqual([[[comments firstObject] valueForKey:@"awesomeComments"] count], 3);

    NSManagedObject *comment = [comments firstObject];
    XCTAssertEqualObjects([comment valueForKey:@"body"], @"comment 1");

    [dataStack drop];
}

- (void)testCustomPrimaryKeyInsideToManyRelationshipBug113 {
    NSArray *objects = [self objectsFromJSON:@"bug-113-stories-comments-no-ids.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Bug113"];

    [Sync changes:objects
    inEntityNamed:@"AwesomeStory"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([self countForEntity:@"AwesomeStory"
                              inContext:dataStack.mainContext], 3);
    NSArray *stories = [self fetchEntity:@"AwesomeStory"
                               predicate:[NSPredicate predicateWithFormat:@"remoteID = %@", @0]
                               inContext:dataStack.mainContext];
    NSManagedObject *story = [stories firstObject];
    XCTAssertEqual([[story valueForKey:@"awesomeComments"] count], 3);

    XCTAssertEqual([self countForEntity:@"AwesomeComment"
                              inContext:dataStack.mainContext], 9);
    NSArray *comments = [self fetchEntity:@"AwesomeComment"
                                predicate:[NSPredicate predicateWithFormat:@"body = %@", @"comment 1"]
                                inContext:dataStack.mainContext];
    XCTAssertEqual(comments.count, 3);

    comments = [self fetchEntity:@"AwesomeComment"
                       predicate:[NSPredicate predicateWithFormat:@"body = %@ AND awesomeStory = %@", @"comment 1", story]
                       inContext:dataStack.mainContext];
    XCTAssertEqual(comments.count, 1);
    NSManagedObject *comment = [comments firstObject];
    XCTAssertEqualObjects([comment valueForKey:@"body"], @"comment 1");
    XCTAssertEqualObjects([[comment valueForKey:@"awesomeStory"] valueForKey:@"remoteID"], @0);
    XCTAssertEqualObjects([[comment valueForKey:@"awesomeStory"] valueForKey:@"title"], @"story 1");

    [dataStack drop];
}

- (void)testCustomKeysInRelationshipsToOneBug113 {
    NSArray *objects = [self objectsFromJSON:@"bug-113-custom_relationship_key_to_one.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Bug113"];

    [Sync changes:objects
    inEntityNamed:@"AwesomeStory"
        dataStack:dataStack
       completion:nil];

    NSArray *array = [self fetchEntity:@"AwesomeStory"
                             inContext:dataStack.mainContext];
    NSManagedObject *story = [array firstObject];
    XCTAssertNotNil([story valueForKey:@"awesomeSummarize"]);

    [dataStack drop];
}

#pragma mark Bug 125 => https://github.com/hyperoslo/Sync/issues/125

- (void)testNilRelationshipsAfterUpdating_Sync_1_0_10 {
    NSDictionary *form = [self objectsFromJSON:@"bug-125.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Bug125"];

    [Sync changes:@[form]
    inEntityNamed:@"Form"
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

    [dataStack drop];
}

@end
