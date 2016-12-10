import XCTest
import DATAStack
import CoreData

class SyncTests: XCTestCase {
    func testSynchronous() {
        let dataStack = Helper.dataStackWithModelName("Camelcase")
        let objects = Helper.objectsFromJSON("camelcase.json") as! [[String: Any]]
        var synchronous = false
        Sync.changes(objects, inEntityNamed: "NormalUser", dataStack: dataStack) { _ in
            synchronous = true
        }
        XCTAssertTrue(synchronous)
        try! dataStack.drop()
    }

    // MARK: - Camelcase
    func testAutomaticCamelcaseMapping() {
        let dataStack = Helper.dataStackWithModelName("Camelcase")
        let objects = Helper.objectsFromJSON("camelcase.json") as! [[String: Any]]
        Sync.changes(objects, inEntityNamed: "NormalUser", dataStack: dataStack, completion: nil)

        let result = Helper.fetchEntity("NormalUser", inContext: dataStack.mainContext)
        XCTAssertEqual(result.count, 1)

        let first = result.first!
        XCTAssertEqual(first.value(forKey: "etternavn") as? String, "Nuñez")
        XCTAssertEqual(first.value(forKey: "firstName") as? String, "Elvis")
        XCTAssertEqual(first.value(forKey: "fullName") as? String, "Elvis Nuñez")
        XCTAssertEqual(first.value(forKey: "numberOfChildren") as? Int, 1)
        XCTAssertEqual(first.value(forKey: "remoteID") as? String, "1")

        try! dataStack.drop()
    }

    // MARK: - Contacts

