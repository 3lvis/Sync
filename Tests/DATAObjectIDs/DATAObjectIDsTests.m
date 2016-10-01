@import XCTest;

#import "Tests-Swift.h"
#import "User+CoreDataClass.h"
@import DATAStack;

@interface DATAObjectIDsTests : XCTestCase

@end

@implementation DATAObjectIDsTests

- (User *)insertUserWithRemoteID:(NSNumber *)remoteID
                         localID:(NSString *)localID
                            name:(NSString *)name
                       inContext:(NSManagedObjectContext *)context {
    User *user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                               inManagedObjectContext:context];
    user.remoteID = remoteID;
    user.localID = localID;
    user.name = name;

    return user;
}
- (void)configureUserWithRemoteID:(NSNumber *)remoteID
                          localID:(NSString *)localID
                             name:(NSString *)name
                            block:(void (^)(User *user, NSManagedObjectContext *context))block {
    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Tests"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackStoreTypeInMemory];

    [stack performInNewBackgroundContext:^(NSManagedObjectContext *context) {
        User *user = [self insertUserWithRemoteID:remoteID localID:localID name:name inContext:context];

        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"error saving: %@", error);
            abort();
        }

        if (block) {
            block (user, context);
        }
    }];

}

- (void)testDictionary {
    [self configureUserWithRemoteID:@1 localID:nil name:@"Joshua" block:^(User *user, NSManagedObjectContext *context) {
        NSDictionary *dictionary = [DATAObjectIDs objectIDsInEntityNamed:@"User"
                                                     withAttributesNamed:@"remoteID"
                                                                 context:context];
        XCTAssertNotNil(dictionary);
        XCTAssertTrue(dictionary.count == 1);
        XCTAssertEqualObjects(dictionary[@1], user.objectID);

        NSManagedObjectID *objectID = dictionary[@1];
        User *retreivedUser = (User *)[context objectWithID:objectID];
        XCTAssertEqualObjects(retreivedUser.remoteID, @1);
        XCTAssertEqualObjects(retreivedUser.name, @"Joshua");
    }];
}

- (void)testDictionaryStringLocalKey {
    [self configureUserWithRemoteID:nil localID:@"100" name:@"Joshua" block:^(User *user, NSManagedObjectContext *context) {
        NSDictionary *dictionary = [DATAObjectIDs objectIDsInEntityNamed:@"User"
                                                     withAttributesNamed:@"localID"
                                                                 context:context];
        XCTAssertNotNil(dictionary);
        XCTAssertTrue(dictionary.count == 1);
        XCTAssertEqualObjects(dictionary[@"100"], user.objectID);

        NSManagedObjectID *objectID = dictionary[@"100"];
        User *retreivedUser = (User *)[context objectWithID:objectID];
        XCTAssertEqualObjects(retreivedUser.localID, @"100");
        XCTAssertEqualObjects(retreivedUser.name, @"Joshua");
    }];
}

- (void)testObjectIDsArray {
    [self configureUserWithRemoteID:@1 localID:nil name:@"Joshua" block:^(User *user, NSManagedObjectContext *context) {
        NSArray *objectIDs = [DATAObjectIDs objectIDsInEntityNamed:@"User"
                                                           context:context];
        XCTAssertNotNil(objectIDs);
        XCTAssertEqual(objectIDs.count, 1);
        XCTAssertEqualObjects(objectIDs.firstObject, user.objectID);
    }];
}

- (void)testObjectIDsArrayWithPredicate {
    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Tests" bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackStoreTypeInMemory];

    [self insertUserWithRemoteID:@1 localID:nil name:@"Joshua" inContext:stack.mainContext];
    User *jon = [self insertUserWithRemoteID:@2 localID:nil name:@"Jon" inContext:stack.mainContext];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == 'Jon'"];
    NSArray *objectIDs = [DATAObjectIDs objectIDsInEntityNamed:@"User"
                                                       context:stack.mainContext
                                                     predicate:predicate];
    XCTAssertNotNil(objectIDs);
    XCTAssertEqual(objectIDs.count, 1);
    XCTAssertEqualObjects(objectIDs.firstObject, jon.objectID);
}

- (void)testDictionaryStringLocalKeyUsingSortDescriptor {
    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Tests" bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackStoreTypeInMemory];
    [stack performInNewBackgroundContext:^(NSManagedObjectContext *context) {
        [self insertUserWithRemoteID:nil localID:@"100" name:@"Joshua" inContext:context];
        [self insertUserWithRemoteID:nil localID:@"200" name:@"Jon" inContext:context];
        [context save:nil];

        NSArray *attributesA = [DATAObjectIDs attributesInEntityNamed:@"User"
                                                        attributeName:@"localID"
                                                              context:context
                                                      sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"localID" ascending:YES]]];
        XCTAssertEqualObjects(attributesA.firstObject, @"100");

        NSArray *attributesB = [DATAObjectIDs attributesInEntityNamed:@"User"
                                                        attributeName:@"localID"
                                                              context:context
                                                      sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"localID" ascending:NO]]];
        XCTAssertEqualObjects(attributesB.firstObject, @"200");
    }];
}

@end
