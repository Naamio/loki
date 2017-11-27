import Foundation
import XCTest

@testable import Loki

class FileBackendTests: XCTestCase {
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
        try! fileManager.removeItem(at: file.url)

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }

    func testFileCreation() {
        let file = FileBackend(inPath: "foo.log")!
        XCTAssertTrue(fileManager.fileExists(atPath: "foo.log"))
        try! fileManager.removeItem(at: file.url)
    }

    func testMultipleLogs() {
        let file = FileBackend(inPath: "foo.log")!
        let formatter = getDateFormatter()
        Loki.dateFormatter = formatter
        Loki.addBackend(file)
        Loki.logLevel = .info
        Loki.info("Hi")
        let line = #line
        Loki.error("Hello")
        let date = formatter.string(from: Date())
        let contents = try! String(contentsOf: file.url, encoding: .utf8)

        let expected = """
[\(date)] [INFO] [FileBackendTests.swift:\(line - 1) testMultipleLogs()] Hi
[\(date)] [ERROR] [FileBackendTests.swift:\(line + 1) testMultipleLogs()] Hello

"""
        XCTAssertEqual(contents, expected)
        try! fileManager.removeItem(at: file.url)
    }
}
