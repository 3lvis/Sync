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
            let objects = Helper.objectsFromJSON("camelcase.json") as! [[String: Any]]

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

            let persistentContainer = Helper.persistentStoreWithModelName("Camelcase")
            let objects = Helper.objectsFromJSON("camelcase.json") as! [[String: Any]]

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

    func testInsertOrUpdate() {
        if #available(iOS 10, *) {
            let expectation = self.expectation(description: "testSkipTestMode")
            let persistentContainer = Helper.persistentStoreWithModelName("Tests")
            let json = ["id": 1]
            persistentContainer.insertOrUpdate(json, inEntityNamed: "User") { result in
                switch result {
                case .success:
                    XCTAssertEqual(1, Helper.countForEntity("User", inContext: persistentContainer.viewContext))
                case .failure:
                    XCTFail()
                }

                expectation.fulfill()
            }
            self.waitForExpectations(timeout: 150.0, handler: nil)
        }
    }

    func testUpdate() {
        if #available(iOS 10, *) {
            let expectation = self.expectation(description: "testSkipTestMode")
            let persistentContainer = Helper.persistentStoreWithModelName("id")
            let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: persistentContainer.viewContext)
            user.setValue("id", forKey: "id")
            try! persistentContainer.viewContext.save()

            XCTAssertEqual(1, Helper.countForEntity("User", inContext: persistentContainer.viewContext))
            persistentContainer.update("id", with: ["name": "bossy"], inEntityNamed: "User") { result in
                switch result {
                case .success(let id):
                    XCTAssertEqual(id as? String, "id")
                    XCTAssertEqual(1, Helper.countForEntity("User", inContext: persistentContainer.viewContext))

                    persistentContainer.viewContext.refresh(user, mergeChanges: false)

                    XCTAssertEqual(user.value(forKey: "name") as? String, "bossy")
                case .failure:
                    XCTFail()
                }

                expectation.fulfill()
            }

            self.waitForExpectations(timeout: 150.0, handler: nil)
        }
    }

    func testDelete() {
        let expectation = self.expectation(description: "testSkipTestMode")
        let persistentContainer = Helper.persistentStoreWithModelName("id")
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: persistentContainer.viewContext)
        user.setValue("id", forKey: "id")
        try! persistentContainer.viewContext.save()

        XCTAssertEqual(1, Helper.countForEntity("User", inContext: persistentContainer.viewContext))
        persistentContainer.delete("id", inEntityNamed: "User") { error in
            XCTAssertEqual(0, Helper.countForEntity("User", inContext: persistentContainer.viewContext))
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 150.0, handler: nil)
    }
}
