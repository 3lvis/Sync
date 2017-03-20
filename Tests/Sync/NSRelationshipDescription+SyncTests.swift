import XCTest
import CoreData
@testable import Sync

class NSRelationshipDescription_SyncTests: XCTestCase {
    func testCustomKey() {
        let dataStack = Helper.dataStackWithModelName("HyperRemoteKey")

        if let entity = NSEntityDescription.entity(forEntityName: "Entity", in: dataStack.mainContext) {
            let dayAttribute = entity.sync_attributes().filter { $0.name == "day" }.first
            if let dayAttribute = dayAttribute {
                XCTAssertEqual(dayAttribute.customKey, "custom")
            } else {
                XCTFail()
            }
        } else {
            XCTFail()
        }

        dataStack.drop()
    }
}
