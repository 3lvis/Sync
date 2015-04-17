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

- (NSArray *)arrayWithObjectsFromJSON:(NSString *)stringJSON
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSArray *array = [NSJSONSerialization JSONObjectWithContentsOfFile:stringJSON inBundle:bundle];

    return array;
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
    NSArray *objectsA = [self arrayWithObjectsFromJSON:@"users_a.json"];

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];

    NSManagedObjectContext *mainContext = [self.dataStack mainContext];

    [Sync changes:objectsA
    inEntityNamed:@"User"
        predicate:nil
        dataStack:self.dataStack
       completion:^(NSError *error) {
           NSError *countError = nil;
           NSInteger count = [mainContext countForFetchRequest:request error:&countError];
           if (countError) NSLog(@"countError: %@", [countError description]);
           XCTAssertEqual(count, 8);
       }];

    NSArray *objectsB = [self arrayWithObjectsFromJSON:@"users_b.json"];

    [Sync changes:objectsB
    inEntityNamed:@"User"
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
    NSArray *objects = [self arrayWithObjectsFromJSON:@"users_notes.json"];

    [Sync changes:objects
    inEntityNamed:@"User"
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
         
           NSError *profilePicturesError = nil;
           NSFetchRequest *profilePictureRequest = [[NSFetchRequest alloc] initWithEntityName:@"Image"];
           profilePictureRequest.predicate = [NSPredicate predicateWithFormat:@"user = %@", user];
           NSInteger profilePicturesCount = [mainContext countForFetchRequest:profilePictureRequest error:&profilePicturesError];
           if (profilePicturesError) NSLog(@"profilePicturesError: %@", profilePicturesError);
           XCTAssertEqual(profilePicturesCount, 3);
       }];
}

- (void)testObjectsForParent
{
    NSArray *objects = [self arrayWithObjectsFromJSON:@"notes_for_user_a.json"];

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

                [Sync changes:objects
                inEntityNamed:@"Note"
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
    NSArray *objects = [self arrayWithObjectsFromJSON:@"tagged_notes.json"];

    [Sync changes:objects
    inEntityNamed:@"Note"
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
    NSArray *objects = [self arrayWithObjectsFromJSON:@"users_company.json"];

    [Sync changes:objects
    inEntityNamed:@"User"
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
    NSArray *objects = [self arrayWithObjectsFromJSON:@"numbers.json"];

    [Sync changes:objects
    inEntityNamed:@"Number"
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
    NSArray *objects = [self arrayWithObjectsFromJSON:@"numbers_in_collection.json"];

    [Sync changes:objects
    inEntityNamed:@"Number"
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
    NSArray *objects = [self arrayWithObjectsFromJSON:@"comments-no-id.json"];

    [Sync changes:objects
    inEntityNamed:@"Comment"
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
    NSArray *objects = [self arrayWithObjectsFromJSON:@"stories-comments-no-ids.json"];

    [Sync changes:objects
    inEntityNamed:@"Story"
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

- (void)testCustomKeysInRelationshipsToMany
{
    NSArray *objects = [self arrayWithObjectsFromJSON:@"custom_relationship_key_to_many.json"];

    [Sync changes:objects
    inEntityNamed:@"User"
        dataStack:self.dataStack
       completion:^(NSError *error) {
           NSManagedObjectContext *mainContext = [self.dataStack mainContext];

           NSError *userError = nil;
           NSFetchRequest *userRequest = [[NSFetchRequest alloc] initWithEntityName:@"User"];
           NSArray *array = [mainContext executeFetchRequest:userRequest error:&userError];
           NSManagedObject *user = [array firstObject];
           XCTAssertEqual([[user valueForKey:@"notes"] count], 3);
       }];
}

- (void)testCustomKeysInRelationshipsToOne
{
    NSArray *objects = [self arrayWithObjectsFromJSON:@"custom_relationship_key_to_one.json"];

    [Sync changes:objects
    inEntityNamed:@"Story"
        dataStack:self.dataStack
       completion:^(NSError *error) {
           NSManagedObjectContext *mainContext = [self.dataStack mainContext];

           NSError *storyError = nil;
           NSFetchRequest *storyRequest = [[NSFetchRequest alloc] initWithEntityName:@"Story"];
           NSArray *array = [mainContext executeFetchRequest:storyRequest error:&storyError];
           NSManagedObject *story = [array firstObject];
           XCTAssertNotNil([story valueForKey:@"summarize"]);
       }];
}

- (void)testCustomMappingAndCustomPrimaryKey
{
    NSArray *objects = [self arrayWithObjectsFromJSON:@"images.json"];

    [Sync changes:objects
    inEntityNamed:@"Image"
        dataStack:self.dataStack
       completion:^(NSError *error) {
           NSManagedObjectContext *mainContext = [self.dataStack mainContext];

           NSError *imagesError = nil;
           NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Image"];
           request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"url" ascending:YES]];
           NSArray *array = [mainContext executeFetchRequest:request error:&imagesError];
           XCTAssertEqual(array.count, 3);
           NSManagedObject *image = [array firstObject];
           XCTAssertEqualObjects([image valueForKey:@"url"], @"http://sample.com/sample0.png");
       }];
}

@end
