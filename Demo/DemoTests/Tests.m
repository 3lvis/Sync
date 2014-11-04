//
//  DemoTests.m
//  DemoTests
//
//  Created by Elvis Nunez on 5/16/14.
//  Copyright (c) 2014 Andy. All rights reserved.
//

@import XCTest;

@import CoreData;

#import "NSManagedObject+ANDYNetworking.h"
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

    [NSManagedObject andy_processChanges:objects
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

        [NSManagedObject andy_processChanges:objects
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
            XCTAssertEqualObjects([[results firstObject] valueForKey:@"email"], @"secondupdated@ovium.com");
        }];

    }];
}

- (void)testRelationships
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Saving expectations"];

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"users_notes.json" inBundle:bundle];

    NSManagedObjectContext *mainContext = [[ANDYDataManager sharedManager] mainContext];

    [NSManagedObject andy_processChanges:objects
                         usingEntityName:@"User"
                               predicate:nil
                              completion:^(NSError *error) {
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

@end
