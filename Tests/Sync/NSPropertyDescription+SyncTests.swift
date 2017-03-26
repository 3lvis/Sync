import XCTest
import CoreData
@testable import Sync

class NSPropertyDescription_SyncTests: XCTestCase {
    func testOldCustomKey() {
        let dataStack = Helper.dataStackWithModelName("RemoteKey")

        if let entity = NSEntityDescription.entity(forEntityName: "Entity", in: dataStack.mainContext) {
            let dayAttribute = entity.sync_attributes().filter { $0.name == "old" }.first
            if let dayAttribute = dayAttribute {
                XCTAssertEqual(dayAttribute.customKey, "custom_old")
            } else {
                XCTFail()
            }
        } else {
            XCTFail()
        }

        dataStack.drop()
    }

    func testCurrentCustomKey() {
        let dataStack = Helper.dataStackWithModelName("RemoteKey")

        if let entity = NSEntityDescription.entity(forEntityName: "Entity", in: dataStack.mainContext) {
            let dayAttribute = entity.sync_attributes().filter { $0.name == "current" }.first
            if let dayAttribute = dayAttribute {
                XCTAssertEqual(dayAttribute.customKey, "custom_current")
            } else {
                XCTFail()
            }
        } else {
            XCTFail()
        }

        dataStack.drop()
    }

    func testIsCustomPrimaryKey() {
        // TODO
    }

    func testShouldExportAttribute() {
        // TODO
    }

    func testCustomTransformerName() {
        // TODO
    }
}