    func testLoadAndUpdateUsers() {
        let dataStack = Helper.dataStackWithModelName("Contacts")

        let objectsA = Helper.objectsFromJSON("users_a.json") as! [[String: Any]]
        Sync.changes(objectsA, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 8)

        let objectsB = Helper.objectsFromJSON("users_b.json") as! [[String: Any]]
        Sync.changes(objectsB, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 6)

        let result = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 7)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: dataStack.mainContext).first!
        XCTAssertEqual(result.value(forKey: "email") as? String, "secondupdated@ovium.com")

        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd"
        dateFormat.timeZone = TimeZone(identifier: "GMT")

        let createdDate = dateFormat.date(from: "2014-02-14")
        XCTAssertEqual(result.value(forKey: "createdAt") as? Date, createdDate)

        let updatedDate = dateFormat.date(from: "2014-02-17")
        XCTAssertEqual(result.value(forKey: "updatedAt") as? Date, updatedDate)

        try! dataStack.drop()
    }

    func testUsersAndCompanies() {
        let dataStack = Helper.dataStackWithModelName("Contacts")

        let objects = Helper.objectsFromJSON("users_company.json") as! [[String: Any]]
        Sync.changes(objects, inEntityNamed: "User", dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 5)
        let user = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: dataStack.mainContext).first!
        XCTAssertEqual((user.value(forKey: "company")! as? NSManagedObject)!.value(forKey: "name") as? String, "Apple")

        XCTAssertEqual(Helper.countForEntity("Company", inContext: dataStack.mainContext), 2)
        let company = Helper.fetchEntity("Company", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 1)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: dataStack.mainContext).first!
        XCTAssertEqual(company.value(forKey: "name") as? String, "Facebook")

        try! dataStack.drop()
    }

    func testCustomMappingAndCustomPrimaryKey() {
        let dataStack = Helper.dataStackWithModelName("Contacts")
        let objects = Helper.objectsFromJSON("images.json") as! [[String: Any]]
        Sync.changes(objects, inEntityNamed: "Image", dataStack: dataStack, completion: nil)

        let array = Helper.fetchEntity("Image", sortDescriptors: [NSSortDescriptor(key: "url", ascending: true)], inContext: dataStack.mainContext)
        XCTAssertEqual(array.count, 3)
        let image = array.first
        XCTAssertEqual(image!.value(forKey: "url") as? String, "http://sample.com/sample0.png")

        try! dataStack.drop()
    }

    func testRelationshipsB() {
        let dataStack = Helper.dataStackWithModelName("Contacts")

        let objects = Helper.objectsFromJSON("users_c.json") as! [[String: Any]]
        Sync.changes(objects, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 4)

        let users = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 6)), inContext: dataStack.mainContext)
        let user = users.first!
        XCTAssertEqual(user.value(forKey: "name") as? String, "Shawn Merrill")

        let location = user.value(forKey: "location") as! NSManagedObject
        XCTAssertEqual(location.value(forKey: "city") as? String, "New York")
        XCTAssertEqual(location.value(forKey: "street") as? String, "Broadway")
        XCTAssertEqual(location.value(forKey: "zipCode") as? NSNumber, NSNumber(value: 10012))

        let profilePicturesCount = Helper.countForEntity("Image", predicate: NSPredicate(format: "user = %@", user), inContext: dataStack.mainContext)
        XCTAssertEqual(profilePicturesCount, 3)

        try! dataStack.drop()
    }

    // If all operations where enabled in the first sync, 2 users would be inserted, in the second sync 1 user would be updated
    // and one user deleted. In this test we try only inserting user, no update, no insert, so the second sync should leave us with
    // 2 users with no changes and 1 inserted user.
    func testSyncingWithOnlyInsertOperationType() {
        let dataStack = Helper.dataStackWithModelName("Contacts")

        let objectsA = Helper.objectsFromJSON("operation-types-users-a.json") as! [[String: Any]]
        Sync.changes(objectsA, inEntityNamed: "User", dataStack: dataStack, operations: [.All], completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 2)

        let objectsB = Helper.objectsFromJSON("operation-types-users-b.json") as! [[String: Any]]
        Sync.changes(objectsB, inEntityNamed: "User", dataStack: dataStack, operations: [.Insert], completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 3)

        let result = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: dataStack.mainContext).first!
        XCTAssertEqual(result.value(forKey: "email") as? String, "melisawhite@ovium.com")

        try! dataStack.drop()
    }

    // If all operations where enabled in the first sync, 2 users would be inserted, in the second sync 1 user would be updated
    // and one user deleted. In this test we try only inserting user, no update, no insert, so the second sync should leave us with
    // 2 users with no changes and 1 inserted user. After this is done, we'll try inserting again, this shouldn't make any changes.
    func testSyncingWithMultipleInsertOperationTypes() {
        let dataStack = Helper.dataStackWithModelName("Contacts")

        let objectsA = Helper.objectsFromJSON("operation-types-users-a.json") as! [[String: Any]]
        Sync.changes(objectsA, inEntityNamed: "User", dataStack: dataStack, operations: [.All], completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 2)

        let objectsB = Helper.objectsFromJSON("operation-types-users-b.json") as! [[String: Any]]
        Sync.changes(objectsB, inEntityNamed: "User", dataStack: dataStack, operations: [.Insert], completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 3)

        let result = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: dataStack.mainContext).first!
        XCTAssertEqual(result.value(forKey: "email") as? String, "melisawhite@ovium.com")

        Sync.changes(objectsB, inEntityNamed: "User", dataStack: dataStack, operations: [.Insert], completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 3)

        try! dataStack.drop()
    }

    // If all operations where enabled in the first sync, 2 users would be inserted, in the second sync 1 user would be updated
    // and one user deleted. In this test we try only updating users, no insert, no delete, so the second sync should leave us with
    // one updated user and one inserted user, the third user will be discarded.
    func testSyncingWithOnlyUpdateOperationType() {
        let dataStack = Helper.dataStackWithModelName("Contacts")

        let objectsA = Helper.objectsFromJSON("operation-types-users-a.json") as! [[String: Any]]
        Sync.changes(objectsA, inEntityNamed: "User", dataStack: dataStack, operations: [.All], completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 2)

        let objectsB = Helper.objectsFromJSON("operation-types-users-b.json") as! [[String: Any]]
        Sync.changes(objectsB, inEntityNamed: "User", dataStack: dataStack, operations: [.Update], completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 2)

        let result = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: dataStack.mainContext).first!
        XCTAssertEqual(result.value(forKey: "email") as? String, "updated@ovium.com")

        try! dataStack.drop()
    }

    // If all operations where enabled in the first sync, 2 users would be inserted, in the second sync 1 user would be updated
    // and one user deleted. In this test we try only deleting users, no insert, no update, so the second sync should leave us with
    // one inserted user, one deleted user and one discarded user.
    func testSyncingWithOnlyDeleteOperationType() {
        let dataStack = Helper.dataStackWithModelName("Contacts")

        let objectsA = Helper.objectsFromJSON("operation-types-users-a.json") as! [[String: Any]]
        Sync.changes(objectsA, inEntityNamed: "User", dataStack: dataStack, operations: [.All], completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 2)

        let objectsB = Helper.objectsFromJSON("operation-types-users-b.json") as! [[String: Any]]
        Sync.changes(objectsB, inEntityNamed: "User", dataStack: dataStack, operations: [.Delete], completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 1)

        let result = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: dataStack.mainContext).first!
        XCTAssertEqual(result.value(forKey: "email") as? String, "melisawhite@ovium.com")

        try! dataStack.drop()
    }

    // If all operations where enabled in the first sync, 2 users would be inserted, in the second sync 1 user would be updated
    // and one user deleted. In this test we try inserting and updating users, no delete, so the second sync should leave us with
    // one updated user, one inserted user, and one user with no changes.
    func testSyncingWithInsertAndUpdateOperationType() {
        let dataStack = Helper.dataStackWithModelName("Contacts")

        let objectsA = Helper.objectsFromJSON("operation-types-users-a.json") as! [[String: Any]]
        Sync.changes(objectsA, inEntityNamed: "User", dataStack: dataStack, operations: [.All], completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 2)

        let objectsB = Helper.objectsFromJSON("operation-types-users-b.json") as! [[String: Any]]
        Sync.changes(objectsB, inEntityNamed: "User", dataStack: dataStack, operations: [.Insert, .Update], completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 3)

        let user0 = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: dataStack.mainContext).first!
        XCTAssertEqual(user0.value(forKey: "email") as? String, "updated@ovium.com")

        let user1 = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 1)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: dataStack.mainContext).first!
        XCTAssertNotNil(user1)

        try! dataStack.drop()
    }

    // MARK: - Notes

    func testRelationshipsA() {
        let objects = Helper.objectsFromJSON("users_notes.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("Notes")

        Sync.changes(objects, inEntityNamed: "SuperUser", dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("SuperUser", inContext: dataStack.mainContext), 4)
        let users = Helper.fetchEntity("SuperUser", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 6)), inContext: dataStack.mainContext)
        let user = users.first!
        XCTAssertEqual(user.value(forKey: "name") as? String, "Shawn Merrill")

        let notesCount = Helper.countForEntity("SuperNote", predicate: NSPredicate(format: "superUser = %@", user), inContext: dataStack.mainContext)
        XCTAssertEqual(notesCount, 5)

        try! dataStack.drop()
    }

    func testObjectsForParent() {
        let objects = Helper.objectsFromJSON("notes_for_user_a.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("InsertObjectsInParent")
        dataStack.performInNewBackgroundContext { backgroundContext in
            // First, we create a parent user, this user is the one that will own all the notes
            let user = NSEntityDescription.insertNewObject(forEntityName: "SuperUser", into: backgroundContext)
            user.setValue(NSNumber(value: 6), forKey: "remoteID")

            try! backgroundContext.save()
        }

        // Then we fetch the user on the main context, because we don't want to break things between contexts
        var users = Helper.fetchEntity("SuperUser", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 6)), inContext: dataStack.mainContext)
        XCTAssertEqual(users.count, 1)

        // Finally we say "Sync all the notes, for this user"
        Sync.changes(objects, inEntityNamed: "SuperNote", parent: users.first!, dataStack: dataStack, completion: nil)

        // Here we just make sure that the user has the notes that we just inserted
        users = Helper.fetchEntity("SuperUser", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 6)), inContext: dataStack.mainContext)
        let user = users.first!
        XCTAssertEqual(user.value(forKey: "remoteID") as? NSNumber, NSNumber(value: 6))

        let notesCount = Helper.countForEntity("SuperNote", predicate: NSPredicate(format: "superUser = %@", user), inContext: dataStack.mainContext)
        XCTAssertEqual(notesCount, 2)

        try! dataStack.drop()
    }

    func testTaggedNotesForUser() {
        let objects = Helper.objectsFromJSON("tagged_notes.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("Notes")

        Sync.changes(objects, inEntityNamed: "SuperNote", dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("SuperNote", inContext: dataStack.mainContext), 3)
        let notes = Helper.fetchEntity("SuperNote", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), inContext: dataStack.mainContext)
        let note = notes.first!
        XCTAssertEqual((note.value(forKey: "superTags") as? NSSet)!.allObjects.count, 2)

        XCTAssertEqual(Helper.countForEntity("SuperTag", inContext: dataStack.mainContext), 2)
        let tags = Helper.fetchEntity("SuperTag", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 1)), inContext: dataStack.mainContext)
        XCTAssertEqual(tags.count, 1)

        let tag = tags.first!
        XCTAssertEqual((tag.value(forKey: "superNotes") as? NSSet)!.allObjects.count, 2)
        try! dataStack.drop()
    }

    func testCustomKeysInRelationshipsToMany() {
        let objects = Helper.objectsFromJSON("custom_relationship_key_to_many.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("CustomRelationshipKey")

        Sync.changes(objects, inEntityNamed: "User", dataStack: dataStack, completion: nil)

        let array = Helper.fetchEntity("User", inContext: dataStack.mainContext)
        let user = array.first!
        XCTAssertEqual((user.value(forKey: "notes") as? NSSet)!.allObjects.count, 3)

        try! dataStack.drop()
    }

    // MARK: - Recursive

    func testNumbersWithEmptyRelationship() {
        let objects = Helper.objectsFromJSON("numbers.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("Recursive")

        Sync.changes(objects, inEntityNamed: "Number", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("Number", inContext: dataStack.mainContext), 6)

        try! dataStack.drop()
    }

    func testRelationshipName() {
        let objects = Helper.objectsFromJSON("numbers_in_collection.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("Recursive")

        Sync.changes(objects, inEntityNamed: "Number", dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("Collection", inContext: dataStack.mainContext), 1)

        let numbers = Helper.fetchEntity("Number", inContext: dataStack.mainContext)
        let number = numbers.first!
        XCTAssertNotNil(number.value(forKey: "parent"))
        XCTAssertEqual((number.value(forKey: "parent") as! NSManagedObject).value(forKey: "name") as? String, "Collection 1")

        try! dataStack.drop()
    }

    // MARK: - Social

    func testCustomPrimaryKey() {
        let objects = Helper.objectsFromJSON("comments-no-id.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("Social")

        Sync.changes(objects, inEntityNamed: "SocialComment", dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("SocialComment", inContext: dataStack.mainContext), 8)
        let comments = Helper.fetchEntity("SocialComment", predicate: NSPredicate(format: "body = %@", "comment 1"), inContext: dataStack.mainContext)
        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual((comments.first!.value(forKey: "comments") as! NSSet).count, 3)

        let comment = comments.first!
        XCTAssertEqual(comment.value(forKey: "body") as? String, "comment 1")

        try! dataStack.drop()
    }

    func testCustomPrimaryKeyInsideToManyRelationship() {
        let objects = Helper.objectsFromJSON("stories-comments-no-ids.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("Social")

        Sync.changes(objects, inEntityNamed: "Story", dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("Story", inContext: dataStack.mainContext), 3)
        let stories = Helper.fetchEntity("Story", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), inContext: dataStack.mainContext)
        let story = stories.first!

        XCTAssertEqual((story.value(forKey: "comments") as! NSSet).count, 3)

        XCTAssertEqual(Helper.countForEntity("SocialComment", inContext: dataStack.mainContext), 9)
        var comments = Helper.fetchEntity("SocialComment", predicate: NSPredicate(format: "body = %@", "comment 1"), inContext: dataStack.mainContext)
        XCTAssertEqual(comments.count, 3)

        comments = Helper.fetchEntity("SocialComment", predicate: NSPredicate(format: "body = %@ AND story = %@", "comment 1", story), inContext: dataStack.mainContext)
        XCTAssertEqual(comments.count, 1)
        if let comment = comments.first {
            XCTAssertEqual(comment.value(forKey: "body") as? String, "comment 1")
            XCTAssertEqual((comment.value(forKey: "story") as? NSManagedObject)!.value(forKey: "remoteID") as? NSNumber, NSNumber(value: 0))
            XCTAssertEqual((comment.value(forKey: "story") as? NSManagedObject)!.value(forKey: "title") as? String, "story 1")
        } else {
            XCTFail()
        }

        try! dataStack.drop()
    }

    func testCustomKeysInRelationshipsToOne() {
        let objects = Helper.objectsFromJSON("custom_relationship_key_to_one.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("Social")

        Sync.changes(objects, inEntityNamed: "Story", dataStack: dataStack, completion: nil)

        let array = Helper.fetchEntity("Story", inContext: dataStack.mainContext)
        let story = array.first!
        XCTAssertNotNil(story.value(forKey: "summarize"))

        try! dataStack.drop()
    }

    // MARK: - Markets

    func testMarketsAndItems() {
        let objects = Helper.objectsFromJSON("markets_items.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("Markets")

        Sync.changes(objects, inEntityNamed: "Market", dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("Market", inContext: dataStack.mainContext), 2)
        let markets = Helper.fetchEntity("Market", predicate: NSPredicate(format: "uniqueId = %@", "1"), inContext: dataStack.mainContext)
        let market = markets.first!
        XCTAssertEqual(market.value(forKey: "otherAttribute") as? String, "Market 1")
        XCTAssertEqual((market.value(forKey: "items") as? NSSet)!.allObjects.count, 1)

        XCTAssertEqual(Helper.countForEntity("Item", inContext: dataStack.mainContext), 1)
        let items = Helper.fetchEntity("Item", predicate: NSPredicate(format: "uniqueId = %@", "1"), inContext: dataStack.mainContext)
        let item = items.first!
        XCTAssertEqual(item.value(forKey: "otherAttribute") as? String, "Item 1")
        XCTAssertEqual((item.value(forKey: "markets") as? NSSet)!.allObjects.count, 2)

        try! dataStack.drop()
    }

    // MARK: - Organization

    func testOrganization() {
        let json = Helper.objectsFromJSON("organizations-tree.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("Organizations")

        Sync.changes(json, inEntityNamed: "OrganizationUnit", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("OrganizationUnit", inContext: dataStack.mainContext), 7)

        Sync.changes(json, inEntityNamed: "OrganizationUnit", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("OrganizationUnit", inContext: dataStack.mainContext), 7)

        try! dataStack.drop()
    }

    // MARK: - Unique

    /**
     *  C and A share the same collection of B, so in the first block
     *  2 entries of B get stored in A, in the second block this
     *  2 entries of B get updated and one entry of C gets added.
     */
    func testUniqueObject() {
        let objects = Helper.objectsFromJSON("unique.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("Unique")

        Sync.changes(objects, inEntityNamed: "A", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("A", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("B", inContext: dataStack.mainContext), 2)
        XCTAssertEqual(Helper.countForEntity("C", inContext: dataStack.mainContext), 0)

        Sync.changes(objects, inEntityNamed: "C", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("A", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("B", inContext: dataStack.mainContext), 2)
        XCTAssertEqual(Helper.countForEntity("C", inContext: dataStack.mainContext), 1)

        try! dataStack.drop()
    }

    // MARK: - Patients => https://github.com/SyncDB/Sync/issues/121

    func testPatients() {
        let objects = Helper.objectsFromJSON("patients.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("Patients")

        Sync.changes(objects, inEntityNamed: "Patient", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("Patient", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Baseline", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Alcohol", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Fitness", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Weight", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Measure", inContext: dataStack.mainContext), 1)

        try! dataStack.drop()
    }

    // MARK: - Bug 84 => https://github.com/SyncDB/Sync/issues/84

    func testStaffAndfulfillers() {
        let objects = Helper.objectsFromJSON("bug-number-84.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("Bug84")

        Sync.changes(objects, inEntityNamed: "MSStaff", dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("MSStaff", inContext: dataStack.mainContext), 1)

        let staff = Helper.fetchEntity("MSStaff", predicate: NSPredicate(format: "xid = %@", "mstaff_F58dVBTsXznvMpCPmpQgyV"), inContext: dataStack.mainContext)
        let oneStaff = staff.first!
        XCTAssertEqual(oneStaff.value(forKey: "image") as? String, "a.jpg")
        XCTAssertEqual((oneStaff.value(forKey: "fulfillers") as? NSSet)!.allObjects.count, 2)

        let numberOffulfillers = Helper.countForEntity("MSFulfiller", inContext: dataStack.mainContext)
        XCTAssertEqual(numberOffulfillers, 2)

        let fulfillers = Helper.fetchEntity("MSFulfiller", predicate: NSPredicate(format: "xid = %@", "ffr_AkAHQegYkrobp5xc2ySc5D"), inContext: dataStack.mainContext)
        let fullfiller = fulfillers.first!
        XCTAssertEqual(fullfiller.value(forKey: "name") as? String, "New York")
        XCTAssertEqual((fullfiller.value(forKey: "staff") as? NSSet)!.allObjects.count, 1)

        try! dataStack.drop()
    }

    // MARK: - Bug 113 => https://github.com/SyncDB/Sync/issues/113

    func testCustomPrimaryKeyBug113() {
        let objects = Helper.objectsFromJSON("bug-113-comments-no-id.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("Bug113")

        Sync.changes(objects, inEntityNamed: "AwesomeComment", dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("AwesomeComment", inContext: dataStack.mainContext), 8)
        let comments = Helper.fetchEntity("AwesomeComment", predicate: NSPredicate(format: "body = %@", "comment 1"), inContext: dataStack.mainContext)
        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual((comments.first!.value(forKey: "awesomeComments") as! NSSet).count, 3)

        let comment = comments.first!
        XCTAssertEqual(comment.value(forKey: "body") as? String, "comment 1")

        try! dataStack.drop()
    }

    func testCustomPrimaryKeyInsideToManyRelationshipBug113() {
        let objects = Helper.objectsFromJSON("bug-113-stories-comments-no-ids.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("Bug113")

        Sync.changes(objects, inEntityNamed: "AwesomeStory", dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("AwesomeStory", inContext: dataStack.mainContext), 3)
        let stories = Helper.fetchEntity("AwesomeStory", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), inContext: dataStack.mainContext)
        let story = stories.first!
        XCTAssertEqual((story.value(forKey: "awesomeComments") as! NSSet).count, 3)

        XCTAssertEqual(Helper.countForEntity("AwesomeComment", inContext: dataStack.mainContext), 9)
        var comments = Helper.fetchEntity("AwesomeComment", predicate: NSPredicate(format: "body = %@", "comment 1"), inContext: dataStack.mainContext)
        XCTAssertEqual(comments.count, 3)

        comments = Helper.fetchEntity("AwesomeComment", predicate: NSPredicate(format: "body = %@ AND awesomeStory = %@", "comment 1", story), inContext: dataStack.mainContext)
        XCTAssertEqual(comments.count, 1)
        if let comment = comments.first {
            XCTAssertEqual(comment.value(forKey: "body") as? String, "comment 1")
            let awesomeStory = comment.value(forKey: "awesomeStory") as! NSManagedObject
            XCTAssertEqual(awesomeStory.value(forKey: "remoteID") as? NSNumber, NSNumber(value: 0))
            XCTAssertEqual(awesomeStory.value(forKey: "title") as? String, "story 1")
        } else {
            XCTFail()
        }

        try! dataStack.drop()
    }

    func testCustomKeysInRelationshipsToOneBug113() {
        let objects = Helper.objectsFromJSON("bug-113-custom_relationship_key_to_one.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("Bug113")

        Sync.changes(objects, inEntityNamed: "AwesomeStory", dataStack: dataStack, completion: nil)

        let array = Helper.fetchEntity("AwesomeStory", inContext: dataStack.mainContext)
        let story = array.first!
        XCTAssertNotNil(story.value(forKey: "awesomeSummarize"))

        try! dataStack.drop()
    }

    // MARK: - Bug 125 => https://github.com/SyncDB/Sync/issues/125

    func testNilRelationshipsAfterUpdating_Sync_1_0_10() {
        let formDictionary = Helper.objectsFromJSON("bug-125.json") as! [String: Any]
        let uri = formDictionary["uri"] as! String
        let dataStack = Helper.dataStackWithModelName("Bug125")

        Sync.changes([formDictionary], inEntityNamed: "Form", predicate: NSPredicate(format: "uri == %@", uri), dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("Form", inContext: dataStack.mainContext), 1)

        XCTAssertEqual(Helper.countForEntity("Element", inContext: dataStack.mainContext), 11)

        XCTAssertEqual(Helper.countForEntity("SelectionItem", inContext: dataStack.mainContext), 4)

        XCTAssertEqual(Helper.countForEntity("Model", inContext: dataStack.mainContext), 1)

        XCTAssertEqual(Helper.countForEntity("ModelProperty", inContext: dataStack.mainContext), 9)

        XCTAssertEqual(Helper.countForEntity("Restriction", inContext: dataStack.mainContext), 3)

        let array = Helper.fetchEntity("Form", inContext: dataStack.mainContext)
        let form = array.first!
        let element = form.value(forKey: "element") as! NSManagedObject
        let model = form.value(forKey: "model") as! NSManagedObject
        XCTAssertNotNil(element)
        XCTAssertNotNil(model)

        try! dataStack.drop()
    }

    func testStoryToSummarize() {
        let formDictionary = Helper.objectsFromJSON("story-summarize.json") as! [String: Any]
        let dataStack = Helper.dataStackWithModelName("Social")

        Sync.changes([formDictionary], inEntityNamed: "Story", predicate: NSPredicate(format: "remoteID == %@", NSNumber(value: 1)), dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("Story", inContext: dataStack.mainContext), 1)
        let stories = Helper.fetchEntity("Story", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 1)), inContext: dataStack.mainContext)
        let story = stories.first!
        let summarize = story.value(forKey: "summarize") as! NSManagedObject
        XCTAssertEqual(summarize.value(forKey: "remoteID") as? NSNumber, NSNumber(value: 1))
        XCTAssertEqual((story.value(forKey: "comments") as! NSSet).count, 1)

        XCTAssertEqual(Helper.countForEntity("SocialComment", inContext: dataStack.mainContext), 1)
        let comments = Helper.fetchEntity("SocialComment", predicate: NSPredicate(format: "body = %@", "Hi"), inContext: dataStack.mainContext)
        XCTAssertEqual(comments.count, 1)

        try! dataStack.drop()
    }

    /**
     * When having JSONs like this:
     * {
     *   "id":12345,
     *    "name":"My Project",
     *    "category_id":12345
     * }
     * It will should map category_id with the necesary category object using the ID 12345
     */
    func testIDRelationshipMapping() {
        let usersDictionary = Helper.objectsFromJSON("users_a.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("Notes")

        Sync.changes(usersDictionary, inEntityNamed: "SuperUser", dataStack: dataStack, completion: nil)

        let usersCount = Helper.countForEntity("SuperUser", inContext: dataStack.mainContext)
        XCTAssertEqual(usersCount, 8)

        let notesDictionary = Helper.objectsFromJSON("notes_with_user_id.json") as! [[String: Any]]

        Sync.changes(notesDictionary, inEntityNamed: "SuperNote", dataStack: dataStack, completion: nil)

        let notesCount = Helper.countForEntity("SuperNote", inContext: dataStack.mainContext)
        XCTAssertEqual(notesCount, 5)

        let notes = Helper.fetchEntity("SuperNote", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), inContext: dataStack.mainContext)
        let note = notes.first!
        let user = note.value(forKey: "superUser")!
        XCTAssertEqual((user as AnyObject).value(forKey: "name") as? String, "Melisa White")

        try! dataStack.drop()
    }

    /**
     * When having JSONs like this:
     * {
     *   "id":12345,
     *    "name":"My Project",
     *    "category":12345
     * }
     * It will should map category_id with the necesary category object using the ID 12345, but adding a custom remoteKey would make it map to category with ID 12345
     */
    func testIDRelationshipCustomMapping() {
        let usersDictionary = Helper.objectsFromJSON("users_a.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("NotesB")

        Sync.changes(usersDictionary, inEntityNamed: "SuperUserB", dataStack: dataStack, completion: nil)

        let usersCount = Helper.countForEntity("SuperUserB", inContext: dataStack.mainContext)
        XCTAssertEqual(usersCount, 8)

        let notesDictionary = Helper.objectsFromJSON("notes_with_user_id_custom.json") as! [[String: Any]]

        Sync.changes(notesDictionary, inEntityNamed: "SuperNoteB", dataStack: dataStack, completion: nil)

        let notesCount = Helper.countForEntity("SuperNoteB", inContext: dataStack.mainContext)
        XCTAssertEqual(notesCount, 5)

        let notes = Helper.fetchEntity("SuperNoteB", predicate: NSPredicate(format: "remoteID = %@", NSNumber(value: 0)), inContext: dataStack.mainContext)
        let note = notes.first!
        let user = note.value(forKey: "superUser")!
        XCTAssertEqual((user as AnyObject).value(forKey: "name") as? String, "Melisa White")

        try! dataStack.drop()
    }

    // MARK: - Ordered Social

    func testCustomPrimaryKeyInOrderedRelationship() {
        let objects = Helper.objectsFromJSON("comments-no-id.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("OrderedSocial")

        Sync.changes(objects, inEntityNamed: "Comment", dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("Comment", inContext: dataStack.mainContext), 8)
        let comments = Helper.fetchEntity("Comment", predicate: NSPredicate(format: "body = %@", "comment 1"), inContext: dataStack.mainContext)
        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual((comments.first!.value(forKey: "comments") as! NSOrderedSet).count, 3)

        let comment = comments.first!
        XCTAssertEqual(comment.value(forKey: "body") as? String, "comment 1")

        try! dataStack.drop()
    }

    // MARK: - Bug 179 => https://github.com/SyncDB/Sync/issues/179

    func testConnectMultipleRelationships() {
        let places = Helper.objectsFromJSON("bug-179-places.json") as! [[String: Any]]
        let routes = Helper.objectsFromJSON("bug-179-routes.json") as! [String: Any]
        let dataStack = Helper.dataStackWithModelName("Bug179")

        Sync.changes(places, inEntityNamed: "Place", dataStack: dataStack, completion: nil)
        Sync.changes([routes], inEntityNamed: "Route", dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("Route", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Place", inContext: dataStack.mainContext), 2)
        let importedRoutes = Helper.fetchEntity("Route", predicate: nil, inContext: dataStack.mainContext)
        XCTAssertEqual(importedRoutes.count, 1)
        let importedRouter = importedRoutes.first!
        XCTAssertEqual(importedRouter.value(forKey: "ident") as? String, "1")

        let startPlace = importedRoutes.first!.value(forKey: "startPlace") as! NSManagedObject
        let endPlace = importedRoutes.first!.value(forKey: "endPlace") as! NSManagedObject
        XCTAssertEqual(startPlace.value(forKey: "name") as? String, "Here")
        XCTAssertEqual(endPlace.value(forKey: "name") as? String, "There")

        try! dataStack.drop()
    }

    // MARK: - Bug 202 => https://github.com/SyncDB/Sync/issues/202

    func testManyToManyKeyNotAllowedHere() {
        let dataStack = Helper.dataStackWithModelName("Bug202")

        let initialInsert = Helper.objectsFromJSON("bug-202-a.json") as! [[String: Any]]
        Sync.changes(initialInsert, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 1)

        let removeAll = Helper.objectsFromJSON("bug-202-b.json") as! [[String: Any]]
        Sync.changes(removeAll, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 0)

        try! dataStack.drop()
    }

    // MARK: - Automatic use of id as remoteID

    func testIDAsRemoteID() {
        let dataStack = Helper.dataStackWithModelName("id")

        let users = Helper.objectsFromJSON("id.json") as! [[String: Any]]
        Sync.changes(users, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 2)

        try! dataStack.drop()
    }

    // MARK: - Bug 157 => https://github.com/SyncDB/Sync/issues/157

    func testBug157() {
        let dataStack = Helper.dataStackWithModelName("Bug157")

        // 3 locations get synced, their references get ignored since no cities are found
        let locations = Helper.objectsFromJSON("157-locations.json") as! [[String: Any]]
        Sync.changes(locations, inEntityNamed: "Location", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("Location", inContext: dataStack.mainContext), 3)
        XCTAssertEqual(Helper.countForEntity("City", inContext: dataStack.mainContext), 0)

        // 3 cities get synced
        let cities = Helper.objectsFromJSON("157-cities.json") as! [[String: Any]]
        Sync.changes(cities, inEntityNamed: "City", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("Location", inContext: dataStack.mainContext), 3)
        XCTAssertEqual(Helper.countForEntity("City", inContext: dataStack.mainContext), 3)

        // 3 locations get synced, but now since their references are available the relationships get made
        Sync.changes(locations, inEntityNamed: "Location", dataStack: dataStack, completion: nil)
        var location1 = Helper.fetchEntity("Location", predicate: NSPredicate(format: "locationID = 0"), inContext: dataStack.mainContext).first
        var location1City = location1?.value(forKey: "city") as? NSManagedObject
        XCTAssertEqual(location1City?.value(forKey: "name") as? String, "Oslo")
        var location2 = Helper.fetchEntity("Location", predicate: NSPredicate(format: "locationID = 1"), inContext: dataStack.mainContext).first
        var location2City = location2?.value(forKey: "city") as? NSManagedObject
        XCTAssertEqual(location2City?.value(forKey: "name") as? String, "Paris")
        var location3 = Helper.fetchEntity("Location", predicate: NSPredicate(format: "locationID = 2"), inContext: dataStack.mainContext).first
        var location3City = location3?.value(forKey: "city") as? NSManagedObject
        XCTAssertNil(location3City?.value(forKey: "name") as? String)

        // Finally we update the relationships to test changing relationships
        let updatedLocations = Helper.objectsFromJSON("157-locations-update.json") as! [[String: Any]]
        Sync.changes(updatedLocations, inEntityNamed: "Location", dataStack: dataStack, completion: nil)
        location1 = Helper.fetchEntity("Location", predicate: NSPredicate(format: "locationID = 0"), inContext: dataStack.mainContext).first
        location1City = location1?.value(forKey: "city") as? NSManagedObject
        XCTAssertNil(location1City?.value(forKey: "name") as? String)
        location2 = Helper.fetchEntity("Location", predicate: NSPredicate(format: "locationID = 1"), inContext: dataStack.mainContext).first
        location2City = location2?.value(forKey: "city") as? NSManagedObject
        XCTAssertEqual(location2City?.value(forKey: "name") as? String, "Oslo")
        location3 = Helper.fetchEntity("Location", predicate: NSPredicate(format: "locationID = 2"), inContext: dataStack.mainContext).first
        location3City = location3?.value(forKey: "city") as? NSManagedObject
        XCTAssertEqual(location3City?.value(forKey: "name") as? String, "Paris")

        try! dataStack.drop()
    }

    // MARK: - Add support for cancellable sync processes https://github.com/SyncDB/Sync/pull/216

    func testOperation() {
        let dataStack = Helper.dataStackWithModelName("id")

        let users = Helper.objectsFromJSON("id.json") as! [[String: Any]]
        let operation = Sync(changes: users, inEntityNamed: "User", predicate: nil, dataStack: dataStack)
        operation.start()
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 2)

        try! dataStack.drop()
    }

    // MARK: - Support multiple ids to set a relationship (to-many) => https://github.com/SyncDB/Sync/issues/151
    // Notes have to be unique, two users can't have the same note.

    func testMultipleIDRelationshipToMany() {
        let dataStack = Helper.dataStackWithModelName("151-to-many")

        // Inserts 3 users, it ignores the relationships since no notes are found
        let users = Helper.objectsFromJSON("151-to-many-users.json") as! [[String: Any]]
        Sync.changes(users, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 3)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: dataStack.mainContext), 0)

        // Inserts 3 notes
        let notes = Helper.objectsFromJSON("151-to-many-notes.json") as! [[String: Any]]
        Sync.changes(notes, inEntityNamed: "Note", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 3)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: dataStack.mainContext), 3)
        let savedUsers = Helper.fetchEntity("User", inContext: dataStack.mainContext)
        var total = 0
        for user in savedUsers {
            let notes = user.value(forKey: "notes") as? Set<NSManagedObject> ?? Set<NSManagedObject>()
            total += notes.count
        }
        XCTAssertEqual(total, 0)

        // Updates the first 3 users, but now it makes the relationships with the notes
        Sync.changes(users, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 3)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: dataStack.mainContext), 3)
        var user10 = Helper.fetchEntity("User", predicate: NSPredicate(format: "userID = 10"), inContext: dataStack.mainContext).first
        var user10Notes = user10?.value(forKey: "notes") as? Set<NSManagedObject>
        XCTAssertEqual(user10Notes?.count, 2)
        var user11 = Helper.fetchEntity("User", predicate: NSPredicate(format: "userID = 11"), inContext: dataStack.mainContext).first
        var user11Notes = user11?.value(forKey: "notes") as? Set<NSManagedObject>
        XCTAssertEqual(user11Notes?.count, 1)
        var user12 = Helper.fetchEntity("User", predicate: NSPredicate(format: "userID = 12"), inContext: dataStack.mainContext).first
        var user12Notes = user12?.value(forKey: "notes") as? Set<NSManagedObject>
        XCTAssertEqual(user12Notes?.count, 0)
        var note0 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 0"), inContext: dataStack.mainContext).first
        var note0User = note0?.value(forKey: "user") as? NSManagedObject
        XCTAssertEqual(note0User?.value(forKey: "userID") as? Int, 10)
        var note1 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 1"), inContext: dataStack.mainContext).first
        var note1User = note1?.value(forKey: "user") as? NSManagedObject
        XCTAssertEqual(note1User?.value(forKey: "userID") as? Int, 10)
        var note2 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 2"), inContext: dataStack.mainContext).first
        var note2User = note2?.value(forKey: "user") as? NSManagedObject
        XCTAssertEqual(note2User?.value(forKey: "userID") as? Int, 11)

        // Updates the first 3 users again, but now it changes all the relationships
        let updatedUsers = Helper.objectsFromJSON("151-to-many-users-update.json") as! [[String: Any]]
        Sync.changes(updatedUsers, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 3)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: dataStack.mainContext), 3)
        user10 = Helper.fetchEntity("User", predicate: NSPredicate(format: "userID = 10"), inContext: dataStack.mainContext).first
        user10Notes = user10?.value(forKey: "notes") as? Set<NSManagedObject>
        XCTAssertEqual(user10Notes?.count, 0)
        user11 = Helper.fetchEntity("User", predicate: NSPredicate(format: "userID = 11"), inContext: dataStack.mainContext).first
        user11Notes = user11?.value(forKey: "notes") as? Set<NSManagedObject>
        XCTAssertEqual(user11Notes?.count, 1)
        user12 = Helper.fetchEntity("User", predicate: NSPredicate(format: "userID = 12"), inContext: dataStack.mainContext).first
        user12Notes = user12?.value(forKey: "notes") as? Set<NSManagedObject>
        XCTAssertEqual(user12Notes?.count, 2)
        note0 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 0"), inContext: dataStack.mainContext).first
        note0User = note0?.value(forKey: "user") as? NSManagedObject
        XCTAssertEqual(note0User?.value(forKey: "userID") as? Int, 12)
        note1 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 1"), inContext: dataStack.mainContext).first
        note1User = note1?.value(forKey: "user") as? NSManagedObject
        XCTAssertEqual(note1User?.value(forKey: "userID") as? Int, 12)
        note2 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 2"), inContext: dataStack.mainContext).first
        note2User = note2?.value(forKey: "user") as? NSManagedObject
        XCTAssertEqual(note2User?.value(forKey: "userID") as? Int, 11)

        try! dataStack.drop()
    }

    // MARK: - Support multiple ids to set a relationship (to-many) => https://github.com/SyncDB/Sync/issues/151
    // Notes have to be unique, two users can't have the same note.

    func testOrderedMultipleIDRelationshipToMany() {
        let dataStack = Helper.dataStackWithModelName("151-ordered-to-many")

        // Inserts 3 users, it ignores the relationships since no notes are found
        let users = Helper.objectsFromJSON("151-to-many-users.json") as! [[String: Any]]
        Sync.changes(users, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 3)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: dataStack.mainContext), 0)

        // Inserts 3 notes
        let notes = Helper.objectsFromJSON("151-to-many-notes.json") as! [[String: Any]]
        Sync.changes(notes, inEntityNamed: "Note", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 3)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: dataStack.mainContext), 3)
        let savedUsers = Helper.fetchEntity("User", inContext: dataStack.mainContext)
        var total = 0
        for user in savedUsers {
            let notes = user.value(forKey: "notes") as? Set<NSManagedObject> ?? Set<NSManagedObject>()
            total += notes.count
        }
        XCTAssertEqual(total, 0)

        // Updates the first 3 users, but now it makes the relationships with the notes
        Sync.changes(users, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 3)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: dataStack.mainContext), 3)
        var user10 = Helper.fetchEntity("User", predicate: NSPredicate(format: "id = 10"), inContext: dataStack.mainContext).first
        var user10Notes = user10?.value(forKey: "notes") as? NSOrderedSet
        XCTAssertEqual(user10Notes?.set.count, 2)
        var user11 = Helper.fetchEntity("User", predicate: NSPredicate(format: "id = 11"), inContext: dataStack.mainContext).first
        var user11Notes = user11?.value(forKey: "notes") as? NSOrderedSet
        XCTAssertEqual(user11Notes?.set.count, 1)
        var user12 = Helper.fetchEntity("User", predicate: NSPredicate(format: "id = 12"), inContext: dataStack.mainContext).first
        var user12Notes = user12?.value(forKey: "notes") as? NSOrderedSet
        XCTAssertEqual(user12Notes?.set.count, 0)

        // Updates the first 3 users again, but now it changes all the relationships
        let updatedUsers = Helper.objectsFromJSON("151-to-many-users-update.json") as! [[String: Any]]
        Sync.changes(updatedUsers, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 3)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: dataStack.mainContext), 3)
        user10 = Helper.fetchEntity("User", predicate: NSPredicate(format: "id = 10"), inContext: dataStack.mainContext).first
        user10Notes = user10?.value(forKey: "notes") as? NSOrderedSet
        XCTAssertEqual(user10Notes?.set.count, 0)
        user11 = Helper.fetchEntity("User", predicate: NSPredicate(format: "id = 11"), inContext: dataStack.mainContext).first
        user11Notes = user11?.value(forKey: "notes") as? NSOrderedSet
        XCTAssertEqual(user11Notes?.set.count, 1)
        user12 = Helper.fetchEntity("User", predicate: NSPredicate(format: "id = 12"), inContext: dataStack.mainContext).first
        user12Notes = user12?.value(forKey: "notes") as? NSOrderedSet
        XCTAssertEqual(user12Notes?.set.count, 2)

        try! dataStack.drop()
    }

    // MARK: - Support multiple ids to set a relationship (many-to-many) => https://github.com/SyncDB/Sync/issues/151

    func testMultipleIDRelationshipManyToMany() {
        let dataStack = Helper.dataStackWithModelName("151-many-to-many")

        // Inserts 4 notes
        let notes = Helper.objectsFromJSON("151-many-to-many-notes.json") as! [[String: Any]]
        Sync.changes(notes, inEntityNamed: "Note", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: dataStack.mainContext), 4)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 0)

        // Inserts 3 tags
        let tags = Helper.objectsFromJSON("151-many-to-many-tags.json") as! [[String: Any]]
        Sync.changes(tags, inEntityNamed: "Tag", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: dataStack.mainContext), 4)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 2)
        let savedNotes = Helper.fetchEntity("Note", inContext: dataStack.mainContext)
        var total = 0
        for note in savedNotes {
            let tags = note.value(forKey: "tags") as? Set<NSManagedObject> ?? Set<NSManagedObject>()
            total += tags.count
        }
        XCTAssertEqual(total, 0)

        // Updates the first 4 notes, but now it makes the relationships with the tags
        Sync.changes(notes, inEntityNamed: "Note", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: dataStack.mainContext), 4)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 2)
        var note0 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 0"), inContext: dataStack.mainContext).first
        var note0Tags = note0?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(note0Tags?.count, 2)
        var note1 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 1"), inContext: dataStack.mainContext).first
        var note1Tags = note1?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(note1Tags?.count, 1)
        var note2 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 2"), inContext: dataStack.mainContext).first
        var note2Tags = note2?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(note2Tags?.count, 0)
        var note3 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 3"), inContext: dataStack.mainContext).first
        var note3Tags = note3?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(note3Tags?.count, 1)

        // Updates the first 4 notes again, but now it changes all the relationships
        let updatedNotes = Helper.objectsFromJSON("151-many-to-many-notes-update.json") as! [[String: Any]]
        XCTAssertEqual(Helper.countForEntity("Note", inContext: dataStack.mainContext), 4)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 2)
        Sync.changes(updatedNotes, inEntityNamed: "Note", dataStack: dataStack, completion: nil)
        note0 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 0"), inContext: dataStack.mainContext).first
        note0Tags = note0?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(note0Tags?.count, 1)
        note1 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 1"), inContext: dataStack.mainContext).first
        note1Tags = note1?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(note1Tags?.count, 0)
        note2 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 2"), inContext: dataStack.mainContext).first
        note2Tags = note2?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(note2Tags?.count, 2)
        note3 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "noteID = 3"), inContext: dataStack.mainContext).first
        note3Tags = note3?.value(forKey: "tags") as? Set<NSManagedObject>
        XCTAssertEqual(note3Tags?.count, 0)

        try! dataStack.drop()
    }

    // MARK: - Support multiple ids to set a relationship (many-to-many) => https://github.com/SyncDB/Sync/issues/151

    func testOrderedMultipleIDRelationshipManyToMany() {
        let dataStack = Helper.dataStackWithModelName("151-ordered-many-to-many")

        // Inserts 4 notes
        let notes = Helper.objectsFromJSON("151-many-to-many-notes.json") as! [[String: Any]]
        Sync.changes(notes, inEntityNamed: "Note", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: dataStack.mainContext), 4)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 0)

        // Inserts 3 tags
        let tags = Helper.objectsFromJSON("151-many-to-many-tags.json") as! [[String: Any]]
        Sync.changes(tags, inEntityNamed: "Tag", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: dataStack.mainContext), 4)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 2)
        let savedNotes = Helper.fetchEntity("Note", inContext: dataStack.mainContext)
        var total = 0
        for note in savedNotes {
            let tags = note.value(forKey: "tags") as? Set<NSManagedObject> ?? Set<NSManagedObject>()
            total += tags.count
        }
        XCTAssertEqual(total, 0)

        // Updates the first 4 notes, but now it makes the relationships with the tags
        Sync.changes(notes, inEntityNamed: "Note", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("Note", inContext: dataStack.mainContext), 4)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 2)
        var note0 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "id = 0"), inContext: dataStack.mainContext).first
        var note0Tags = note0?.value(forKey: "tags") as? NSOrderedSet
        XCTAssertEqual(note0Tags?.count, 2)
        var note1 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "id = 1"), inContext: dataStack.mainContext).first
        var note1Tags = note1?.value(forKey: "tags") as? NSOrderedSet
        XCTAssertEqual(note1Tags?.count, 1)
        var note2 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "id = 2"), inContext: dataStack.mainContext).first
        var note2Tags = note2?.value(forKey: "tags") as? NSOrderedSet
        XCTAssertEqual(note2Tags?.count, 0)
        var note3 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "id = 3"), inContext: dataStack.mainContext).first
        var note3Tags = note3?.value(forKey: "tags") as? NSOrderedSet
        XCTAssertEqual(note3Tags?.count, 1)

        // Updates the first 4 notes again, but now it changes all the relationships
        let updatedNotes = Helper.objectsFromJSON("151-many-to-many-notes-update.json") as! [[String: Any]]
        XCTAssertEqual(Helper.countForEntity("Note", inContext: dataStack.mainContext), 4)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 2)
        Sync.changes(updatedNotes, inEntityNamed: "Note", dataStack: dataStack, completion: nil)
        note0 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "id = 0"), inContext: dataStack.mainContext).first
        note0Tags = note0?.value(forKey: "tags") as? NSOrderedSet
        XCTAssertEqual(note0Tags?.set.count, 1)
        note1 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "id = 1"), inContext: dataStack.mainContext).first
        note1Tags = note1?.value(forKey: "tags") as? NSOrderedSet
        XCTAssertEqual(note1Tags?.set.count, 0)
        note2 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "id = 2"), inContext: dataStack.mainContext).first
        note2Tags = note2?.value(forKey: "tags") as? NSOrderedSet
        XCTAssertEqual(note2Tags?.set.count, 2)
        note3 = Helper.fetchEntity("Note", predicate: NSPredicate(format: "id = 3"), inContext: dataStack.mainContext).first
        note3Tags = note3?.value(forKey: "tags") as? NSOrderedSet
        XCTAssertEqual(note3Tags?.count, 0)

        try! dataStack.drop()
    }

    // MARK: - Bug 257 => https://github.com/SyncDB/Sync/issues/257

    func testBug257() {
        let dataStack = Helper.dataStackWithModelName("Bug257")

        let JSON = Helper.objectsFromJSON("bug-257.json") as! [String: Any]
        Sync.changes([JSON], inEntityNamed: "Workout", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("Workout", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Exercise", inContext: dataStack.mainContext), 2)

        try! dataStack.drop()
    }

    // MARK: - Bug 254 => https://github.com/SyncDB/Sync/issues/254

    func testBug254() {
        let dataStack = Helper.dataStackWithModelName("Bug254")

        let JSON = Helper.objectsFromJSON("bug-254.json") as! [String: Any]
        Sync.changes([JSON], inEntityNamed: "House", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("House", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Human", inContext: dataStack.mainContext), 1)

        // Verify correct "House -> Resident" connections
        let house = Helper.fetchEntity("House", predicate: NSPredicate(format: "id = 0"), inContext: dataStack.mainContext).first
        let residents = house?.value(forKey: "residents") as? Set<NSManagedObject>
        let resident = residents?.first
        XCTAssertEqual(resident?.value(forKey: "id") as? Int, 0)

        let residentHouse = resident?.value(forKey: "residenthouse") as? NSManagedObject
        XCTAssertEqual(residentHouse?.value(forKey: "id") as? Int, 0)

        // Verify empty "Ownhouses -> Owners" connections
        let human = Helper.fetchEntity("Human", predicate: NSPredicate(format: "id = 0"), inContext: dataStack.mainContext).first
        let ownhouses = human?.value(forKey: "ownhouses") as? Set<NSManagedObject>
        XCTAssertEqual(ownhouses?.count, 0)

        try! dataStack.drop()
    }

    // MARK: Bug 260 => https://github.com/SyncDB/Sync/issues/260

    func testBug260CamelCase() {
        let dataStack = Helper.dataStackWithModelName("ToOne")

        let snakeCaseJSON = Helper.objectsFromJSON("to-one-snakecase.json") as! [String: Any]
        Sync.changes([snakeCaseJSON], inEntityNamed: "RentedHome", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("RentedHome", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("LegalPerson", inContext: dataStack.mainContext), 1)

        try! dataStack.drop()
    }

    func testBug260SnakeCase() {
        let dataStack = Helper.dataStackWithModelName("ToOne")

        let camelCaseJSON = Helper.objectsFromJSON("to-one-camelcase.json") as! [String: Any]
        Sync.changes([camelCaseJSON], inEntityNamed: "RentedHome", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("RentedHome", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("LegalPerson", inContext: dataStack.mainContext), 1)

        try! dataStack.drop()
    }

    // MARK: Bug 239 => https://github.com/SyncDB/Sync/pull/239

    func testBug239() {
        let carsObject = Helper.objectsFromJSON("bug-239.json") as! [[String: Any]]
        let dataStack = Helper.dataStackWithModelName("Bug239")
        Sync.changes(carsObject, inEntityNamed: "Racecar", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("Racecar", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Passenger", inContext: dataStack.mainContext), 2)

        let racecars = Helper.fetchEntity("Racecar", predicate: nil, inContext: dataStack.mainContext)
        let racecar = racecars.first!
        XCTAssertEqual((racecar.value(forKey: "passengers") as? NSSet)!.allObjects.count, 2)

        try! dataStack.drop()
    }

    // MARK: - https://github.com/SyncDB/Sync/issues/225

    func test225ReplacedTag() {
        let dataStack = Helper.dataStackWithModelName("225")

        let usersA = Helper.objectsFromJSON("225-a.json") as! [[String: Any]]
        Sync.changes(usersA, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 1)

        // This should remove the old tag reference to the user and insert this new one.
        let usersB = Helper.objectsFromJSON("225-a-replaced.json") as! [[String: Any]]
        Sync.changes(usersB, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 2)

        let user = Helper.fetchEntity("User", inContext: dataStack.mainContext).first!
        let predicate = NSPredicate(format: "ANY users IN %@", [user])
        let tags = Helper.fetchEntity("Tag", predicate: predicate, inContext: dataStack.mainContext)
        XCTAssertEqual(tags.count, 1)

        try! dataStack.drop()
    }

    func test225RemovedTagsWithEmptyArray() {
        let dataStack = Helper.dataStackWithModelName("225")

        let usersA = Helper.objectsFromJSON("225-a.json") as! [[String: Any]]
        Sync.changes(usersA, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 1)

        // This should remove all the references.
        let usersB = Helper.objectsFromJSON("225-a-empty.json") as! [[String: Any]]
        Sync.changes(usersB, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 1)

        // WARNING: Maybe this shouldn't be 0, but should be 1 instead, since it shouldn't delete the
        // object, but instead, it should just remove the reference.
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 0)

        let user = Helper.fetchEntity("User", inContext: dataStack.mainContext).first!
        let predicate = NSPredicate(format: "ANY users IN %@", [user])
        let tags = Helper.fetchEntity("Tag", predicate: predicate, inContext: dataStack.mainContext)
        XCTAssertEqual(tags.count, 0)

        try! dataStack.drop()
    }

    func test225RemovedTagsWithNull() {
        let dataStack = Helper.dataStackWithModelName("225")

        let usersA = Helper.objectsFromJSON("225-a.json") as! [[String: Any]]
        Sync.changes(usersA, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 1)

        // WARNING: Maybe this shouldn't be 0, but should be 1 instead, since it shouldn't delete the
        // object, but instead, it should just remove the reference.
        let usersB = Helper.objectsFromJSON("225-a-null.json") as! [[String: Any]]
        Sync.changes(usersB, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 0)

        let user = Helper.fetchEntity("User", inContext: dataStack.mainContext).first!
        let predicate = NSPredicate(format: "ANY users IN %@", [user])
        let tags = Helper.fetchEntity("Tag", predicate: predicate, inContext: dataStack.mainContext)
        XCTAssertEqual(tags.count, 0)

        try! dataStack.drop()
    }

    func test280() {
        let dataStack = Helper.dataStackWithModelName("280")

        let routes = Helper.objectsFromJSON("280.json") as! [[String: Any]]
        Sync.changes(routes, inEntityNamed: "Route", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("Route", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("RoutePolylineItem", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("RouteStop", inContext: dataStack.mainContext), 1)

        Sync.changes(routes, inEntityNamed: "Route", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("Route", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("RoutePolylineItem", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("RouteStop", inContext: dataStack.mainContext), 1)

        try! dataStack.drop()
    }

    func test283() {
        let dataStack = Helper.dataStackWithModelName("283")

        let taskLists = Helper.objectsFromJSON("283.json") as! [[String: Any]]
        Sync.changes(taskLists, inEntityNamed: "TaskList", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("TaskList", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Owner", inContext: dataStack.mainContext), 1)

        let taskList = Helper.fetchEntity("TaskList", inContext: dataStack.mainContext).first!
        let owner = taskList.value(forKey: "owner") as? NSManagedObject
        XCTAssertNotNil(owner)

        let participants = taskList.value(forKey: "participants") as? NSSet ?? NSSet()
        XCTAssertEqual(participants.count, 0)

        try! dataStack.drop()
    }

    func test320RemoveOneToToneWithNull() {
        let dataStack = Helper.dataStackWithModelName("320")

        let tagA = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: dataStack.mainContext)
        tagA.setValue(10, forKey: "remoteID")

        let userA = NSEntityDescription.insertNewObject(forEntityName: "User", into: dataStack.mainContext)
        userA.setValue(1, forKey: "remoteID")
        userA.setValue(tagA, forKey: "tag")

        try! dataStack.mainContext.save()

        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 1)

        let usersB = Helper.objectsFromJSON("320.json") as! [[String: Any]]
        Sync.changes(usersB, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Tag", inContext: dataStack.mainContext), 1)

        let user = Helper.fetchEntity("User", inContext: dataStack.mainContext).first!
        let predicate = NSPredicate(format: "ANY user = %@", user)
        let tag = Helper.fetchEntity("Tag", predicate: predicate, inContext: dataStack.mainContext)
        XCTAssertEqual(tag.count, 0)

        try! dataStack.drop()
    }

    func test233() {
        let dataStack = Helper.dataStackWithModelName("233")

        let slide1 = NSEntityDescription.insertNewObject(forEntityName: "Slide", into: dataStack.mainContext)
        slide1.setValue(1, forKey: "id")

        let slide2 = NSEntityDescription.insertNewObject(forEntityName: "Slide", into: dataStack.mainContext)
        slide2.setValue(2, forKey: "id")

        let presentation = NSEntityDescription.insertNewObject(forEntityName: "Presentation", into: dataStack.mainContext)
        presentation.setValue(1, forKey: "id")

        let slides = NSMutableOrderedSet()
        slides.add(slide1)
        slides.add(slide2)

        presentation.setValue(slides, forKey: "slides")

        try! dataStack.mainContext.save()

        XCTAssertEqual(Helper.countForEntity("Presentation", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Slide", inContext: dataStack.mainContext), 2)
        let lastSlide = Helper.fetchEntity("Presentation", inContext: dataStack.mainContext).first!.mutableOrderedSetValue(forKey: "slides").lastObject as! NSManagedObject
        let lastSlideID = lastSlide.value(forKey: "id") as! Int
        XCTAssertEqual(lastSlideID, 2)

        // Change order of slides, before it was [1, 2], now it will be [2, 1]
        let presentationOrderB = Helper.objectsFromJSON("233.json") as! [[String: Any]]
        Sync.changes(presentationOrderB, inEntityNamed: "Presentation", dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("Presentation", inContext: dataStack.mainContext), 1)

        let firstSlide = Helper.fetchEntity("Presentation", inContext: dataStack.mainContext).first!.mutableOrderedSetValue(forKey: "slides").firstObject as! NSManagedObject
        let firstSlideID = firstSlide.value(forKey: "id") as! Int

        // check if order is properly updated
        XCTAssertEqual(firstSlideID, lastSlideID)

        try! dataStack.drop()
    }

    // https://github.com/SyncDB/Sync/issues/327

    func test327OrderedToMany() {
        let dataStack = Helper.dataStackWithModelName("233")

        let slide1 = NSEntityDescription.insertNewObject(forEntityName: "Slide", into: dataStack.mainContext)
        slide1.setValue(1, forKey: "id")

        let slide2 = NSEntityDescription.insertNewObject(forEntityName: "Slide", into: dataStack.mainContext)
        slide2.setValue(2, forKey: "id")

        let presentation = NSEntityDescription.insertNewObject(forEntityName: "Presentation", into: dataStack.mainContext)
        presentation.setValue(1, forKey: "id")

        let slides = NSMutableOrderedSet()
        slides.add(slide1)
        slides.add(slide2)

        presentation.setValue(slides, forKey: "slides")

        try! dataStack.mainContext.save()

        XCTAssertEqual(Helper.countForEntity("Presentation", inContext: dataStack.mainContext), 1)
        XCTAssertEqual(Helper.countForEntity("Slide", inContext: dataStack.mainContext), 2)
        let lastSlide = Helper.fetchEntity("Presentation", inContext: dataStack.mainContext).first!.mutableOrderedSetValue(forKey: "slides").lastObject as! NSManagedObject
        let lastSlideID = lastSlide.value(forKey: "id") as! Int
        XCTAssertEqual(lastSlideID, 2)

        // Change order of slides, before it was [1, 2], now it will be [2, 1]
        let presentationOrderB = Helper.objectsFromJSON("237.json") as! [[String: Any]]
        Sync.changes(presentationOrderB, inEntityNamed: "Presentation", dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("Presentation", inContext: dataStack.mainContext), 1)

        let firstSlide = Helper.fetchEntity("Presentation", inContext: dataStack.mainContext).first!.mutableOrderedSetValue(forKey: "slides").firstObject as! NSManagedObject
        let firstSlideID = firstSlide.value(forKey: "id") as! Int

        // check if order is properly updated
        XCTAssertEqual(firstSlideID, lastSlideID)

        try! dataStack.drop()
    }

    // https://github.com/SyncDB/Sync/issues/265

    func test265() {
        let dataStack = Helper.dataStackWithModelName("265")
        let players = Helper.objectsFromJSON("265.json") as! [[String: Any]]
        Sync.changes(players, inEntityNamed: "Player", dataStack: dataStack, completion: nil)

        // Player 1
        // Has one player group: 1

        // Player group 1
        // This player group has two players: [1]

        // This should be 1, but sadly it's two :(
        XCTAssertEqual(Helper.countForEntity("Player", inContext: dataStack.mainContext), 2)
        XCTAssertEqual(Helper.countForEntity("PlayerGroup", inContext: dataStack.mainContext), 1)
        try! dataStack.drop()
    }

    func test3ca82a0() {
        let dataStack = Helper.dataStackWithModelName("3ca82a0")

        let taskLists = Helper.objectsFromJSON("3ca82a0.json") as! [[String: Any]]
        Sync.changes(taskLists, inEntityNamed: "Article", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("Article", inContext: dataStack.mainContext), 2)
        XCTAssertEqual(Helper.countForEntity("ArticleTag", inContext: dataStack.mainContext), 1)

        try! dataStack.drop()
    }
}
