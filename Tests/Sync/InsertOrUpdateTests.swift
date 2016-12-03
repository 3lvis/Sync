import XCTest
import DATAStack
import CoreData

class InsertOrUpdateTests: XCTestCase {
    func testInsertOrUpdateWithStringID() {
        let dataStack = Helper.dataStackWithModelName("id")
        let json = ["id": "id", "name": "name"]
        let insertedObject = try! Sync.insertOrUpdate(json, inEntityNamed: "User", using: dataStack.mainContext)
        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))

        XCTAssertEqual(insertedObject.value(forKey: "id") as? String, "id")
        XCTAssertEqual(insertedObject.value(forKey: "name") as? String, "name")

        if let object = Helper.fetchEntity("User", inContext: dataStack.mainContext).first {
            XCTAssertEqual(object.value(forKey: "id") as? String, "id")
            XCTAssertEqual(object.value(forKey: "name") as? String, "name")
        } else {
            XCTFail()
        }
        try! dataStack.drop()
    }

    func testInsertOrUpdateWithNumberID() {
        let dataStack = Helper.dataStackWithModelName("Tests")
        let json = ["id": 1]
        try! Sync.insertOrUpdate(json, inEntityNamed: "User", using: dataStack.mainContext)
        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))
        try! dataStack.drop()
    }

    func testInsertOrUpdateUpdate() {
        let dataStack = Helper.dataStackWithModelName("id")
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: dataStack.mainContext)
        user.setValue("id", forKey: "id")
        user.setValue("old", forKey: "name")
        try! dataStack.mainContext.save()

        let json = ["id": "id", "name": "new"]
        let updatedObject = try! Sync.insertOrUpdate(json, inEntityNamed: "User", using: dataStack.mainContext)
        XCTAssertEqual(updatedObject.value(forKey: "id") as? String, "id")
        XCTAssertEqual(updatedObject.value(forKey: "name") as? String, "new")

        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))
        if let object = Helper.fetchEntity("User", inContext: dataStack.mainContext).first {
            XCTAssertEqual(object.value(forKey: "id") as? String, "id")
            XCTAssertEqual(object.value(forKey: "name") as? String, "new")
        } else {
            XCTFail()
        }
        try! dataStack.drop()
    }
}
