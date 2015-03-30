@import XCTest;

@import CoreData;

#import "Sync.h"
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
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSArray *objectsA = [NSJSONSerialization JSONObjectWithContentsOfFile:@"users_a.json" inBundle:bundle];

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];

    NSManagedObjectContext *mainContext = [self.dataStack mainContext];

    [Sync processChanges:objectsA
         usingEntityName:@"User"
               predicate:nil
               dataStack:self.dataStack
              completion:^(NSError *error) {
                  NSError *countError = nil;
                  NSInteger count = [mainContext countForFetchRequest:request error:&countError];
                  if (countError) NSLog(@"countError: %@", [countError description]);
                  XCTAssertEqual(count, 8);
              }];

    NSArray *objectsB = [NSJSONSerialization JSONObjectWithContentsOfFile:@"users_b.json" inBundle:bundle];

    [Sync processChanges:objectsB
         usingEntityName:@"User"
               predicate:nil
               dataStack:self.dataStack
              completion:^(NSError *error) {
                  NSError *countError = nil;
                  NSInteger count = [mainContext countForFetchRequest:request error:&countError];
                  if (countError) NSLog(@"countError: %@", [countError description]);
                  XCTAssertEqual(count, 6);
              }];

    request.predicate = [NSPredicate predicateWithFormat:@"remoteID == %@", @7];
    NSArray *results = [mainContext executeFetchRequest:request error:nil];
    NSManagedObject *result = [results firstObject];
    XCTAssertEqualObjects([result valueForKey:@"email"], @"secondupdated@ovium.com");

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.dateFormat = @"yyyy-MM-dd";
    dateFormat.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];

    NSDate *createdDate = [dateFormat dateFromString:@"2014-02-14"];
    XCTAssertEqualObjects([result valueForKey:@"createdAt"], createdDate);

    NSDate *updatedDate = [dateFormat dateFromString:@"2014-02-17"];
    XCTAssertEqualObjects([result valueForKey:@"updatedAt"], updatedDate);
}

- (void)testRelationships
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"users_notes.json" inBundle:bundle];

    [Sync processChanges:objects
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
              }];
}

- (void)testObjectsForParent
{
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

                [Sync processChanges:objects
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
                          }];
            }];
        }];
    }];
}

- (void)testTaggedNotesForUser
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"tagged_notes.json" inBundle:bundle];

    [Sync processChanges:objects
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
              }];
}

- (void)testUsersAndCompanies
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"users_company.json" inBundle:bundle];

    [Sync processChanges:objects
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
              }];
}

/**
 * How to test numbers:
 * - Because of to-one collection relationship, sync is failing when parsing children objects
 */
- (void)testNumbersWithEmptyRelationship
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"numbers.json" inBundle:bundle];
    [Sync processChanges:objects
         usingEntityName:@"Number"
               predicate:nil
               dataStack:self.dataStack
              completion:^(NSError *error) {
                  NSManagedObjectContext *mainContext = [self.dataStack mainContext];

                  NSInteger numberCount =[self countAllEntities:@"Number" inContext:mainContext];
                  XCTAssertEqual(numberCount, 6);
              }];
}

- (NSInteger)countAllEntities:(NSString *)entity inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:entity];
    return [context countForFetchRequest:fetch error:nil];
}

- (void)testRelationshipName
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"numbers_in_collection.json" inBundle:bundle];
    [Sync processChanges:objects
         usingEntityName:@"Number"
               dataStack:self.dataStack
              completion:^(NSError *error) {
                  NSManagedObjectContext *mainContext = [self.dataStack mainContext];

                  NSInteger collectioCount =[self countAllEntities:@"Collection" inContext:mainContext];
                  XCTAssertEqual(collectioCount, 1);

                  NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Number"];
                  NSManagedObject *number = [[mainContext executeFetchRequest:request error:nil] firstObject];
                  XCTAssertNotNil([number valueForKey:@"parent"]);
                  XCTAssertEqualObjects([[number valueForKey:@"parent"]  valueForKey:@"name"], @"Collection 1");
              }];
}

- (void)testCustomPrimaryKey
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"comments-no-id.json"
                                                                inBundle:bundle];
    [Sync processChanges:objects
         usingEntityName:@"Comment"
               dataStack:self.dataStack
              completion:^(NSError *error) {
                  NSManagedObjectContext *mainContext = [self.dataStack mainContext];

                  NSError *commentsError = nil;
                  NSFetchRequest *commentsRequest = [[NSFetchRequest alloc] initWithEntityName:@"Comment"];
                  NSInteger numberOfComments = [mainContext countForFetchRequest:commentsRequest error:&commentsError];
                  if (commentsError) NSLog(@"commentsError: %@", commentsError);
                  XCTAssertEqual(numberOfComments, 8);

                  NSError *commentsFetchError = nil;
                  commentsRequest.predicate = [NSPredicate predicateWithFormat:@"body = %@", @"comment 1"];
                  NSArray *comments = [mainContext executeFetchRequest:commentsRequest error:&commentsFetchError];
                  if (commentsFetchError) NSLog(@"commentsFetchError: %@", commentsFetchError);
                  NSManagedObject *comment = [comments firstObject];
                  XCTAssertEqualObjects([comment valueForKey:@"body"], @"comment 1");
              }];
}

- (void)testCustomPrimaryKeyInsideToManyRelationship
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSArray *objects = [NSJSONSerialization JSONObjectWithContentsOfFile:@"stories-comments-no-ids.json"
                                                                inBundle:bundle];
    [Sync processChanges:objects
         usingEntityName:@"Story"
               dataStack:self.dataStack
              completion:^(NSError *error) {
                  NSManagedObjectContext *mainContext = [self.dataStack mainContext];

                  NSError *storiesError = nil;
                  NSFetchRequest *storiesRequest = [[NSFetchRequest alloc] initWithEntityName:@"Story"];
                  NSInteger numberOfStories = [mainContext countForFetchRequest:storiesRequest error:&storiesError];
                  if (storiesError) NSLog(@"storiesError: %@", storiesError);
                  XCTAssertEqual(numberOfStories, 3);

                  NSError *storiesFetchError = nil;
                  storiesRequest.predicate = [NSPredicate predicateWithFormat:@"remoteID = %@", @0];
                  NSArray *stories = [mainContext executeFetchRequest:storiesRequest error:&storiesFetchError];
                  if (storiesFetchError) NSLog(@"storiesFetchError: %@", storiesFetchError);
                  NSManagedObject *story = [stories firstObject];
                  XCTAssertEqual([[story valueForKey:@"comments"] count], 3);

                  NSError *commentsError = nil;
                  NSFetchRequest *commentsRequest = [[NSFetchRequest alloc] initWithEntityName:@"Comment"];
                  NSInteger numberOfComments = [mainContext countForFetchRequest:commentsRequest error:&commentsError];
                  if (commentsError) NSLog(@"commentsError: %@", commentsError);
                  XCTAssertEqual(numberOfComments, 9);

                  NSError *commentsFetchError = nil;
                  commentsRequest.predicate = [NSPredicate predicateWithFormat:@"body = %@", @"comment 1"];
                  NSArray *comments = [mainContext executeFetchRequest:commentsRequest error:&commentsFetchError];
                  if (commentsFetchError) NSLog(@"commentsFetchError: %@", commentsFetchError);
                  NSManagedObject *comment = [comments firstObject];
                  XCTAssertEqualObjects([comment valueForKey:@"body"], @"comment 1");
              }];
}

@end
