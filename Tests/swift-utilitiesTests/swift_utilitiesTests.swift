import XCTest
@testable import swift_utilities

final class swift_utilitiesTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(swift_utilities().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
