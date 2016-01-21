@import XCTest;
@import DATAStack;
#import "Tests-Swift.h"
@import Sync;

@interface SyncTests : XCTestCase

@end

@implementation SyncTests

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
