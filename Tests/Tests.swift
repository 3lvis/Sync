import XCTest
import DATAStack
import Sync

class Tests: XCTestCase {
    // MARK: - Contacts

    func testLoadAndUpdateUsers() {
        let objectsA = Helper.objectsFromJSON("users_a.json") as! [[String : AnyObject]]
        let dataStack = Helper.dataStackWithModelName("Contacts")
        Sync.changes(objectsA, inEntityNamed: "User", dataStack: dataStack, completion: nil)

        let count = Helper.countForEntity("User", inContext: dataStack.mainContext)
        XCTAssertEqual(count, 8)

        let objectsB = Helper.objectsFromJSON("users_b.json") as! [[String : AnyObject]]
        Sync.changes(objectsB, inEntityNamed: "User", dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("User", inContext:dataStack.mainContext), 6)

        let result = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(int: 7)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: dataStack.mainContext).first!
        XCTAssertEqual(result.valueForKey("email") as? String, "secondupdated@ovium.com")

        let dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd"
        dateFormat.timeZone = NSTimeZone(name: "GMT")

        let createdDate = dateFormat.dateFromString("2014-02-14")
        XCTAssertEqual(result.valueForKey("createdAt") as? NSDate, createdDate);

        let updatedDate = dateFormat.dateFromString("2014-02-17")
        XCTAssertEqual(result.valueForKey("updatedAt") as? NSDate, updatedDate)
        
        dataStack.drop()
    }
}
