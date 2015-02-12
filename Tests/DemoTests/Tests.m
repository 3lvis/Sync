@import XCTest;

@import CoreData;

#import "Kipu.h"
#import "NSJSONSerialization+ANDYJSONFile.h"
#import "DATAStack.h"

@interface Tests : XCTestCase

@property (nonatomic, strong) DATAStack *dataStack;

@end

@implementation Tests

- (DATAStack *)dataStack
{
    if (_dataStack) return _dataStack;

    _dataStack = [[DATAStack alloc] initWithModelName:@"Model"
                                               bundle:[NSBundle bundleForClass:[self class]]
                                            storeType:DATAStackInMemoryStoreType];

    return _dataStack;
}

#pragma mark - Set up

- (void)tearDown
{
    [self.dataStack drop];
    self.dataStack = nil;

    [super tearDown];
}

#pragma mark - Tests

- (void)testLoadAndUpdateUsers
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Saving expectations"];

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"users_a.json" inBundle:bundle];

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];

    NSManagedObjectContext *mainContext = [self.dataStack mainContext];

    [Kipu processChanges:objects
         usingEntityName:@"User"
               predicate:nil
               dataStack:self.dataStack
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
                   dataStack:self.dataStack
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

            request.predicate = [NSPredicate predicateWithFormat:@"remoteID == %@", @7];
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
               dataStack:self.dataStack
              completion:^(NSError *error) {
                  NSManagedObjectContext *mainContext = [self.dataStack mainContext];

                  NSError *userError = nil;
                  NSFetchRequest *userRequest = [[NSFetchRequest alloc] initWithEntityName:@"User"];
                  NSInteger usersCount = [mainContext countForFetchRequest:userRequest error:&userError];
                  if (userError) NSLog(@"userError: %@", userError);
                  XCTAssertEqual(usersCount, 4);

                  NSError *userFetchError = nil;
                  userRequest.predicate = [NSPredicate predicateWithFormat:@"remoteID = %@", @6];
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

    [self.dataStack performInNewBackgroundContext:^(NSManagedObjectContext *backgroundContext) {
        NSManagedObject *user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                              inManagedObjectContext:backgroundContext];
        [user setValue:@6 forKey:@"remoteID"];
        [user setValue:@"Shawn Merrill" forKey:@"name"];
        [user setValue:@"firstupdate@ovium.com" forKey:@"email"];

        NSError *userError = nil;
        [backgroundContext save:&userError];
        if (userError) NSLog(@"userError: %@", userError);

        NSManagedObjectContext *mainContext = [self.dataStack mainContext];
        [mainContext performBlockAndWait:^{
            [self.dataStack persistWithCompletion:^{
                NSFetchRequest *userRequest = [[NSFetchRequest alloc] initWithEntityName:@"User"];
                userRequest.predicate = [NSPredicate predicateWithFormat:@"remoteID = %@", @6];
                NSArray *users = [mainContext executeFetchRequest:userRequest error:nil];
                if (users.count != 1) abort();

                [Kipu processChanges:objects
                     usingEntityName:@"Note"
                              parent:[users firstObject]
                           dataStack:self.dataStack
                          completion:^(NSError *error) {
                              NSManagedObjectContext *mainContext = [self.dataStack mainContext];

                              NSError *userFetchError = nil;
                              NSFetchRequest *userRequest = [[NSFetchRequest alloc] initWithEntityName:@"User"];
                              userRequest.predicate = [NSPredicate predicateWithFormat:@"remoteID = %@", @6];
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
               dataStack:self.dataStack
              completion:^(NSError *error) {
                  NSManagedObjectContext *mainContext = [self.dataStack mainContext];

                  NSError *notesError = nil;
                  NSFetchRequest *notesRequest = [[NSFetchRequest alloc] initWithEntityName:@"Note"];
                  NSInteger numberOfNotes = [mainContext countForFetchRequest:notesRequest error:&notesError];
                  if (notesError) NSLog(@"notesError: %@", notesError);
                  XCTAssertEqual(numberOfNotes, 5);

                  NSError *notesFetchError = nil;
                  notesRequest.predicate = [NSPredicate predicateWithFormat:@"remoteID = %@", @0];
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
                  tagsRequest.predicate = [NSPredicate predicateWithFormat:@"remoteID = %@", @1];
                  NSArray *tags = [mainContext executeFetchRequest:tagsRequest error:&tagsFetchError];
                  if (tagsFetchError) NSLog(@"tagsFetchError: %@", tagsFetchError);
                  NSManagedObject *tag = [tags firstObject];
                  XCTAssertEqual([[[tag valueForKey:@"notes"] allObjects] count], 4,
                                 @"Tag with ID 1 should have 4 notes");

                  [expectation fulfill];
              }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testUsersAndCompanies
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Saving expectations"];

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"users_company.json" inBundle:bundle];

    [Kipu processChanges:objects
         usingEntityName:@"User"
               predicate:nil
               dataStack:self.dataStack
              completion:^(NSError *error) {
                  NSManagedObjectContext *mainContext = [self.dataStack mainContext];

                  NSError *usersError = nil;
                  NSFetchRequest *usersRequest = [[NSFetchRequest alloc] initWithEntityName:@"User"];
                  NSInteger numberOfUsers = [mainContext countForFetchRequest:usersRequest error:&usersError];
                  if (usersError) NSLog(@"usersError: %@", usersError);
                  XCTAssertEqual(numberOfUsers, 5);

                  NSError *usersFetchError = nil;
                  usersRequest.predicate = [NSPredicate predicateWithFormat:@"remoteID = %@", @0];
                  NSArray *users = [mainContext executeFetchRequest:usersRequest error:&usersFetchError];
                  if (usersFetchError) NSLog(@"usersFetchError: %@", usersFetchError);
                  NSManagedObject *user = [users firstObject];
                  XCTAssertEqualObjects([[user valueForKey:@"company"] valueForKey:@"name"], @"Apple");

                  NSError *companiesError = nil;
                  NSFetchRequest *companiesRequest = [[NSFetchRequest alloc] initWithEntityName:@"Company"];
                  NSInteger numberOfCompanies = [mainContext countForFetchRequest:companiesRequest error:&companiesError];
                  if (companiesError) NSLog(@"companiesError: %@", companiesError);
                  XCTAssertEqual(numberOfCompanies, 2);

                  NSError *companiesFetchError = nil;
                  companiesRequest.predicate = [NSPredicate predicateWithFormat:@"remoteID = %@", @1];
                  NSArray *companies = [mainContext executeFetchRequest:companiesRequest error:&companiesFetchError];
                  if (companiesFetchError) NSLog(@"companiesFetchError: %@", companiesFetchError);
                  NSManagedObject *company = [companies firstObject];
                  XCTAssertEqualObjects([company valueForKey:@"name"], @"Facebook");

                  [expectation fulfill];
              }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

@end
