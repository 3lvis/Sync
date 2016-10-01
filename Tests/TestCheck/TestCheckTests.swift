import XCTest

class TestCheckTests: XCTestCase {
    func testIsRunning() {
        XCTAssertTrue(TestCheck.isTesting)
    }
}
