import XCTest
import DATAStack
import CoreData

class FetchTests: XCTestCase {
    func testFetch() {
        let dataStack = Helper.dataStackWithModelName("id")
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: dataStack.mainContext)
        user.setValue("id", forKey: "id")
        user.setValue("dada", forKey: "name")
        try! dataStack.mainContext.save()
        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))

        let fetched = try! Sync.fetch("id", inEntityNamed: "User", using: dataStack.mainContext)
        XCTAssertEqual(fetched?.value(forKey: "id") as? String, "id")
        XCTAssertEqual(fetched?.value(forKey: "name") as? String, "dada")

        try! Sync.delete("id", inEntityNamed: "User", using: dataStack.mainContext)
        XCTAssertEqual(0, Helper.countForEntity("User", inContext: dataStack.mainContext))

        let newFetched = try! Sync.fetch("id", inEntityNamed: "User", using: dataStack.mainContext)
        XCTAssertNil(newFetched)

        try! dataStack.drop()
    }
}
