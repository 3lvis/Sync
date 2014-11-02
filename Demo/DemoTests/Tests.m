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

- (void)testLoadFirstUsers
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Saving expectations"];

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"first.json" inBundle:bundle];

    [NSManagedObject andy_processChanges:objects
                         usingEntityName:@"User"
                                localKey:@"id"
                               remoteKey:@"id"
                               predicate:nil
                              completion:^{

                                  NSError *error = nil;
                                  NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];
                                  NSInteger count = [[[ANDYDataManager sharedManager] mainContext] countForFetchRequest:request error:&error];

                                  XCTAssertEqual(count, 13);

                                  [expectation fulfill];
                              }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

@end
