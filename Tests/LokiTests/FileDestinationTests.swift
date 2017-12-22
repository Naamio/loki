import Foundation
import XCTest

@testable import Loki

class FileDestinationTests: XCTestCase {
    let fileManager = FileManager()

    static var allTests = [
        ("testNormalLog", testNormalLog),
        ("testFileCreation", testFileCreation),
        ("testMultipleLogs", testMultipleLogs),
    ]

    func getDateFormatter() -> DateFormatter {
        /// Default ISO datetime formatting.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter
    }

    override func setUp() {
        Loki.destinations = []
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testNormalLog() {
        let file = FileDestination(inPath: "foo.log")!
        let logWritten = expectation(description: "log written to file")
        let formatter = getDateFormatter()

        Loki.dateFormatter = formatter
        Loki.addDestination(file)
        Loki.logLevel = .info
        Loki.info("Hi")
        let line = #line
        let date = formatter.string(from: Date())
        let contents = try! String(contentsOf: file.url, encoding: .utf8)
        XCTAssertEqual(contents,
                       "[\(date)] [INFO] [:FileDestinationTests.swift:\(line - 1) testNormalLog()] Hi\n")
        logWritten.fulfill()
        try! fileManager.removeItem(at: file.url)

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }

    func testFileCreation() {
        let file = FileDestination(inPath: "foo.log")!
        XCTAssertTrue(fileManager.fileExists(atPath: "foo.log"))
        try! fileManager.removeItem(at: file.url)
    }

    func testMultipleLogs() {
        let file = FileDestination(inPath: "foo.log")!
        let formatter = getDateFormatter()
        Loki.dateFormatter = formatter
        Loki.addDestination(file)
        Loki.logLevel = .info
        Loki.info("Hi")
        let line = #line
        Loki.error("Hello")
        let date = formatter.string(from: Date())
        let contents = try! String(contentsOf: file.url, encoding: .utf8)

        let expected = """
[\(date)] [INFO] [:FileDestinationTests.swift:\(line - 1) testMultipleLogs()] Hi
[\(date)] [ERROR] [:FileDestinationTests.swift:\(line + 1) testMultipleLogs()] Hello

"""
        XCTAssertEqual(contents, expected)
        try! fileManager.removeItem(at: file.url)
    }
}
