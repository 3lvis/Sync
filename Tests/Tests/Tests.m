@import XCTest;

@import CoreData;

#import "Sync.h"
#import "NSJSONSerialization+ANDYJSONFile.h"
#import "DATAStack.h"

@interface Tests : XCTestCase

@end

@implementation Tests

#pragma mark - Helpers

- (DATAStack *)dataStackWithModelName:(NSString *)modelName
{
    DATAStack *dataStack = [[DATAStack alloc] initWithModelName:modelName
                                                         bundle:[NSBundle bundleForClass:[self class]]
                                                      storeType:DATAStackInMemoryStoreType];

    return dataStack;
}

- (NSArray *)objectsFromJSON:(NSString *)fileName
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSArray *array = [NSJSONSerialization JSONObjectWithContentsOfFile:fileName inBundle:bundle];

    return array;
}

#pragma mark - Tests

#pragma mark Contacts

- (void)testLoadAndUpdateUsers
{
    NSArray *objectsA = [self objectsFromJSON:@"users_a.json"];

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];

    DATAStack *dataStack = [self dataStackWithModelName:@"Contacts"];
    NSManagedObjectContext *mainContext = [dataStack mainContext];

    [Sync changes:objectsA
    inEntityNamed:@"User"
        dataStack:dataStack
       completion:^(NSError *error) {
           NSError *countError = nil;
           NSInteger count = [mainContext countForFetchRequest:request error:&countError];
           if (countError) NSLog(@"countError: %@", [countError description]);
           XCTAssertEqual(count, 8);
       }];

    NSArray *objectsB = [self objectsFromJSON:@"users_b.json"];

    [Sync changes:objectsB
    inEntityNamed:@"User"
        dataStack:dataStack
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

- (void)testUsersAndCompanies
{
    NSArray *objects = [self objectsFromJSON:@"users_company.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Contacts"];

    [Sync changes:objects
    inEntityNamed:@"User"
        dataStack:dataStack
       completion:^(NSError *error) {
           NSManagedObjectContext *mainContext = [dataStack mainContext];

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

- (void)testCustomMappingAndCustomPrimaryKey
{
    NSArray *objects = [self objectsFromJSON:@"images.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Contacts"];

    [Sync changes:objects
    inEntityNamed:@"Image"
        dataStack:dataStack
       completion:^(NSError *error) {
           NSManagedObjectContext *mainContext = [dataStack mainContext];

           NSError *imagesError = nil;
           NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Image"];
           request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"url" ascending:YES]];
           NSArray *array = [mainContext executeFetchRequest:request error:&imagesError];
           XCTAssertEqual(array.count, 3);
           NSManagedObject *image = [array firstObject];
           XCTAssertEqualObjects([image valueForKey:@"url"], @"http://sample.com/sample0.png");
       }];
}

- (void)testRelationshipsB
{
    NSArray *objects = [self objectsFromJSON:@"users_c.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Contacts"];

    [Sync changes:objects
    inEntityNamed:@"User"
        dataStack:dataStack
       completion:^(NSError *error) {
           NSManagedObjectContext *mainContext = [dataStack mainContext];

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

           NSManagedObject *location = [user valueForKey:@"location"];
           XCTAssertTrue([[location valueForKey:@"city"] isEqualToString:@"New York"]);
           XCTAssertTrue([[location valueForKey:@"street"] isEqualToString:@"Broadway"]);
           XCTAssertEqualObjects([location valueForKey:@"zipCode"], @10012);

           NSError *profilePicturesError = nil;
           NSFetchRequest *profilePictureRequest = [[NSFetchRequest alloc] initWithEntityName:@"Image"];
           profilePictureRequest.predicate = [NSPredicate predicateWithFormat:@"user = %@", user];
           NSInteger profilePicturesCount = [mainContext countForFetchRequest:profilePictureRequest error:&profilePicturesError];
           if (profilePicturesError) NSLog(@"profilePicturesError: %@", profilePicturesError);
           XCTAssertEqual(profilePicturesCount, 3);
       }];
}

#pragma mark Notes

- (void)testRelationshipsA
{
    NSArray *objects = [self objectsFromJSON:@"users_notes.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Notes"];

    [Sync changes:objects
    inEntityNamed:@"User"
        dataStack:dataStack
       completion:^(NSError *error) {
           NSManagedObjectContext *mainContext = [dataStack mainContext];

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
    NSArray *objects = [self objectsFromJSON:@"notes_for_user_a.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Notes"];

    [dataStack performInNewBackgroundContext:^(NSManagedObjectContext *backgroundContext) {
        NSManagedObject *user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                              inManagedObjectContext:backgroundContext];
        [user setValue:@6 forKey:@"remoteID"];
        [user setValue:@"Shawn Merrill" forKey:@"name"];
        [user setValue:@"firstupdate@ovium.com" forKey:@"email"];

        NSError *userError = nil;
        [backgroundContext save:&userError];
        if (userError) NSLog(@"userError: %@", userError);

        NSManagedObjectContext *mainContext = [dataStack mainContext];
        [mainContext performBlockAndWait:^{
            [dataStack persistWithCompletion:^{
                NSFetchRequest *userRequest = [[NSFetchRequest alloc] initWithEntityName:@"User"];
                userRequest.predicate = [NSPredicate predicateWithFormat:@"remoteID = %@", @6];
                NSArray *users = [mainContext executeFetchRequest:userRequest error:nil];
                if (users.count != 1) abort();

                [Sync changes:objects
                inEntityNamed:@"Note"
                       parent:[users firstObject]
                    dataStack:dataStack
                   completion:^(NSError *error) {
                       NSManagedObjectContext *mainContext = [dataStack mainContext];

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
    NSArray *objects = [self objectsFromJSON:@"tagged_notes.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Notes"];

    [Sync changes:objects
    inEntityNamed:@"Note"
        dataStack:dataStack
       completion:^(NSError *error) {
           NSManagedObjectContext *mainContext = [dataStack mainContext];

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

- (void)testCustomKeysInRelationshipsToMany
{
    NSArray *objects = [self objectsFromJSON:@"custom_relationship_key_to_many.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Notes"];

    [Sync changes:objects
    inEntityNamed:@"User"
        dataStack:dataStack
       completion:^(NSError *error) {
           NSManagedObjectContext *mainContext = [dataStack mainContext];

           NSError *userError = nil;
           NSFetchRequest *userRequest = [[NSFetchRequest alloc] initWithEntityName:@"User"];
           NSArray *array = [mainContext executeFetchRequest:userRequest error:&userError];
           NSManagedObject *user = [array firstObject];
           XCTAssertEqual([[user valueForKey:@"notes"] count], 3);
       }];
}

#pragma mark Recursive

/**
 * How to test numbers:
 * - Because of to-one collection relationship, sync is failing when parsing children objects
 */
- (void)testNumbersWithEmptyRelationship
{
    NSArray *objects = [self objectsFromJSON:@"numbers.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Recursive"];

    [Sync changes:objects
    inEntityNamed:@"Number"
        dataStack:dataStack
       completion:^(NSError *error) {
           NSManagedObjectContext *mainContext = [dataStack mainContext];

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
    NSArray *objects = [self objectsFromJSON:@"numbers_in_collection.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Recursive"];

    [Sync changes:objects
    inEntityNamed:@"Number"
        dataStack:dataStack
       completion:^(NSError *error) {
           NSManagedObjectContext *mainContext = [dataStack mainContext];

           NSInteger collectioCount =[self countAllEntities:@"Collection" inContext:mainContext];
           XCTAssertEqual(collectioCount, 1);

           NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Number"];
           NSManagedObject *number = [[mainContext executeFetchRequest:request error:nil] firstObject];
           XCTAssertNotNil([number valueForKey:@"parent"]);
           XCTAssertEqualObjects([[number valueForKey:@"parent"]  valueForKey:@"name"], @"Collection 1");
       }];
}

#pragma mark Social

- (void)testCustomPrimaryKey
{
    NSArray *objects = [self objectsFromJSON:@"comments-no-id.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Social"];

    [Sync changes:objects
    inEntityNamed:@"Comment"
        dataStack:dataStack
       completion:^(NSError *error) {
           NSManagedObjectContext *mainContext = [dataStack mainContext];

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
    NSArray *objects = [self objectsFromJSON:@"stories-comments-no-ids.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Social"];

    [Sync changes:objects
    inEntityNamed:@"Story"
        dataStack:dataStack
       completion:^(NSError *error) {
           NSManagedObjectContext *mainContext = [dataStack mainContext];

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

- (void)testCustomKeysInRelationshipsToOne
{
    NSArray *objects = [self objectsFromJSON:@"custom_relationship_key_to_one.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Social"];

    [Sync changes:objects
    inEntityNamed:@"Story"
        dataStack:dataStack
       completion:^(NSError *error) {
           NSManagedObjectContext *mainContext = [dataStack mainContext];

           NSError *storyError = nil;
           NSFetchRequest *storyRequest = [[NSFetchRequest alloc] initWithEntityName:@"Story"];
           NSArray *array = [mainContext executeFetchRequest:storyRequest error:&storyError];
           NSManagedObject *story = [array firstObject];
           XCTAssertNotNil([story valueForKey:@"summarize"]);
       }];
}

#pragma mark Markets

- (void)testMarketsAndItems
{
    NSArray *objects = [self objectsFromJSON:@"markets_items.json"];
    DATAStack *dataStack = [self dataStackWithModelName:@"Markets"];

    [Sync changes:objects
    inEntityNamed:@"Market"
        dataStack:dataStack
       completion:^(NSError *error) {
           NSManagedObjectContext *mainContext = [dataStack mainContext];

           NSError *marketsError = nil;
           NSFetchRequest *marketsRequest = [[NSFetchRequest alloc] initWithEntityName:@"Market"];
           NSInteger numberOfMarkets = [mainContext countForFetchRequest:marketsRequest error:&marketsError];
           if (marketsError) NSLog(@"marketsError: %@", marketsError);
           XCTAssertEqual(numberOfMarkets, 2);

           NSError *marketsFetchError = nil;
           //marketsRequest.predicate = [NSPredicate predicateWithFormat:@"uniqueId = %@", @"1"];
           NSArray *markets = [mainContext executeFetchRequest:marketsRequest error:&marketsFetchError];
           if (marketsFetchError) NSLog(@"marketsFetchError: %@", marketsFetchError);
           NSManagedObject *market = [markets firstObject];
           XCTAssertEqual([[[market valueForKey:@"items"] allObjects] count], 2);

           NSError *itemsError = nil;
           NSFetchRequest *itemsRequest = [[NSFetchRequest alloc] initWithEntityName:@"Item"];
           NSInteger numberOfItems = [mainContext countForFetchRequest:itemsRequest error:&itemsError];
           if (itemsError) NSLog(@"itemsError: %@", itemsError);
           XCTAssertEqual(numberOfItems, 2);

           NSError *itemsFetchError = nil;
           itemsRequest.predicate = [NSPredicate predicateWithFormat:@"uniqueId = %@", @"1"];
           NSArray *tags = [mainContext executeFetchRequest:itemsRequest error:&itemsFetchError];
           if (itemsFetchError) NSLog(@"itemsFetchError: %@", itemsFetchError);
           NSManagedObject *tag = [tags firstObject];
           XCTAssertEqual([[[tag valueForKey:@"markets"] allObjects] count], 4);
       }];
}

@end
