import XCTest
import DATAStack
import CoreData

class InsertTests: XCTestCase {
    func testInsertWithStringID() {
        let dataStack = Helper.dataStackWithModelName("id")
        let json = ["id": "id", "name": "name"]
        Sync.insertOrUpdate(json, inEntityNamed: "User", in: dataStack.mainContext, completion: nil)
        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))
        guard let object = Helper.fetchEntity("User", inContext: dataStack.mainContext).first else { XCTFail(); return }
        XCTAssertEqual(object.value(forKey: "id") as? String, "id")
        XCTAssertEqual(object.value(forKey: "name") as? String, "name")
        try! dataStack.drop()
    }

    func testInsertWithNumberID() {
        let dataStack = Helper.dataStackWithModelName("Tests")
        let json = ["id": 1]
        Sync.insertOrUpdate(json, inEntityNamed: "User", in: dataStack.mainContext, completion: nil)
        XCTAssertEqual(1, Helper.countForEntity("User", inContext: dataStack.mainContext))
        try! dataStack.drop()
    }
}
