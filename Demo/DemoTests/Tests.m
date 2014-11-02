//
//  DemoTests.m
//  DemoTests
//
//  Created by Elvis Nunez on 5/16/14.
//  Copyright (c) 2014 Andy. All rights reserved.
//

@import XCTest;

@import CoreData;

@interface DemoTests : XCTestCase

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation DemoTests

#pragma mark - Set up

- (NSManagedObjectContext *)context
{
    if (_context) return _context;

    NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSPersistentStore *store = [psc addPersistentStoreWithType:NSInMemoryStoreType
                                                 configuration:nil
                                                           URL:nil
                                                       options:nil
                                                         error:nil];
    NSAssert(store, @"Should have a store by now");

    _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _context.persistentStoreCoordinator = psc;

    return _context;
}

- (void)setUp
{
    [super setUp];

    [self.context save:nil];
}

- (void)tearDown
{
    [self.context rollback];

    [super tearDown];
}

#pragma mark - Tests

- (void)testSample
{
    XCTAssert(@"YES!");
}

@end
