import Foundation
import XCTest
@testable import Loki

class ConsoleDestinationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Loki.removeAllDestinations()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSendsToConsole() {
        let log = Loki.self
        let console = ConsoleDestination()
        XCTAssertTrue(log.addDestination(console))
        log.info("Writing to console for test")
        XCTAssertEqual(console.reset, "")
        XCTAssertEqual(console.escape, "")
    }
    
    // MARK: Linux allTests
    static let allTests = [
        ("testSendsToConsole", testSendsToConsole)
    ]
}
