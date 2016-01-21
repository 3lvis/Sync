@import XCTest;
@import DATAStack;
#import "Tests-Swift.h"
@import Sync;

@interface SyncTests : XCTestCase

@end

@implementation SyncTests

#pragma mark Notes

- (void)testObjectsForParent {
    NSArray *objects = [Helper objectsFromJSON:@"notes_for_user_a.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Notes"];

    [dataStack performInNewBackgroundContext:^(NSManagedObjectContext *backgroundContext) {

        // First, we create a parent user, this user is the one that will own all the notes
        NSManagedObject *user = [NSEntityDescription insertNewObjectForEntityForName:@"SuperUser"
                                                              inManagedObjectContext:backgroundContext];
        [user setValue:@6 forKey:@"remoteID"];
        [user setValue:@"Shawn Merrill" forKey:@"name"];
        [user setValue:@"firstupdate@ovium.com" forKey:@"email"];

        NSError *userError = nil;
        [backgroundContext save:&userError];
        if (userError) NSLog(@"userError: %@", userError);

        [dataStack persistWithCompletion:nil];
    }];

    // Then we fetch the user on the main context, because we don't want to break things between contexts
    NSArray *users = [Helper fetchEntity:@"SuperUser"
                             predicate:[NSPredicate predicateWithFormat:@"remoteID = %@", @6]
                             inContext:dataStack.mainContext];
    XCTAssertEqual(users.count, 1);

    // Finally we say "Sync all the notes, for this user"
    [Sync changes:objects
    inEntityNamed:@"SuperNote"
           parent:[users firstObject]
        dataStack:dataStack
       completion:nil];

    // Here we just make sure that the user has the notes that we just inserted
    users = [Helper fetchEntity:@"SuperUser"
                    predicate:[NSPredicate predicateWithFormat:@"remoteID = %@", @6]
                    inContext:dataStack.mainContext];
    NSManagedObject *user = [users firstObject];
    XCTAssertEqualObjects([user valueForKey:@"name"], @"Shawn Merrill");

    NSInteger notesCount = [Helper countForEntity:@"SuperNote"
                                      predicate:[NSPredicate predicateWithFormat:@"superUser = %@", user]
                                      inContext:dataStack.mainContext];
    XCTAssertEqual(notesCount, 5);

    [dataStack drop];
}

