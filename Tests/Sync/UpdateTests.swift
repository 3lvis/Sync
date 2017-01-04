import XCTest
import DATAStack
import CoreData

class UpdateTests: XCTestCase {
    func testUpdateWithObjectNotFound() {
        let dataStack = Helper.dataStackWithModelName("id")
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: dataStack.mainContext)
        user.setValue("id", forKey: "id")
        try! dataStack.mainContext.save()

        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))
        let id = try! Sync.update("someotherid", with: [String: Any](), inEntityNamed: "User", using: dataStack.mainContext)
        XCTAssertNil(id)
        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))

        dataStack.drop()
    }

    func testUpdateWhileMaintainingTheSameID() {
        let dataStack = Helper.dataStackWithModelName("id")
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: dataStack.mainContext)
        user.setValue("id", forKey: "id")
        try! dataStack.mainContext.save()

        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))
        let updatedObject = try! Sync.update("id", with: ["name": "bossy"], inEntityNamed: "User", using: dataStack.mainContext)
        XCTAssertEqual(updatedObject?.value(forKey: "id") as? String, "id")
        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))

        dataStack.mainContext.refresh(user, mergeChanges: false)

        XCTAssertEqual(user.value(forKey: "name") as? String, "bossy")

        dataStack.drop()
    }

    func testUpdateWithJSONThatHasNewID() {
        let dataStack = Helper.dataStackWithModelName("id")
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: dataStack.mainContext)
        user.setValue("id", forKey: "id")
        try! dataStack.mainContext.save()

        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))
        let updatedObject = try! Sync.update("id", with: ["id": "someid"], inEntityNamed: "User", using: dataStack.mainContext)
        XCTAssertEqual(updatedObject?.value(forKey: "id") as? String, "someid")
        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))

        dataStack.drop()
    }
}
