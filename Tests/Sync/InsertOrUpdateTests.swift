import XCTest

import CoreData
import Sync

class InsertOrUpdateTests: XCTestCase {
    func testInsertOrUpdateWithStringID() {
        let dataStack = Helper.dataStackWithModelName("id")
        let json = ["id": "id", "name": "name"]
        let insertedObject = try! dataStack.insertOrUpdate(json, inEntityNamed: "User")
        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))

        XCTAssertEqual(insertedObject.value(forKey: "id") as? String, "id")
        XCTAssertEqual(insertedObject.value(forKey: "name") as? String, "name")

        if let object = Helper.fetchEntity("User", inContext: dataStack.mainContext).first {
            XCTAssertEqual(object.value(forKey: "id") as? String, "id")
            XCTAssertEqual(object.value(forKey: "name") as? String, "name")
        } else {
            XCTFail()
        }
        dataStack.drop()
    }

    func testInsertOrUpdateWithNumberID() {
        let dataStack = Helper.dataStackWithModelName("Tests")
        let json = ["id": 1]
        try! dataStack.insertOrUpdate(json, inEntityNamed: "User")
        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))
        dataStack.drop()
    }

    func testInsertOrUpdateUpdate() {
        let dataStack = Helper.dataStackWithModelName("id")
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: dataStack.mainContext)
        user.setValue("id", forKey: "id")
        user.setValue("old", forKey: "name")
        try! dataStack.mainContext.save()

        let json = ["id": "id", "name": "new"]
        let updatedObject = try! dataStack.insertOrUpdate(json, inEntityNamed: "User")
        XCTAssertEqual(updatedObject.value(forKey: "id") as? String, "id")
        XCTAssertEqual(updatedObject.value(forKey: "name") as? String, "new")

        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))
        if let object = Helper.fetchEntity("User", inContext: dataStack.mainContext).first {
            XCTAssertEqual(object.value(forKey: "id") as? String, "id")
            XCTAssertEqual(object.value(forKey: "name") as? String, "new")
        } else {
            XCTFail()
        }
        dataStack.drop()
    }
}
