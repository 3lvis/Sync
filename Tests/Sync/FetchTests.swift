import XCTest

import CoreData
import Sync

class FetchTests: XCTestCase {
    func testFetch() {
        let dataStack = Helper.dataStackWithModelName("id")
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: dataStack.mainContext)
        user.setValue("id", forKey: "id")
        user.setValue("dada", forKey: "name")
        try! dataStack.mainContext.save()
        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))

        let fetched = try! dataStack.fetch("id", inEntityNamed: "User")
        XCTAssertEqual(fetched?.value(forKey: "id") as? String, "id")
        XCTAssertEqual(fetched?.value(forKey: "name") as? String, "dada")

        try! Sync.delete("id", inEntityNamed: "User", using: dataStack.mainContext)
        XCTAssertEqual(0, Helper.countForEntity("User", inContext: dataStack.mainContext))

        let newFetched = try! dataStack.fetch("id", inEntityNamed: "User")
        XCTAssertNil(newFetched)

        dataStack.drop()
    }
}
