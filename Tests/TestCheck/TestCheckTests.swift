import XCTest
import Sync

class TestCheckTests: XCTestCase {
    func testIsRunning() {
        XCTAssertTrue(TestCheck.isTesting)
    }
}
