import Foundation
import XCTest

@testable import Loki

class FileBackendTests: XCTestCase {
    static var allTests = [
        ("testNormalLog", testNormalLog),
    ]

    func getDateFormatter() -> DateFormatter {
        /// Default ISO datetime formatting.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter
    }

    override func setUp() {
        Loki.backends = []
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testNormalLog() {
        let file = FileBackend(inPath: "foo.log")!
        let logWritten = expectation(description: "log written to file")
        let formatter = getDateFormatter()

        Loki.dateFormatter = formatter
        Loki.addBackend(file)
        Loki.logLevel = .info
        Loki.info("Hi")
        let line = #line
        let date = formatter.string(from: Date())
        let contents = try! String(contentsOf: file.url, encoding: .utf8)
        XCTAssertEqual(contents,
                       "[\(date)] [INFO] [FileBackendTests.swift:\(line - 1) testNormalLog()] Hi\n")
        logWritten.fulfill()
        try! FileManager().removeItem(at: file.url)

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }
}
