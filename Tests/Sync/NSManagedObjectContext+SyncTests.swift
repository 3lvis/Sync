import XCTest
import DATAStack

class NSManagedObjectContext_SyncTests: XCTestCase {
    func testSafeObjectInContext() {
    }

    func configureUserWithRemoteID(remoteID: NSNumber?, localID: String?, name: String, block: @escaping (_ user: NSManagedObject, _ context: NSManagedObjectContext) -> Void) {
        let stack = DATAStack(modelName: "Tests", bundle: Bundle(for: NSManagedObjectContext_SyncTests.self), storeType: .inMemory)
        stack.performInNewBackgroundContext { context in
            let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: context)
            user.setValue(remoteID, forKey: "remoteID")
            user.setValue(localID, forKey: "localID")
            user.setValue(name, forKey: "name")
            try! context.save()
            block(user, context)
        }
    }

    func testDictionary() {
        self.configureUserWithRemoteID(remoteID: 1, localID: nil, name: "Joshua") { user, context in
            let dictionary = context.managedObjectIDs(in: "User", usingAsKey: "remoteID", predicate: nil)
            XCTAssertNotNil(dictionary)
            XCTAssertTrue(dictionary.count == 1)
            XCTAssertEqual(dictionary[NSNumber(value: 1)], user.objectID)

            let objectID = dictionary[NSNumber(value: 1)]!
            let retreivedUser = context.object(with: objectID)
            XCTAssertEqual(retreivedUser.value(forKey: "remoteID") as? Int, 1)
            XCTAssertEqual(retreivedUser.value(forKey: "name") as? String, "Joshua")
        }
    }

    func testDictionaryStringLocalKey() {
        self.configureUserWithRemoteID(remoteID: nil, localID: "100", name: "Joshua") { user, context in
            let dictionary = context.managedObjectIDs(in: "User", usingAsKey: "localID", predicate: nil)
            XCTAssertNotNil(dictionary)
            XCTAssertTrue(dictionary.count == 1)
            XCTAssertEqual(dictionary["100"], user.objectID)

            let objectID = dictionary["100"]!
            let retreivedUser = context.object(with: objectID)
            XCTAssertEqual(retreivedUser.value(forKey: "localID") as? String, "100")
            XCTAssertEqual(retreivedUser.value(forKey: "name") as? String, "Joshua")
        }
    }
}
