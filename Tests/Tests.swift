import XCTest
import DATAStack
import Sync

class Tests: XCTestCase {
    // MARK: - Contacts

    func testLoadAndUpdateUsers() {
        let dataStack = Helper.dataStackWithModelName("Contacts")

        let objectsA = Helper.objectsFromJSON("users_a.json") as! [[String : AnyObject]]
        Sync.changes(objectsA, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext: dataStack.mainContext), 8)

        let objectsB = Helper.objectsFromJSON("users_b.json") as! [[String : AnyObject]]
        Sync.changes(objectsB, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext:dataStack.mainContext), 6)

        let result = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(int: 7)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext: dataStack.mainContext).first!
        XCTAssertEqual(result.valueForKey("email") as? String, "secondupdated@ovium.com")

        let dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd"
        dateFormat.timeZone = NSTimeZone(name: "GMT")

        let createdDate = dateFormat.dateFromString("2014-02-14")
        XCTAssertEqual(result.valueForKey("createdAt") as? NSDate, createdDate);

        let updatedDate = dateFormat.dateFromString("2014-02-17")
        XCTAssertEqual(result.valueForKey("updatedAt") as? NSDate, updatedDate)
        
        dataStack.drop()
    }

    func testUsersAndCompanies() {
        let dataStack = Helper.dataStackWithModelName("Contacts")

        let objects = Helper.objectsFromJSON("users_company.json") as! [[String : AnyObject]]
        Sync.changes(objects, inEntityNamed: "User", dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("User", inContext:dataStack.mainContext), 5);
        let user = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(int: 0)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext:dataStack.mainContext).first!
        XCTAssertEqual((user.valueForKey("company")! as? NSManagedObject)!.valueForKey("name") as? String, "Apple")

        XCTAssertEqual(Helper.countForEntity("Company", inContext:dataStack.mainContext), 2)
        let company = Helper.fetchEntity("Company", predicate: NSPredicate(format: "remoteID = %@", NSNumber(int: 1)), sortDescriptors: [NSSortDescriptor(key: "remoteID", ascending: true)], inContext:dataStack.mainContext).first!
        XCTAssertEqual(company.valueForKey("name") as? String, "Facebook")
        
        dataStack.drop()
    }

    func testCustomMappingAndCustomPrimaryKey() {
        let dataStack = Helper.dataStackWithModelName("Contacts")
        let objects = Helper.objectsFromJSON("images.json") as! [[String : AnyObject]]
        Sync.changes(objects, inEntityNamed: "Image", dataStack: dataStack, completion: nil)

        let array = Helper.fetchEntity("Image", sortDescriptors: [NSSortDescriptor(key: "url", ascending: true)], inContext: dataStack.mainContext)
        XCTAssertEqual(array.count, 3)
        let image = array.first
        XCTAssertEqual(image!.valueForKey("url") as? String, "http://sample.com/sample0.png")

        dataStack.drop()
    }

    func testRelationshipsB() {
        let dataStack = Helper.dataStackWithModelName("Contacts")

        let objects = Helper.objectsFromJSON("users_c.json") as! [[String : AnyObject]]
        Sync.changes(objects, inEntityNamed: "User", dataStack: dataStack, completion: nil)
        XCTAssertEqual(Helper.countForEntity("User", inContext:dataStack.mainContext), 4);

        let users = Helper.fetchEntity("User", predicate: NSPredicate(format: "remoteID = %@", NSNumber(int: 6)), inContext:dataStack.mainContext)
        let user = users.first!
        XCTAssertEqual(user.valueForKey("name") as? String, "Shawn Merrill")

        let location = user.valueForKey("location") as! NSManagedObject
        XCTAssertEqual(location.valueForKey("city") as? String, "New York")
        XCTAssertEqual(location.valueForKey("street") as? String, "Broadway")
        XCTAssertEqual(location.valueForKey("zipCode") as? NSNumber, NSNumber(int: 10012))

        let profilePicturesCount = Helper.countForEntity("Image", predicate: NSPredicate(format: "user = %@", user), inContext:dataStack.mainContext)
        XCTAssertEqual(profilePicturesCount, 3);

        dataStack.drop()
    }

    // MARK: - Notes

    func testRelationshipsA() {
        let objects = Helper.objectsFromJSON("users_notes.json") as! [[String : AnyObject]]
        let dataStack = Helper.dataStackWithModelName("Notes")

        Sync.changes(objects, inEntityNamed: "SuperUser", dataStack: dataStack, completion: nil)

        XCTAssertEqual(Helper.countForEntity("SuperUser", inContext:dataStack.mainContext), 4)
        let users = Helper.fetchEntity("SuperUser", predicate: NSPredicate(format:"remoteID = %@", NSNumber(int: 6)), inContext:dataStack.mainContext)
        let user = users.first!
        XCTAssertEqual(user.valueForKey("name") as? String, "Shawn Merrill")

        let notesCount = Helper.countForEntity("SuperNote", predicate: NSPredicate(format:"superUser = %@", user), inContext:dataStack.mainContext)
        XCTAssertEqual(notesCount, 5);
        
        dataStack.drop()
    }

    func testObjectsForParent() {
        let objects = Helper.objectsFromJSON("notes_for_user_a.json") as! [[String : AnyObject]]
        let dataStack = Helper.dataStackWithModelName("Notes")
        dataStack.performInNewBackgroundContext { backgroundContext in
            // First, we create a parent user, this user is the one that will own all the notes
            let user = NSEntityDescription.insertNewObjectForEntityForName("SuperUser", inManagedObjectContext:backgroundContext)
            user.setValue(NSNumber(int: 6), forKey: "remoteID")
            user.setValue("Shawn Merrill", forKey: "name")
            user.setValue("firstupdate@ovium.com", forKey: "email")

            try! backgroundContext.save()
            dataStack.persistWithCompletion(nil)
        }

        // Then we fetch the user on the main context, because we don't want to break things between contexts
        var users = Helper.fetchEntity("SuperUser", predicate: NSPredicate(format:"remoteID = %@", NSNumber(int: 6)), inContext:dataStack.mainContext)
        XCTAssertEqual(users.count, 1)

        // Finally we say "Sync all the notes, for this user"
        Sync.changes(objects, inEntityNamed:"SuperNote", parent:users.first!, dataStack:dataStack, completion:nil)

        // Here we just make sure that the user has the notes that we just inserted
        users = Helper.fetchEntity("SuperUser", predicate: NSPredicate(format:"remoteID = %@", NSNumber(int: 6)), inContext: dataStack.mainContext)
        let user = users.first!
        XCTAssertEqual(user.valueForKey("name") as? String, "Shawn Merrill")
        
        let notesCount = Helper.countForEntity("SuperNote", predicate: NSPredicate(format:"superUser = %@", user), inContext:dataStack.mainContext)
        XCTAssertEqual(notesCount, 5)
        
        dataStack.drop()
    }
}
