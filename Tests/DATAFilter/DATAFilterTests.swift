import XCTest
import CoreData
import DATAStack

class DATAFilterTests: XCTestCase {
    @discardableResult func user(remoteID: Int, firstName: String, lastName: String, age: Int, context: NSManagedObjectContext) -> NSManagedObject {
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: context)
        user.setValue(remoteID, forKey: "remoteID")
        user.setValue(firstName, forKey: "firstName")
        user.setValue(lastName, forKey: "lastName")
        user.setValue(age, forKey: "age")

        try! context.save()

        return user
    }

    @discardableResult func note(remoteID: String, text: String, context: NSManagedObjectContext) -> NSManagedObject {
        let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
        note.setValue(remoteID, forKey: "remoteID")
        note.setValue(text, forKey: "text")

        try! context.save()

        return note
    }

    func createUsers(context: NSManagedObjectContext) {
        self.user(remoteID: 0, firstName: "Amy", lastName: "Juergens", age: 21, context: context)
        self.user(remoteID: 1, firstName: "Ben", lastName: "Boykewich", age: 23, context: context)
        self.user(remoteID: 2, firstName: "Ricky", lastName: "Underwood", age: 19, context: context)
        self.user(remoteID: 3, firstName: "Grace", lastName: "Bowman", age: 20, context: context)
        self.user(remoteID: 4, firstName: "Adrian", lastName: "Lee", age: 20, context: context)
    }

    func testUsersCount() {
        let dataStack = DATAStack(modelName: "Model", bundle: Bundle(for: DATAFilterTests.self), storeType: .inMemory)
        self.createUsers(context: dataStack.mainContext)

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        let count = try! dataStack.mainContext.count(for: request)
        XCTAssertEqual(count, 5)
    }

    /*
    /*
     5 pre-defined users are inserted, IDs: 0, 1, 2, 3, 4
     In users.json:
     - Inserted: 6 and 7
     - Updated: 0, 1, 2 and 3
     - Deleted: 4
     */
    func testMapChangesA() {
        let dataStack = DATAStack(modelName: "Model", bundle: Bundle(for: DATAFilterTests.self), storeType: .inMemory)
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.createUsers(context: backgroundContext)

            let before = DATAObjectIDs.objectIDs(inEntityNamed: "User", withAttributesNamed: "remoteID", context: backgroundContext)
            let JSONObjects = try! JSON.from("users.json", bundle: Bundle(for: DATAFilterTests.self)) as! [[String: Any]]
            var inserted = 0
            var updated = 0
            var deleted = before.count
            DATAFilter.changes(JSONObjects, inEntityNamed: "User", localPrimaryKey: "remoteID", remotePrimaryKey: "id", context: backgroundContext, inserted: { objectJSON in
                inserted += 1
            }, updated: { objectJSON, updatedObject in
                updated += 1
                deleted -= 1
            })
            XCTAssertEqual(inserted, 2)
            XCTAssertEqual(updated, 4)
            XCTAssertEqual(deleted, 1)
        }
    }

    /*
     5 pre-defined users are inserted, IDs: 0, 1, 2, 3, 4
     In users.json:
     - Inserted: 6 and 7
     - Updated: 0, 1, 2 and 3
     - Deleted: 4
     */
    func testMapChangesAWitNull() {
        let dataStack = DATAStack(modelName: "Model", bundle: Bundle(for: DATAFilterTests.self), storeType: .inMemory)
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.createUsers(context: backgroundContext)

            let before = DATAObjectIDs.objectIDs(inEntityNamed: "User", withAttributesNamed: "remoteID", context: backgroundContext)
            let JSONObjects = try! JSON.from("users-with-null.json", bundle: Bundle(for: DATAFilterTests.self)) as! [[String: Any]]
            var inserted = 0
            var updated = 0
            var deleted = before.count
            DATAFilter.changes(JSONObjects, inEntityNamed: "User", localPrimaryKey: "remoteID", remotePrimaryKey: "id", context: backgroundContext, inserted: { objectJSON in
                inserted += 1
            }, updated: { objectJSON, updatedObject in
                updated += 1
                deleted -= 1
            })
            XCTAssertEqual(inserted, 2)
            XCTAssertEqual(updated, 4)
            XCTAssertEqual(deleted, 1)
        }
    }

    /*
     5 pre-defined users are inserted, IDs: 0, 1, 2, 3, 4
     In users.json:
     - Inserted: 6 and 7
     - Updated: 0, 1, 2 and 3
     - Deleted: 4
     */
    func testMapChangesAWithNil() {
        let dataStack = DATAStack(modelName: "Model", bundle: Bundle(for: DATAFilterTests.self), storeType: .inMemory)
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.createUsers(context: backgroundContext)

            let before = DATAObjectIDs.objectIDs(inEntityNamed: "User", withAttributesNamed: "remoteID", context: backgroundContext)
            let JSONObjects = try! JSON.from("users-with-nil.json", bundle: Bundle(for: DATAFilterTests.self)) as! [[String: Any]]
            var inserted = 0
            var updated = 0
            var deleted = before.count
            DATAFilter.changes(JSONObjects, inEntityNamed: "User", localPrimaryKey: "remoteID", remotePrimaryKey: "id", context: backgroundContext, inserted: { objectJSON in
                inserted += 1
            }, updated: { objectJSON, updatedObject in
                updated += 1
                deleted -= 1
            })
            XCTAssertEqual(inserted, 2)
            XCTAssertEqual(updated, 3)
            XCTAssertEqual(deleted, 2)
        }
    }

    /*
     5 pre-defined users are inserted, IDs: 0, 1, 2, 3, 4
     In users.json:
     - Inserted: None
     - Updated: 0, 1, 2, 3 and 4
     - Deleted: None
     */
    func testMapChangesB() {
        let dataStack = DATAStack(modelName: "Model", bundle: Bundle(for: DATAFilterTests.self), storeType: .inMemory)
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.createUsers(context: backgroundContext)

            let before = DATAObjectIDs.objectIDs(inEntityNamed: "User", withAttributesNamed: "remoteID", context: backgroundContext)
            let JSONObjects = try! JSON.from("users2.json", bundle: Bundle(for: DATAFilterTests.self)) as! [[String: Any]]
            var inserted = 0
            var updated = 0
            var deleted = before.count
            DATAFilter.changes(JSONObjects, inEntityNamed: "User", localPrimaryKey: "remoteID", remotePrimaryKey: "id", context: backgroundContext, inserted: { objectJSON in
                inserted += 1
            }, updated: { objectJSON, updatedObject in
                updated += 1
                deleted -= 1
            })
            XCTAssertEqual(inserted, 0)
            XCTAssertEqual(updated, 5)
            XCTAssertEqual(deleted, 0)
        }
    }

    /*
     5 pre-defined users are inserted, IDs: 0, 1, 2, 3, 4
     In users.json:
     - Inserted: None
     - Updated: None
     - Deleted: None
     */
    func testMapChangesC() {
        let dataStack = DATAStack(modelName: "Model", bundle: Bundle(for: DATAFilterTests.self), storeType: .inMemory)
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.createUsers(context: backgroundContext)

            let before = DATAObjectIDs.objectIDs(inEntityNamed: "User", withAttributesNamed: "remoteID", context: backgroundContext)
            let JSONObjects = try! JSON.from("users3.json", bundle: Bundle(for: DATAFilterTests.self)) as! [[String: Any]]
            var inserted = 0
            var updated = 0
            var deleted = before.count
            DATAFilter.changes(JSONObjects, inEntityNamed: "User", localPrimaryKey: "remoteID", remotePrimaryKey: "id", context: backgroundContext, inserted: { objectJSON in
                inserted += 1
            }, updated: { objectJSON, updatedObject in
                updated += 1
                deleted -= 1
            })
            XCTAssertEqual(inserted, 0)
            XCTAssertEqual(updated, 0)
            XCTAssertEqual(deleted, 5)
        }
    }

    /*
     5 pre-defined users are inserted, IDs: 0, 1, 2, 3, 4
     After the pre-defined ones, we try to insert the user 0 many times.
     In users.json:
     - Inserted: 6 and 7
     - Updated: 0, 1, 2 and 3
     - Deleted: 4
     */
    func testUniquing() {
        let dataStack = DATAStack(modelName: "Model", bundle: Bundle(for: DATAFilterTests.self), storeType: .inMemory)
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.createUsers(context: backgroundContext)

            self.user(remoteID: 0, firstName: "Amy", lastName: "Juergens", age: 21, context: backgroundContext)
            self.user(remoteID: 0, firstName: "Amy", lastName: "Juergens", age: 21, context: backgroundContext)
            self.user(remoteID: 0, firstName: "Amy", lastName: "Juergens", age: 21, context: backgroundContext)
            try! backgroundContext.save()

            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
            let numberOfUsers = try! backgroundContext.count(for: request)
            XCTAssertEqual(numberOfUsers, 8)

            let JSONObjects = try! JSON.from("users.json", bundle: Bundle(for: DATAFilterTests.self)) as! [[String: Any]]
            DATAFilter.changes(JSONObjects, inEntityNamed: "User", localPrimaryKey: "remoteID", remotePrimaryKey: "id", context: backgroundContext, inserted: { objectJSON in
            }, updated: { objectJSON, updatedObject in
            })

            let deletedNumberOfUsers = try! backgroundContext.count(for: request)
            XCTAssertEqual(deletedNumberOfUsers, 4)
        }
    }

    /*
     1 pre-defined none is inserted with id "123"
     In notes.json:
     - Inserted: 0
     - Updated: "123"
     - Deleted: 0
     */
    func testStringID() {
        let dataStack = DATAStack(modelName: "Model", bundle: Bundle(for: DATAFilterTests.self), storeType: .inMemory)
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.note(remoteID: "123", text: "text", context: backgroundContext)
            try! backgroundContext.save()

            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
            let count = try! backgroundContext.count(for: request)
            XCTAssertEqual(count, 1)

            let JSONObjects = try! JSON.from("note.json", bundle: Bundle(for: DATAFilterTests.self)) as! [[String: Any]]
            DATAFilter.changes(JSONObjects, inEntityNamed: "Note", localPrimaryKey: "remoteID", remotePrimaryKey: "id", context: backgroundContext, inserted: { objectJSON in
                XCTAssertFalse(true)
            }, updated: { objectJSON, updatedObject in
                XCTAssertEqual(objectJSON["id"] as? String, "123")
            })
        }
    }

    func testInsertOnly() {
        let dataStack = DATAStack(modelName: "Model", bundle: Bundle(for: DATAFilterTests.self), storeType: .inMemory)
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.user(remoteID: 0, firstName: "Amy", lastName: "Juergens", age: 21, context: backgroundContext)
            self.user(remoteID: 1, firstName: "Ben", lastName: "Boykewich", age: 23, context: backgroundContext)

            let before = DATAObjectIDs.objectIDs(inEntityNamed: "User", withAttributesNamed: "remoteID", context: backgroundContext)
            let JSONObjects = try! JSON.from("simple.json", bundle: Bundle(for: DATAFilterTests.self)) as! [[String: Any]]
            var inserted = 0
            var updated = 0
            var deleted = before.count
            DATAFilter.changes(JSONObjects, inEntityNamed: "User", predicate: nil, operations: [.Insert], localPrimaryKey: "remoteID", remotePrimaryKey: "id", context: backgroundContext, inserted: { objectJSON in
                inserted += 1
            }, updated: { objectJSON, updatedObject in
                updated += 1
                deleted -= 1
            })
            XCTAssertEqual(inserted, 1)
            XCTAssertEqual(updated, 0)
            XCTAssertEqual(deleted, 2)
        }
    }

    func testUpdateOnly() {
        let dataStack = DATAStack(modelName: "Model", bundle: Bundle(for: DATAFilterTests.self), storeType: .inMemory)
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.user(remoteID: 0, firstName: "Amy", lastName: "Juergens", age: 21, context: backgroundContext)
            self.user(remoteID: 1, firstName: "Ben", lastName: "Boykewich", age: 23, context: backgroundContext)

            let before = DATAObjectIDs.objectIDs(inEntityNamed: "User", withAttributesNamed: "remoteID", context: backgroundContext)
            let JSONObjects = try! JSON.from("simple.json", bundle: Bundle(for: DATAFilterTests.self)) as! [[String: Any]]
            var inserted = 0
            var updated = 0
            var deleted = before.count
            DATAFilter.changes(JSONObjects, inEntityNamed: "User", predicate: nil, operations: [.Update], localPrimaryKey: "remoteID", remotePrimaryKey: "id", context: backgroundContext, inserted: { objectJSON in
                inserted += 1
            }, updated: { objectJSON, updatedObject in
                updated += 1
                deleted -= 1
            })
            XCTAssertEqual(inserted, 0)
            XCTAssertEqual(updated, 1)
            XCTAssertEqual(deleted, 1)
        }
    }

    func testDeleteOnly() {
        let dataStack = DATAStack(modelName: "Model", bundle: Bundle(for: DATAFilterTests.self), storeType: .inMemory)
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.user(remoteID: 0, firstName: "Amy", lastName: "Juergens", age: 21, context: backgroundContext)
            self.user(remoteID: 1, firstName: "Ben", lastName: "Boykewich", age: 23, context: backgroundContext)

            let before = DATAObjectIDs.objectIDs(inEntityNamed: "User", withAttributesNamed: "remoteID", context: backgroundContext)
            let JSONObjects = try! JSON.from("simple.json", bundle: Bundle(for: DATAFilterTests.self)) as! [[String: Any]]
            var inserted = 0
            var updated = 0
            var deleted = before.count
            DATAFilter.changes(JSONObjects, inEntityNamed: "User", predicate: nil, operations: [.Delete], localPrimaryKey: "remoteID", remotePrimaryKey: "id", context: backgroundContext, inserted: { objectJSON in
                inserted += 1
            }, updated: { objectJSON, updatedObject in
                updated += 1
                deleted -= 1
            })
            XCTAssertEqual(inserted, 0)
            XCTAssertEqual(updated, 0)
            XCTAssertEqual(deleted, 2)
        }
    }

    /*
     5 pre-defined users are inserted, IDs: 0, 1, 2, 3, 4
     The predicate "remoteID == 1" means that we will only compare the users.json with
     the set existing ID: 1, meaning that if an item with ID: 2 appears, then this item will be inserted.
     */
    func testPredicate() {
        let dataStack = DATAStack(modelName: "Model", bundle: Bundle(for: DATAFilterTests.self), storeType: .inMemory)
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.createUsers(context: backgroundContext)

            let before = DATAObjectIDs.objectIDs(inEntityNamed: "User", withAttributesNamed: "remoteID", context: backgroundContext)
            let JSONObjects = try! JSON.from("users.json", bundle: Bundle(for: DATAFilterTests.self)) as! [[String: Any]]
            var inserted = 0
            var updated = 0
            var deleted = before.count
            DATAFilter.changes(JSONObjects, inEntityNamed: "User", predicate: NSPredicate(format: "remoteID == \(0)"), operations: [.All], localPrimaryKey: "remoteID", remotePrimaryKey: "id", context: backgroundContext, inserted: { objectJSON in
                inserted += 1
            }, updated: { objectJSON, updatedObject in
                updated += 1
                deleted -= 1
            })
            XCTAssertEqual(inserted, 5)
            XCTAssertEqual(updated, 1)
            XCTAssertEqual(deleted, 4)
        }
    }
     */
}
