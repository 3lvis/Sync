@import XCTest;

#import "Inflections.h"

@interface NSString (PrivateInflections)

- (BOOL)hyp_containsWord:(NSString *)word;
- (NSString *)hyp_lowerCaseFirstLetter;
- (NSString *)hyp_replaceIdentifierWithString:(NSString *)replacementString;

@end

@interface NSString_InflectionsTests : XCTestCase

@end

@implementation NSString_InflectionsTests

#pragma mark - Inflections

- (void)testReplacementIdentifier {
    NSString *testString = @"first_name";

    XCTAssertEqualObjects([testString hyp_replaceIdentifierWithString:@""], @"FirstName");

    testString = @"id";

    XCTAssertEqualObjects([testString hyp_replaceIdentifierWithString:@""], @"ID");

    testString = @"user_id";

    XCTAssertEqualObjects([testString hyp_replaceIdentifierWithString:@""], @"UserID");
}

- (void)testLowerCaseFirstLetter {
    NSString *testString = @"FirstName";

    XCTAssertEqualObjects([testString hyp_lowerCaseFirstLetter], @"firstName");
}

- (void)testSnakeCase {
    NSString *camelCase = @"age";
    NSString *snakeCase = @"age";

    XCTAssertEqualObjects(snakeCase, [camelCase hyp_snakeCase]);

    camelCase = @"id";
    snakeCase = @"id";

    XCTAssertEqualObjects(snakeCase, [camelCase hyp_snakeCase]);

    camelCase = @"pdf";
    snakeCase = @"pdf";

    XCTAssertEqualObjects(snakeCase, [camelCase hyp_snakeCase]);

    camelCase = @"driverIdentifier";
    snakeCase = @"driver_identifier";

    XCTAssertEqualObjects(snakeCase, [camelCase hyp_snakeCase]);

    camelCase = @"integer16";
    snakeCase = @"integer16";

    XCTAssertEqualObjects(snakeCase, [camelCase hyp_snakeCase]);

    camelCase = @"userID";
    snakeCase = @"user_id";

    XCTAssertEqualObjects(snakeCase, [camelCase hyp_snakeCase]);

    camelCase = @"createdAt";
    snakeCase = @"created_at";

    XCTAssertEqualObjects(snakeCase, [camelCase hyp_snakeCase]);

    camelCase = @"userIDFirst";
    snakeCase = @"user_id_first";

    XCTAssertEqualObjects(snakeCase, [camelCase hyp_snakeCase]);

    camelCase = @"OrderedUser";
    snakeCase = @"ordered_user";

    XCTAssertEqualObjects(snakeCase, [camelCase hyp_snakeCase]);
}

- (void)testCamelCase {
    NSString *snakeCase = @"age";
    NSString *camelCase = @"age";

    XCTAssertEqualObjects(camelCase, [snakeCase hyp_camelCase]);

    snakeCase = @"id";
    camelCase = @"id";

    XCTAssertEqualObjects(camelCase, [snakeCase hyp_camelCase]);

    snakeCase = @"pdf";
    camelCase = @"pdf";

    XCTAssertEqualObjects(camelCase, [snakeCase hyp_camelCase]);

    snakeCase = @"driver_identifier";
    camelCase = @"driverIdentifier";

    XCTAssertEqualObjects(camelCase, [snakeCase hyp_camelCase]);

    snakeCase = @"integer16";
    camelCase = @"integer16";

    XCTAssertEqualObjects(snakeCase, [camelCase hyp_camelCase]);

    snakeCase = @"user_id";
    camelCase = @"userID";

    XCTAssertEqualObjects(camelCase, [snakeCase hyp_camelCase]);

    snakeCase = @"updated_at";
    camelCase = @"updatedAt";

    XCTAssertEqualObjects(camelCase, [snakeCase hyp_camelCase]);

//    snakeCase = @"f2f_url";
//    camelCase = @"f2fURL";
//
//    XCTAssertEqualObjects(camelCase, [snakeCase hyp_camelCase]);

    snakeCase = @"test_!_key";

    XCTAssertNil([snakeCase hyp_camelCase]);
}

- (void)testCamelCaseCapitalizedString {
    NSString *capitalizedString = @"GreenWallet";
    NSString *camelCase = @"greenWallet";

    XCTAssertEqualObjects(camelCase, [capitalizedString hyp_camelCase]);
}

- (void)testStorageForSameWordButDifferentInflections {
    XCTAssertEqualObjects(@"greenWallet", [@"GreenWallet" hyp_camelCase]);
    XCTAssertEqualObjects(@"green_wallet", [@"GreenWallet" hyp_snakeCase]);
}

- (void)testConcurrentAccess {
	dispatch_queue_t concurrentQueue = dispatch_queue_create("com.syncdb.test", DISPATCH_QUEUE_CONCURRENT);

	dispatch_apply(6000, concurrentQueue, ^(const size_t i){
		[self testSnakeCase];
		[self testCamelCase];
	});

}

@end
