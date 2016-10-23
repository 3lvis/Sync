import XCTest
import DATAStack

class DATAObjectIDsTests: XCTestCase {
    func insertUserWithRemoteID(remoteID: NSNumber?, localID: String?, name: String, context: NSManagedObjectContext) -> User {
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: context) as! User
        user.remoteID = remoteID
        user.localID = localID
        user.name = name
        
        return user
    }

    func configureUserWithRemoteID(remoteID: NSNumber?, localID: String?, name: String, block: @escaping (_ user: User, _ context: NSManagedObjectContext) -> Void) {
        let stack = DATAStack(modelName: "Tests", bundle: Bundle(for: DATAObjectIDsTests.self), storeType: .inMemory)
        stack.performInNewBackgroundContext { context in
            let user = self.insertUserWithRemoteID(remoteID: remoteID, localID: localID, name: name, context: context)
            try! context.save()
            block(user, context)
        }
    }

    func testDictionary() {
        self.configureUserWithRemoteID(remoteID: 1, localID: nil, name: "Joshua") { user, context in
            let dictionary = DATAObjectIDs.objectIDs(inEntityNamed: "User", withAttributesNamed: "remoteID", context: context)
            XCTAssertNotNil(dictionary)
            XCTAssertTrue(dictionary.count == 1)
            XCTAssertEqual(dictionary[NSNumber(value: 1)], user.objectID)

            let objectID = dictionary[NSNumber(value: 1)]!
            let retreivedUser = context.object(with: objectID) as! User
            XCTAssertEqual(retreivedUser.remoteID, 1);
            XCTAssertEqual(retreivedUser.name, "Joshua");
        }
    }

    func testDictionaryStringLocalKey() {
        self.configureUserWithRemoteID(remoteID: nil, localID: "100", name: "Joshua") { user, context in
            let dictionary = DATAObjectIDs.objectIDs(inEntityNamed: "User", withAttributesNamed: "localID", context: context)
            XCTAssertNotNil(dictionary)
            XCTAssertTrue(dictionary.count == 1)
            XCTAssertEqual(dictionary["100"], user.objectID);

            let objectID = dictionary["100"]!
            let retreivedUser = context.object(with: objectID) as! User
            XCTAssertEqual(retreivedUser.localID, "100")
            XCTAssertEqual(retreivedUser.name, "Joshua")
        }
    }

    func testObjectIDsArray() {
        self.configureUserWithRemoteID(remoteID: 1, localID: nil, name: "Joshua") { user, context in
            let objectIDs = DATAObjectIDs.objectIDs(inEntityNamed: "User", context: context)
            XCTAssertEqual(objectIDs.count, 1);
            XCTAssertEqual(objectIDs.first, user.objectID)
        }
    }

    func testObjectIDsArrayWithPredicate() {
        let stack = DATAStack(modelName: "Tests", bundle: Bundle(for: DATAObjectIDsTests.self), storeType: .inMemory)
        let _ = self.insertUserWithRemoteID(remoteID: 1, localID: nil, name: "Joshua", context: stack.mainContext)
        let jon = self.insertUserWithRemoteID(remoteID: 2, localID: nil, name: "Jon", context: stack.mainContext)

        let predicate = NSPredicate(format: "name == 'Jon'")
        let objectIDs = DATAObjectIDs.objectIDs(inEntityNamed: "User", context: stack.mainContext, predicate: predicate) 
        XCTAssertEqual(objectIDs.count, 1)
        XCTAssertEqual(objectIDs.first, jon.objectID)
    }

    func testDictionaryStringLocalKeyUsingSortDescriptor() {
        let stack = DATAStack(modelName: "Tests", bundle: Bundle(for: DATAObjectIDsTests.self), storeType: .inMemory)
        stack.performInNewBackgroundContext { context in
            let _ = self.insertUserWithRemoteID(remoteID: nil, localID: "100", name: "Joshua", context: context)
            let _ = self.insertUserWithRemoteID(remoteID: nil, localID: "200", name: "Jon", context: context)
            try! context.save()

            let attributesA = DATAObjectIDs.attributes(inEntityNamed: "User", attributeName: "localID", context: context, sortDescriptors: [NSSortDescriptor(key: "localID", ascending: true)])
            XCTAssertEqual(attributesA.first as? String, "100")

            let attributesB = DATAObjectIDs.attributes(inEntityNamed: "User", attributeName: "localID", context: context, sortDescriptors: [NSSortDescriptor(key: "localID", ascending: false)])
            XCTAssertEqual(attributesB.first as? String, "200")
        }
    }
}
