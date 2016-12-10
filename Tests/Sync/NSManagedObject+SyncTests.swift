import XCTest
import CoreData

class NSManagedObject_SyncTests: XCTestCase {
    func testCopyInContext() {
        // Create and fetch an item in a mainContext, then copy that item
        // to a background context. Then do the check there.
    }

    func testFillWithDictionary() {
        // This method is mostly to categorize the type of filling that we should do.
        // Maybe is better to just unit test a method that returns the type of relationship syncing.
    }

    // I am afraid that we will end up duplicating many of the current existing tests in order to test the following
    // methods. Maybe a better idea would be to split up those into methods that return things instead of just mutations.
    func testToManyRelationship() {
    }

    func testRelationshipUsingIDInsteadOfDictionary() {
    }

    func testToOneRelationship() {
    }
}