- (void)testTaggedNotesForUser {
    NSArray *objects = [Helper objectsFromJSON:@"tagged_notes.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Notes"];

    [Sync changes:objects
    inEntityNamed:@"SuperNote"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([Helper countForEntity:@"SuperNote"
                              inContext:dataStack.mainContext], 5);
    NSArray *notes = [Helper fetchEntity:@"SuperNote"
                             predicate:[NSPredicate predicateWithFormat:@"remoteID = %@", @0]
                             inContext:dataStack.mainContext];
    NSManagedObject *note = [notes firstObject];
    XCTAssertEqual([[[note valueForKey:@"superTags"] allObjects] count], 2,
                   @"Note with ID 0 should have 2 tags");

    XCTAssertEqual([Helper countForEntity:@"SuperTag"
                              inContext:dataStack.mainContext], 2);
    NSArray *tags = [Helper fetchEntity:@"SuperTag"
                            predicate:[NSPredicate predicateWithFormat:@"remoteID = %@", @1]
                            inContext:dataStack.mainContext];
    XCTAssertEqual(tags.count, 1);

    NSManagedObject *tag = [tags firstObject];
    XCTAssertEqual([[[tag valueForKey:@"superNotes"] allObjects] count], 4,
                   @"Tag with ID 1 should have 4 notes");

    [dataStack drop];
}

- (void)testCustomKeysInRelationshipsToMany {
    NSArray *objects = [Helper objectsFromJSON:@"custom_relationship_key_to_many.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Notes"];

    [Sync changes:objects
    inEntityNamed:@"SuperUser"
        dataStack:dataStack
       completion:nil];

    NSArray *array = [Helper fetchEntity:@"SuperUser"
                             inContext:dataStack.mainContext];
    NSManagedObject *user = [array firstObject];
    XCTAssertEqual([[[user valueForKey:@"superNotes"] allObjects] count], 3);

    [dataStack drop];
}

// Sync provides a predicate method to filter which methods would be synced
// this test checks that providing a predicate for "startTime > now" only syncs
// elements that start in the future.
/*
- (void)testSyncWithPredicateAfterDate {
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Notes"];

    NSDictionary *old1 = @{@"id" : @1, @"name" : @"Old 1", @"created_at" : @"2014-02-14T00:00:00+00:00"};
    NSDictionary *old2 = @{@"id" : @2, @"name" : @"Old 2", @"created_at" : @"2014-03-14T00:00:00+00:00"};
    NSArray *objects = @[old1, old2];

    [Sync changes:objects
    inEntityNamed:@"SuperUser"
        dataStack:dataStack
       completion:nil];

    NSArray *array = [Helper fetchEntity:@"SuperUser"
                       sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"remoteID" ascending:YES]]
                             inContext:dataStack.mainContext];
    XCTAssertEqual(array.count, 2);

    NSManagedObject *user1 = array[0];
    XCTAssertEqualObjects([user1 valueForKey:@"name"], old1[@"name"]);

    NSManagedObject *user2 = array[1];
    XCTAssertEqualObjects([user2 valueForKey:@"name"], old2[@"name"]);

    NSDictionary *updatedOld2 = @{@"id" : @2, @"name" : @"Updated Old 2", @"created_at" : @"2014-03-14T00:00:00+00:00"};
    NSDictionary *new = @{@"id" : @3, @"name" : @"New 2", @"created_at" : @"2049-03-14T00:00:00+00:00"};
    NSArray *newObjects = @[updatedOld2, new];

    [Sync changes:newObjects
    inEntityNamed:@"SuperUser"
        predicate:[NSPredicate predicateWithFormat:@"createdAt > %@", [NSDate date]]
        dataStack:dataStack
       completion:nil];

    NSArray *updatedArray = [Helper fetchEntity:@"SuperUser"
                              sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"remoteID" ascending:YES]]
                                    inContext:dataStack.mainContext];
    XCTAssertEqual(updatedArray.count, 3);

    NSManagedObject *updatedUser1 = updatedArray[0];
    XCTAssertEqualObjects([updatedUser1 valueForKey:@"name"], old1[@"name"]);

    NSManagedObject *updatedUser2 = updatedArray[1];
    XCTAssertEqualObjects([updatedUser2 valueForKey:@"name"], old2[@"name"]);

    NSManagedObject *updatedUser3 = updatedArray[2];
    XCTAssertEqualObjects([updatedUser3 valueForKey:@"name"], new[@"name"]);

    [dataStack drop];
}
*/

#pragma mark Recursive

- (void)testNumbersWithEmptyRelationship {
    NSArray *objects = [Helper objectsFromJSON:@"numbers.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Recursive"];

    [Sync changes:objects
    inEntityNamed:@"Number"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([Helper countForEntity:@"Number"
                              inContext:dataStack.mainContext], 6);

    [dataStack drop];
}

- (void)testRelationshipName {
    NSArray *objects = [Helper objectsFromJSON:@"numbers_in_collection.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Recursive"];

    [Sync changes:objects
    inEntityNamed:@"Number"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([Helper countForEntity:@"Collection"
                              inContext:dataStack.mainContext], 1);

    NSArray *numbers = [Helper fetchEntity:@"Number"
                               inContext:dataStack.mainContext];
    NSManagedObject *number = [numbers firstObject];
    XCTAssertNotNil([number valueForKey:@"parent"]);
    XCTAssertEqualObjects([[number valueForKey:@"parent"]  valueForKey:@"name"], @"Collection 1");

    [dataStack drop];
}

#pragma mark Social

- (void)testCustomPrimaryKey {
    NSArray *objects = [Helper objectsFromJSON:@"comments-no-id.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Social"];

    [Sync changes:objects
    inEntityNamed:@"Comment"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([Helper countForEntity:@"Comment"
                              inContext:dataStack.mainContext], 8);
    NSArray *comments = [Helper fetchEntity:@"Comment"
                                predicate:[NSPredicate predicateWithFormat:@"body = %@", @"comment 1"]
                                inContext:dataStack.mainContext];
    XCTAssertEqual(comments.count, 1);
    XCTAssertEqual([[[comments firstObject] valueForKey:@"comments"] count], 3);

    NSManagedObject *comment = [comments firstObject];
    XCTAssertEqualObjects([comment valueForKey:@"body"], @"comment 1");

    [dataStack drop];
}

- (void)testCustomPrimaryKeyInsideToManyRelationship {
    NSArray *objects = [Helper objectsFromJSON:@"stories-comments-no-ids.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Social"];

    [Sync changes:objects
    inEntityNamed:@"Story"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([Helper countForEntity:@"Story"
                              inContext:dataStack.mainContext], 3);
    NSArray *stories = [Helper fetchEntity:@"Story"
                               predicate:[NSPredicate predicateWithFormat:@"remoteID = %@", @0]
                               inContext:dataStack.mainContext];
    NSManagedObject *story = [stories firstObject];
    XCTAssertEqual([[story valueForKey:@"comments"] count], 3);

    XCTAssertEqual([Helper countForEntity:@"Comment"
                              inContext:dataStack.mainContext], 9);
    NSArray *comments = [Helper fetchEntity:@"Comment"
                                predicate:[NSPredicate predicateWithFormat:@"body = %@", @"comment 1"]
                                inContext:dataStack.mainContext];
    XCTAssertEqual(comments.count, 3);

    comments = [Helper fetchEntity:@"Comment"
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
    NSArray *objects = [Helper objectsFromJSON:@"custom_relationship_key_to_one.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Social"];

    [Sync changes:objects
    inEntityNamed:@"Story"
        dataStack:dataStack
       completion:nil];

    NSArray *array = [Helper fetchEntity:@"Story"
                             inContext:dataStack.mainContext];
    NSManagedObject *story = [array firstObject];
    XCTAssertNotNil([story valueForKey:@"summarize"]);

    [dataStack drop];
}

#pragma mark Markets

- (void)testMarketsAndItems {
    NSArray *objects = [Helper objectsFromJSON:@"markets_items.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Markets"];

    [Sync changes:objects
    inEntityNamed:@"Market"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([Helper countForEntity:@"Market"
                              inContext:dataStack.mainContext], 2);
    NSArray *markets = [Helper fetchEntity:@"Market"
                               predicate:[NSPredicate predicateWithFormat:@"uniqueId = %@", @"1"]
                               inContext:dataStack.mainContext];
    NSManagedObject *market = [markets firstObject];
    XCTAssertEqualObjects([market valueForKey:@"otherAttribute"], @"Market 1");
    XCTAssertEqual([[[market valueForKey:@"items"] allObjects] count], 1);

    XCTAssertEqual([Helper countForEntity:@"Item"
                              inContext:dataStack.mainContext], 1);
    NSArray *items = [Helper fetchEntity:@"Item"
                             predicate:[NSPredicate predicateWithFormat:@"uniqueId = %@", @"1"]
                             inContext:dataStack.mainContext];
    NSManagedObject *item = [items firstObject];
    XCTAssertEqualObjects([item valueForKey:@"otherAttribute"], @"Item 1");
    XCTAssertEqual([[[item valueForKey:@"markets"] allObjects] count], 2);

    [dataStack drop];
}

#pragma mark Organization

- (void)testOrganization {

    NSArray *json = [Helper objectsFromJSON:@"organizations-tree.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Organizations"];

    [Sync changes:json inEntityNamed:@"OrganizationUnit" dataStack:dataStack completion:nil];
    XCTAssertEqual([Helper countForEntity:@"OrganizationUnit"
                              inContext:dataStack.mainContext], 7);

    [Sync changes:json inEntityNamed:@"OrganizationUnit" dataStack:dataStack completion:nil];
    XCTAssertEqual([Helper countForEntity:@"OrganizationUnit"
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
    NSArray *objects = [Helper objectsFromJSON:@"unique.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Unique"];

    [Sync changes:objects
    inEntityNamed:@"A"
        dataStack:dataStack
       completion:nil];
    XCTAssertEqual([Helper countForEntity:@"A"
                              inContext:dataStack.mainContext], 1);
    XCTAssertEqual([Helper countForEntity:@"B"
                              inContext:dataStack.mainContext], 2);
    XCTAssertEqual([Helper countForEntity:@"C"
                              inContext:dataStack.mainContext], 0);

    [Sync changes:objects
    inEntityNamed:@"C"
        dataStack:dataStack
       completion:nil];
    XCTAssertEqual([Helper countForEntity:@"A"
                              inContext:dataStack.mainContext], 1);
    XCTAssertEqual([Helper countForEntity:@"B"
                              inContext:dataStack.mainContext], 2);
    XCTAssertEqual([Helper countForEntity:@"C"
                              inContext:dataStack.mainContext], 1);

    [dataStack drop];
}

#pragma mark Patients => https://github.com/hyperoslo/Sync/issues/121

- (void)testPatients {
    NSArray *objects = [Helper objectsFromJSON:@"patients.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Patients"];

    [Sync changes:objects
    inEntityNamed:@"Patient"
        dataStack:dataStack
       completion:nil];
    XCTAssertEqual([Helper countForEntity:@"Patient"
                              inContext:dataStack.mainContext], 1);
    XCTAssertEqual([Helper countForEntity:@"Baseline"
                              inContext:dataStack.mainContext], 1);
    XCTAssertEqual([Helper countForEntity:@"Alcohol"
                              inContext:dataStack.mainContext], 1);
    XCTAssertEqual([Helper countForEntity:@"Fitness"
                              inContext:dataStack.mainContext], 1);
    XCTAssertEqual([Helper countForEntity:@"Weight"
                              inContext:dataStack.mainContext], 1);
    XCTAssertEqual([Helper countForEntity:@"Measure"
                              inContext:dataStack.mainContext], 1);

    [dataStack drop];
}

#pragma mark Bug 84 => https://github.com/hyperoslo/Sync/issues/84

- (void)testStaffAndfulfillers {
    NSArray *objects = [Helper objectsFromJSON:@"bug-number-84.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Bug84"];

    [Sync changes:objects
    inEntityNamed:@"MSStaff"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([Helper countForEntity:@"MSStaff"
                              inContext:dataStack.mainContext], 1);

    NSArray *staff = [Helper fetchEntity:@"MSStaff"
                             predicate:[NSPredicate predicateWithFormat:@"xid = %@", @"mstaff_F58dVBTsXznvMpCPmpQgyV"]
                             inContext:dataStack.mainContext];
    NSManagedObject *oneStaff = [staff firstObject];
    XCTAssertEqualObjects([oneStaff valueForKey:@"image"], @"a.jpg");
    XCTAssertEqual([[[oneStaff valueForKey:@"fulfillers"] allObjects] count], 2);

    NSInteger numberOffulfillers = [Helper countForEntity:@"MSFulfiller"
                                              inContext:dataStack.mainContext];
    XCTAssertEqual(numberOffulfillers, 2);

    NSArray *fulfillers = [Helper fetchEntity:@"MSFulfiller"
                                  predicate:[NSPredicate predicateWithFormat:@"xid = %@", @"ffr_AkAHQegYkrobp5xc2ySc5D"]
                                  inContext:dataStack.mainContext];
    NSManagedObject *fullfiller = [fulfillers firstObject];
    XCTAssertEqualObjects([fullfiller valueForKey:@"name"], @"New York");
    XCTAssertEqual([[[fullfiller valueForKey:@"staff"] allObjects] count], 1);

    [dataStack drop];
}

#pragma mark Bug 113 => https://github.com/hyperoslo/Sync/issues/113

- (void)testCustomPrimaryKeyBug113 {
    NSArray *objects = [Helper objectsFromJSON:@"bug-113-comments-no-id.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Bug113"];

    [Sync changes:objects
    inEntityNamed:@"AwesomeComment"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([Helper countForEntity:@"AwesomeComment"
                              inContext:dataStack.mainContext], 8);
    NSArray *comments = [Helper fetchEntity:@"AwesomeComment"
                                predicate:[NSPredicate predicateWithFormat:@"body = %@", @"comment 1"]
                                inContext:dataStack.mainContext];
    XCTAssertEqual(comments.count, 1);
    XCTAssertEqual([[[comments firstObject] valueForKey:@"awesomeComments"] count], 3);

    NSManagedObject *comment = [comments firstObject];
    XCTAssertEqualObjects([comment valueForKey:@"body"], @"comment 1");

    [dataStack drop];
}

- (void)testCustomPrimaryKeyInsideToManyRelationshipBug113 {
    NSArray *objects = [Helper objectsFromJSON:@"bug-113-stories-comments-no-ids.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Bug113"];

    [Sync changes:objects
    inEntityNamed:@"AwesomeStory"
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([Helper countForEntity:@"AwesomeStory"
                              inContext:dataStack.mainContext], 3);
    NSArray *stories = [Helper fetchEntity:@"AwesomeStory"
                               predicate:[NSPredicate predicateWithFormat:@"remoteID = %@", @0]
                               inContext:dataStack.mainContext];
    NSManagedObject *story = [stories firstObject];
    XCTAssertEqual([[story valueForKey:@"awesomeComments"] count], 3);

    XCTAssertEqual([Helper countForEntity:@"AwesomeComment"
                              inContext:dataStack.mainContext], 9);
    NSArray *comments = [Helper fetchEntity:@"AwesomeComment"
                                predicate:[NSPredicate predicateWithFormat:@"body = %@", @"comment 1"]
                                inContext:dataStack.mainContext];
    XCTAssertEqual(comments.count, 3);

    comments = [Helper fetchEntity:@"AwesomeComment"
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
    NSArray *objects = [Helper objectsFromJSON:@"bug-113-custom_relationship_key_to_one.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Bug113"];

    [Sync changes:objects
    inEntityNamed:@"AwesomeStory"
        dataStack:dataStack
       completion:nil];

    NSArray *array = [Helper fetchEntity:@"AwesomeStory"
                             inContext:dataStack.mainContext];
    NSManagedObject *story = [array firstObject];
    XCTAssertNotNil([story valueForKey:@"awesomeSummarize"]);

    [dataStack drop];
}

#pragma mark Bug 125 => https://github.com/hyperoslo/Sync/issues/125

- (void)testNilRelationshipsAfterUpdating_Sync_1_0_10 {
    NSDictionary *formDictionary = [Helper objectsFromJSON:@"bug-125.json"];
    NSString *uri = formDictionary[@"uri"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Bug125"];

    [Sync changes:@[formDictionary]
    inEntityNamed:@"Form"
        predicate:[NSPredicate predicateWithFormat:@"uri == %@", uri]
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([Helper countForEntity:@"Form"
                              inContext:dataStack.mainContext], 1);

    XCTAssertEqual([Helper countForEntity:@"Element"
                              inContext:dataStack.mainContext], 11);

    XCTAssertEqual([Helper countForEntity:@"SelectionItem"
                              inContext:dataStack.mainContext], 4);

    XCTAssertEqual([Helper countForEntity:@"Model"
                              inContext:dataStack.mainContext], 1);

    XCTAssertEqual([Helper countForEntity:@"ModelProperty"
                              inContext:dataStack.mainContext], 9);

    XCTAssertEqual([Helper countForEntity:@"Restriction"
                              inContext:dataStack.mainContext], 3);

    NSArray *array = [Helper fetchEntity:@"Form"
                             inContext:dataStack.mainContext];
    NSManagedObject *form = [array firstObject];
    NSManagedObject *element = [form valueForKey:@"element"];
    NSManagedObject *model = [form valueForKey:@"model"];
    XCTAssertNotNil(element);
    XCTAssertNotNil(model);

    [dataStack drop];
}

- (void)testStoryToSummarize {
    NSDictionary *formDictionary = [Helper objectsFromJSON:@"story-summarize.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Social"];

    [Sync changes:@[formDictionary]
    inEntityNamed:@"Story"
        predicate:[NSPredicate predicateWithFormat:@"remoteID == %@", @1]
        dataStack:dataStack
       completion:nil];

    XCTAssertEqual([Helper countForEntity:@"Story"
                              inContext:dataStack.mainContext], 1);
    NSArray *stories = [Helper fetchEntity:@"Story"
                               predicate:[NSPredicate predicateWithFormat:@"remoteID = %@", @1]
                               inContext:dataStack.mainContext];
    NSManagedObject *story = [stories firstObject];
    NSManagedObject *summarize = [story valueForKey:@"summarize"];
    XCTAssertEqualObjects([summarize valueForKey:@"remoteID"], @1);
    XCTAssertEqual([[story valueForKey:@"comments"] count], 1);

    XCTAssertEqual([Helper countForEntity:@"Comment"
                              inContext:dataStack.mainContext], 1);
    NSArray *comments = [Helper fetchEntity:@"Comment"
                                predicate:[NSPredicate predicateWithFormat:@"body = %@", @"Hi"]
                                inContext:dataStack.mainContext];
    XCTAssertEqual(comments.count, 1);

    [dataStack drop];
}

/*
 When having JSONs like this:
 {
   "id":12345,
   "name":"My Project",
   "category_id":12345
 }

 It will should map category_id with the necesary category object using the ID 12345
*/
- (void)testIDRelationshipMapping {
    NSArray *usersDictionary = [Helper objectsFromJSON:@"users_a.json"];
    DATAStack *dataStack = [Helper dataStackWithModelName:@"Notes"];

    [Sync changes:usersDictionary
    inEntityNamed:@"SuperUser"
        dataStack:dataStack
       completion:nil];

    NSInteger usersCount = [Helper countForEntity:@"SuperUser" inContext:dataStack.mainContext];
    XCTAssertEqual(usersCount, 8);

    NSArray *notesDictionary = [Helper objectsFromJSON:@"notes_with_user_id.json"];

    [Sync changes:notesDictionary
    inEntityNamed:@"SuperNote"
        dataStack:dataStack
       completion:nil];

    NSInteger notesCount = [Helper countForEntity:@"SuperNote" inContext:dataStack.mainContext];
    XCTAssertEqual(notesCount, 5);

    NSArray *notes = [Helper fetchEntity:@"SuperNote"
                             predicate:[NSPredicate predicateWithFormat:@"remoteID = %@", @0]
                             inContext:dataStack.mainContext];
    NSManagedObject *note = notes.firstObject;
    NSManagedObject *user = [note valueForKey:@"superUser"];
    XCTAssertEqualObjects([user valueForKey:@"name"], @"Melisa White");

    [dataStack drop];
}

@end
