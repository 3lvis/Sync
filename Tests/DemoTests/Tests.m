//
//  DemoTests.m
//  DemoTests
//
//  Created by Elvis Nunez on 5/16/14.
//  Copyright (c) 2014 Andy. All rights reserved.
//

@import XCTest;

@import CoreData;

#import "Kipu.h"
#import "NSJSONSerialization+ANDYJSONFile.h"
#import "ANDYDataManager.h"

@interface Tests : XCTestCase

@end

@implementation Tests

#pragma mark - Set up

- (void)setUp
{
    [super setUp];

    [ANDYDataManager setModelName:@"Model"];

    [ANDYDataManager setModelBundle:[NSBundle bundleForClass:[self class]]];

    [ANDYDataManager setUpStackWithInMemoryStore];
}

- (void)tearDown
{
    [[ANDYDataManager sharedManager] destroy];

    [super tearDown];
}

#pragma mark - Tests

- (void)testLoadAndUpdateUsers
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Saving expectations"];

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"users_a.json" inBundle:bundle];

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];

    NSManagedObjectContext *mainContext = [[ANDYDataManager sharedManager] mainContext];

    [Kipu processChanges:objects
         usingEntityName:@"User"
               predicate:nil
              completion:^(NSError *error) {
                  NSError *countError = nil;
                  NSInteger count = [mainContext countForFetchRequest:request error:&countError];
                  if (countError) NSLog(@"countError: %@", [countError description]);
                  XCTAssertEqual(count, 8);

                  [expectation fulfill];
              }];

    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {

        if (error) {
            NSLog(@"error loading users: %@", error);
            return;
        }

        XCTestExpectation *expectation = [self expectationWithDescription:@"Saving expectations"];

        NSBundle *bundle = [NSBundle bundleForClass:[self class]];

        NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"users_b.json" inBundle:bundle];

        [Kipu processChanges:objects
             usingEntityName:@"User"
                   predicate:nil
                  completion:^(NSError *error) {
                      NSError *countError = nil;
                      NSInteger count = [mainContext countForFetchRequest:request error:&countError];
                      if (countError) NSLog(@"countError: %@", [countError description]);
                      XCTAssertEqual(count, 6);

                      [expectation fulfill];
                  }];

        [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {

            if (error) {
                NSLog(@"error loading users: %@", error);
                return;
            }

            request.predicate = [NSPredicate predicateWithFormat:@"userID == %@", @7];
            NSArray *results = [mainContext executeFetchRequest:request error:nil];
            NSManagedObject *result = [results firstObject];
            XCTAssertEqualObjects([result valueForKey:@"email"], @"secondupdated@ovium.com");

            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            dateFormat.dateFormat = @"yyyy-MM-dd";
            dateFormat.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];

            NSDate *createdDate = [dateFormat dateFromString:@"2014-02-14"];
            XCTAssertEqualObjects([result valueForKey:@"createdDate"], createdDate);

            NSDate *updatedDate = [dateFormat dateFromString:@"2014-02-17"];
            XCTAssertEqualObjects([result valueForKey:@"updatedDate"], updatedDate);
        }];

    }];
}

