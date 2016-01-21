@import XCTest;
@import DATAStack;
#import "Tests-Swift.h"
@import Sync;

@interface SyncTests : XCTestCase

@end

@implementation SyncTests

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
