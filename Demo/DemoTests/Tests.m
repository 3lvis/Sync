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

+ (void)setUp
{
    [super setUp];

    [ANDYDataManager setModelName:@"Model"];

    [ANDYDataManager setModelBundle:[NSBundle bundleForClass:[self class]]];

    [ANDYDataManager setUpStackWithInMemoryStore];
}

#pragma mark - Tests

- (void)testLoadAndUpdateUsers
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Saving expectations"];

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"first.json" inBundle:bundle];

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];

    NSManagedObjectContext *mainContext = [[ANDYDataManager sharedManager] mainContext];

    [NSManagedObject andy_processChanges:objects
                         usingEntityName:@"User"
                                localKey:@"id"
                               remoteKey:@"id"
                               predicate:nil
                              completion:^{

                                  NSError *error = nil;
                                  NSInteger count = [mainContext countForFetchRequest:request error:&error];

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

        NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"second.json" inBundle:bundle];

        [NSManagedObject andy_processChanges:objects
                             usingEntityName:@"User"
                                    localKey:@"id"
                                   remoteKey:@"id"
                                   predicate:nil
                                  completion:^{

                                      NSError *error = nil;
                                      NSInteger count = [mainContext countForFetchRequest:request error:&error];

                                      XCTAssertEqual(count, 6);

                                      [expectation fulfill];
                                  }];

        [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {

            if (error) {
                NSLog(@"error loading users: %@", error);
                return;
            }

            request.predicate = [NSPredicate predicateWithFormat:@"id == %@", @7];
            NSArray *results = [mainContext executeFetchRequest:request error:nil];
            XCTAssertEqualObjects([[results firstObject] valueForKey:@"email"], @"secondupdated@ovium.com");
        }];

    }];
}

@end
