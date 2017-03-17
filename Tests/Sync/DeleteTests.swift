import XCTest

import CoreData
import Sync

class DeleteTests: XCTestCase {
    func testDeleteWithStringID() {
        let dataStack = Helper.dataStackWithModelName("id")
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: dataStack.mainContext)
        user.setValue("id", forKey: "id")
        try! dataStack.mainContext.save()

        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))
        try! dataStack.delete("id", inEntityNamed: "User")
        XCTAssertEqual(0, Helper.countForEntity("User", inContext: dataStack.mainContext))

        dataStack.drop()
    }

    func testDeleteWithNumberID() {
        let dataStack = Helper.dataStackWithModelName("Tests")
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: dataStack.mainContext)
        user.setValue(1, forKey: "remoteID")
        try! dataStack.mainContext.save()

        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))
        try! dataStack.delete(1, inEntityNamed: "User")
        XCTAssertEqual(0, Helper.countForEntity("User", inContext: dataStack.mainContext))

        dataStack.drop()
    }
}
