import XCTest
import DATAStack
import CoreData

class NSPersistentContainerTests: XCTestCase {
    func testPersistentContainer() {
        if #available(iOS 10, *) {
            let expectation = self.expectation(description: "testSkipTestMode")

            let momdModelURL = Bundle(for: NSPersistentContainerTests.self).url(forResource: "Camelcase", withExtension: "momd")!
            let model = NSManagedObjectModel(contentsOf: momdModelURL)!
            let persistentContainer = NSPersistentContainer(name: "Camelcase", managedObjectModel: model)
            try! persistentContainer.persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
            let objects = Helper.objectsFromJSON("camelcase.json") as! [[String : Any]]

            Sync.changes(objects, inEntityNamed: "NormalUser", predicate: nil, persistentContainer: persistentContainer) { error in
                let result = Helper.fetchEntity("NormalUser", inContext: persistentContainer.viewContext)
                XCTAssertEqual(result.count, 1)

                if let first = result.first {
                    XCTAssertEqual(first.value(forKey: "etternavn") as? String, "Nuñez")
                    XCTAssertEqual(first.value(forKey: "firstName") as? String, "Elvis")
                    XCTAssertEqual(first.value(forKey: "fullName") as? String, "Elvis Nuñez")
                    XCTAssertEqual(first.value(forKey: "numberOfChildren") as? Int, 1)
                    XCTAssertEqual(first.value(forKey: "remoteID") as? String, "1")
                } else {
                    XCTFail()
                }

                expectation.fulfill()
            }
            
            self.waitForExpectations(timeout: 150.0, handler: nil)
        }
   }

    func testPersistentContainerExtension() {
        if #available(iOS 10, *) {
            let expectation = self.expectation(description: "testSkipTestMode")

            let momdModelURL = Bundle(for: NSPersistentContainerTests.self).url(forResource: "Camelcase", withExtension: "momd")!
            let model = NSManagedObjectModel(contentsOf: momdModelURL)!
            let persistentContainer = NSPersistentContainer(name: "Camelcase", managedObjectModel: model)
            try! persistentContainer.persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
            let objects = Helper.objectsFromJSON("camelcase.json") as! [[String : Any]]

            persistentContainer.sync(objects, inEntityNamed: "NormalUser") { error in
                let result = Helper.fetchEntity("NormalUser", inContext: persistentContainer.viewContext)
                XCTAssertEqual(result.count, 1)

                if let first = result.first {
                    XCTAssertEqual(first.value(forKey: "etternavn") as? String, "Nuñez")
                    XCTAssertEqual(first.value(forKey: "firstName") as? String, "Elvis")
                    XCTAssertEqual(first.value(forKey: "fullName") as? String, "Elvis Nuñez")
                    XCTAssertEqual(first.value(forKey: "numberOfChildren") as? Int, 1)
                    XCTAssertEqual(first.value(forKey: "remoteID") as? String, "1")
                } else {
                    XCTFail()
                }

                expectation.fulfill()
            }

            self.waitForExpectations(timeout: 150.0, handler: nil)
        }
    }
}
