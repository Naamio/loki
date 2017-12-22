import Foundation
import XCTest

@testable import Loki

class StringDestination {
    var string = ""
}

extension StringDestination: BaseDestination {
    public func writeLog(_ logData: LogMessage) {
        self.string += logData.toString()
    }
}

class LoggingTests: XCTestCase {
    func getDateFormatter() -> DateFormatter {
        /// Default ISO datetime formatting.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter
    }

    static var allTests = [
        ("testNormalLog", testNormalLog),
        ("testMultipleBackends", testMultipleBackends),
        ("testLevelMismatch", testLevelMismatch),
        ("testNoBackends", testNoBackends),
        ("testDisable", testDisable),
        ("testSubLevels", testSubLevels),
    ]

    override func setUp() {
        Loki.sourceName = ""
        Loki.destinations = []
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testNormalLog() {
        let logWritten = expectation(description: "log written to string")
        let destination = StringDestination()

        let formatter = getDateFormatter()
        Loki.sourceName = "testApp"
        Loki.dateFormatter = formatter
        Loki.addDestination(destination)
        Loki.warn("Hi")
        let line = #line
        let date = formatter.string(from: Date())
        XCTAssertEqual(destination.string,
                       "[\(date)] [WARN] [testApp:LoggingTests.swift:\(line - 1) testNormalLog()] Hi")
        logWritten.fulfill()

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }

    func testMultipleBackends() {
        let log1Written = expectation(description: "log written to string 1")
        let log2Written = expectation(description: "log written to string 2")
        let destination1 = StringDestination()
        let destination2 = StringDestination()

        let formatter = getDateFormatter()
        Loki.dateFormatter = formatter
        Loki.addDestination(destination1)
        Loki.addDestination(destination2)
        Loki.error("Hi")
        let line = #line

        let date = formatter.string(from: Date())
        let finalString = "[\(date)] [ERROR] [:LoggingTests.swift:\(line - 1) testMultipleBackends()] Hi"
        XCTAssertEqual(destination1.string, finalString)
        log1Written.fulfill()
        XCTAssertEqual(destination1.string, finalString)
        log2Written.fulfill()

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }

    func testNoBackends() {
        XCTAssertFalse(Loki.isLogging(.info))
    }

    func testDisable() {
        let logFail = expectation(description: "log not written")
        let destination = StringDestination()
        Loki.addDestination(destination)
        Loki.logLevel = .none
        Loki.error("Hi")
        XCTAssertEqual(destination.string, "")
        logFail.fulfill()

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }

    func testLevelMismatch() {
        let logFail = expectation(description: "log not written")
        let logWritten = expectation(description: "log written")
        let destination = StringDestination()
        Loki.addDestination(destination)
        Loki.logLevel = .error
        Loki.info("Hi")
        XCTAssertEqual(destination.string, "")
        logFail.fulfill()

        let formatter = getDateFormatter()
        Loki.dateFormatter = formatter
        Loki.logLevel = .debug
        Loki.verbose("Hello")
        let line = #line

        let date = formatter.string(from: Date())
        let finalString = "[\(date)] [VERBOSE] [:LoggingTests.swift:\(line - 1) testLevelMismatch()] Hello"
        XCTAssertEqual(destination.string, finalString)
        logWritten.fulfill()

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }

    func testSubLevels() {
        let levels: [LogLevel] = [.debug, .verbose, .info, .warn, .error]
        for level in levels {
            for sublevel in levels {
                Loki.destinations = []
                let destination = StringDestination()
                Loki.addDestination(destination)
                Loki.logLevel = level
                let formatter = getDateFormatter()
                Loki.dateFormatter = formatter
                Loki.log(sublevel, "Hi")
                let line = #line

                if level.rawValue <= sublevel.rawValue {
                    let date = formatter.string(from: Date())
                    let finalString = "[\(date)] [\(sublevel)] [:LoggingTests.swift:\(line - 1) testSubLevels()] Hi"
                    XCTAssertEqual(destination.string, finalString)
                } else {
                    XCTAssertEqual(destination.string, "")
                }
            }
        }
    }
}