- (void)testRelationships
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Saving expectations"];

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"users_notes.json" inBundle:bundle];

    [Kipu processChanges:objects
         usingEntityName:@"User"
               predicate:nil
              completion:^(NSError *error) {
                  NSManagedObjectContext *mainContext = [[ANDYDataManager sharedManager] mainContext];

                  NSError *userError = nil;
                  NSFetchRequest *userRequest = [[NSFetchRequest alloc] initWithEntityName:@"User"];
                  NSInteger usersCount = [mainContext countForFetchRequest:userRequest error:&userError];
                  if (userError) NSLog(@"userError: %@", userError);
                  XCTAssertEqual(usersCount, 4);

                  NSError *userFetchError = nil;
                  userRequest.predicate = [NSPredicate predicateWithFormat:@"userID = %@", @6];
                  NSArray *users = [mainContext executeFetchRequest:userRequest error:&userFetchError];
                  if (userFetchError) NSLog(@"userFetchError: %@", userFetchError);
                  NSManagedObject *user = [users firstObject];
                  XCTAssertEqualObjects([user valueForKey:@"name"], @"Shawn Merrill");

                  NSError *notesError = nil;
                  NSFetchRequest *noteRequest = [[NSFetchRequest alloc] initWithEntityName:@"Note"];
                  noteRequest.predicate = [NSPredicate predicateWithFormat:@"user = %@", user];
                  NSInteger notesCount = [mainContext countForFetchRequest:noteRequest error:&notesError];
                  if (notesError) NSLog(@"notesError: %@", notesError);
                  XCTAssertEqual(notesCount, 5);

                  [expectation fulfill];
              }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testObjectsForParent
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Saving expectations"];

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"notes_for_user_a.json" inBundle:bundle];

    NSManagedObjectContext *background = [ANDYDataManager backgroundContext];
    [background performBlock:^{

        NSManagedObject *user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                              inManagedObjectContext:background];
        [user setValue:@6 forKey:@"userID"];
        [user setValue:@"Shawn Merrill" forKey:@"name"];
        [user setValue:@"firstupdate@ovium.com" forKey:@"email"];

        NSError *userError = nil;
        [background save:&userError];
        if (userError) NSLog(@"userError: %@", userError);

        NSManagedObjectContext *mainContext = [[ANDYDataManager sharedManager] mainContext];
        [mainContext performBlockAndWait:^{
            [[ANDYDataManager sharedManager] persistContext];

            NSFetchRequest *userRequest = [[NSFetchRequest alloc] initWithEntityName:@"User"];
            userRequest.predicate = [NSPredicate predicateWithFormat:@"userID = %@", @6];
            NSArray *users = [mainContext executeFetchRequest:userRequest error:nil];
            if (users.count != 1) abort();

            [Kipu processChanges:objects
                 usingEntityName:@"Note"
                          parent:[users firstObject]
                      completion:^(NSError *error) {
                          NSManagedObjectContext *mainContext = [[ANDYDataManager sharedManager] mainContext];

                          NSError *userFetchError = nil;
                          NSFetchRequest *userRequest = [[NSFetchRequest alloc] initWithEntityName:@"User"];
                          userRequest.predicate = [NSPredicate predicateWithFormat:@"userID = %@", @6];
                          NSArray *users = [mainContext executeFetchRequest:userRequest error:&userFetchError];
                          if (userFetchError) NSLog(@"userFetchError: %@", userFetchError);
                          NSManagedObject *user = [users firstObject];
                          XCTAssertEqualObjects([user valueForKey:@"name"], @"Shawn Merrill");

                          NSError *notesError = nil;
                          NSFetchRequest *noteRequest = [[NSFetchRequest alloc] initWithEntityName:@"Note"];
                          noteRequest.predicate = [NSPredicate predicateWithFormat:@"user = %@", user];
                          NSInteger notesCount = [mainContext countForFetchRequest:noteRequest error:&notesError];
                          if (notesError) NSLog(@"notesError: %@", notesError);
                          XCTAssertEqual(notesCount, 5);

                          [expectation fulfill];
                      }];
        }];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testTaggedNotesForUser
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Saving expectations"];

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"tagged_notes.json" inBundle:bundle];

    [Kipu processChanges:objects
         usingEntityName:@"Note"
               predicate:nil
              completion:^(NSError *error) {
                  NSManagedObjectContext *mainContext = [[ANDYDataManager sharedManager] mainContext];

                  NSError *notesError = nil;
                  NSFetchRequest *notesRequest = [[NSFetchRequest alloc] initWithEntityName:@"Note"];
                  NSInteger numberOfNotes = [mainContext countForFetchRequest:notesRequest error:&notesError];
                  if (notesError) NSLog(@"notesError: %@", notesError);
                  XCTAssertEqual(numberOfNotes, 5);

                  NSError *notesFetchError = nil;
                  notesRequest.predicate = [NSPredicate predicateWithFormat:@"noteID = %@", @0];
                  NSArray *notes = [mainContext executeFetchRequest:notesRequest error:&notesFetchError];
                  if (notesFetchError) NSLog(@"notesFetchError: %@", notesFetchError);
                  NSManagedObject *note = [notes firstObject];
                  XCTAssertEqual([[[note valueForKey:@"tags"] allObjects] count], 2,
                                 @"Note with ID 0 should have 2 tags");

                  NSError *tagsError = nil;
                  NSFetchRequest *tagsRequest = [[NSFetchRequest alloc] initWithEntityName:@"Tag"];
                  NSInteger numberOfTags = [mainContext countForFetchRequest:tagsRequest error:&tagsError];
                  if (tagsError) NSLog(@"tagsError: %@", tagsError);
                  XCTAssertEqual(numberOfTags, 2);

                  NSError *tagsFetchError = nil;
                  tagsRequest.predicate = [NSPredicate predicateWithFormat:@"tagID = %@", @1];
                  NSArray *tags = [mainContext executeFetchRequest:tagsRequest error:&tagsFetchError];
                  if (tagsFetchError) NSLog(@"tagsFetchError: %@", tagsFetchError);
                  NSManagedObject *tag = [tags firstObject];
                  XCTAssertEqual([[[tag valueForKey:@"notes"] allObjects] count], 4,
                                 @"Tag with ID 1 should have 4 notes");

                  [expectation fulfill];
              }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];

}

@end
