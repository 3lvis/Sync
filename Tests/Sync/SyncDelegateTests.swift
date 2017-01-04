import XCTest
import DATAStack
import CoreData

class SyncDelegateTests: XCTestCase {
    func testWillInsertJSON() {
        let dataStack = Helper.dataStackWithModelName("Tests")

        let json = [["id": 9, "completed": false]]
        let syncOperation = Sync(changes: json, inEntityNamed: "User", dataStack: dataStack)
        syncOperation.delegate = self
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 0)
        syncOperation.start()
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 1)

        if let task = Helper.fetchEntity("User", inContext: dataStack.mainContext).first {
            XCTAssertEqual(task.value(forKey: "remoteID") as? Int, 9)
            XCTAssertEqual(task.value(forKey: "localID") as? String, "local")
        } else {
            XCTFail()
        }
        dataStack.drop()
    }
}

extension SyncDelegateTests: SyncDelegate {
    func sync(_ sync: Sync, willInsert json: [String: Any], in entityNamed: String, parent: NSManagedObject?) -> [String: Any] {
        var newJSON = json
        newJSON["localID"] = "local"

        return newJSON
    }
}
