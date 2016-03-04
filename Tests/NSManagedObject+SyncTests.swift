import XCTest
import Sync
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
    
    // MARK: - Bug 179 => https://github.com/hyperoslo/Sync/issues/179
    
    func testConnectMultipleRelationships() {
        let places = Helper.objectsFromJSON("bug-179-places.json") as! [[String : AnyObject]]
        let routes = Helper.objectsFromJSON("bug-179-routes.json") as! [String : AnyObject]
        let dataStack = Helper.dataStackWithModelName("Bug179")
        
        Sync.changes(places, inEntityNamed: "Place", dataStack: dataStack, completion: nil)
        Sync.changes([ routes ], inEntityNamed: "Route", dataStack: dataStack, completion: nil)
        
        XCTAssertEqual(Helper.countForEntity("Route", inContext:dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Place", inContext:dataStack.mainContext), 2)
        let importedRoutes = Helper.fetchEntity("Route", predicate: nil, inContext:dataStack.mainContext)
        XCTAssertEqual(importedRoutes.count, 1)
        
        let startPlace = importedRoutes.first!.valueForKey("startPlace") as! NSManagedObject
        let endPlace = importedRoutes.first!.valueForKey("endPlace") as! NSManagedObject
        
        XCTAssertNotNil(startPlace)
        XCTAssertNotNil(endPlace)
        
        XCTAssertNotEqual(startPlace, endPlace)
        
        dataStack.drop()
    }
}
