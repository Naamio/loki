import Foundation
import XCTest

@testable import Loki

class StringBackend {
    var string = ""
}

extension StringBackend: LokiBackend {
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
        Loki.appName = ""
        Loki.backends = []
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testNormalLog() {
        let logWritten = expectation(description: "log written to string")
        let backend = StringBackend()

        let formatter = getDateFormatter()
        Loki.appName = "testApp"
        Loki.dateFormatter = formatter
        Loki.addBackend(backend)
        Loki.warn("Hi")
        let line = #line
        let date = formatter.string(from: Date())
        XCTAssertEqual(backend.string,
                       "[\(date)] [WARN] [testApp:LoggingTests.swift:\(line - 1) testNormalLog()] Hi")
        logWritten.fulfill()

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }

    func testMultipleBackends() {
        let log1Written = expectation(description: "log written to string 1")
        let log2Written = expectation(description: "log written to string 2")
        let backend1 = StringBackend()
        let backend2 = StringBackend()

        let formatter = getDateFormatter()
        Loki.dateFormatter = formatter
        Loki.addBackend(backend1)
        Loki.addBackend(backend2)
        Loki.error("Hi")
        let line = #line

        let date = formatter.string(from: Date())
        let finalString = "[\(date)] [ERROR] [:LoggingTests.swift:\(line - 1) testMultipleBackends()] Hi"
        XCTAssertEqual(backend1.string, finalString)
        log1Written.fulfill()
        XCTAssertEqual(backend1.string, finalString)
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
        let backend = StringBackend()
        Loki.addBackend(backend)
        Loki.logLevel = .none
        Loki.error("Hi")
        XCTAssertEqual(backend.string, "")
        logFail.fulfill()

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }

    func testLevelMismatch() {
        let logFail = expectation(description: "log not written")
        let logWritten = expectation(description: "log written")
        let backend = StringBackend()
        Loki.addBackend(backend)
        Loki.logLevel = .error
        Loki.info("Hi")
        XCTAssertEqual(backend.string, "")
        logFail.fulfill()

        let formatter = getDateFormatter()
        Loki.dateFormatter = formatter
        Loki.logLevel = .debug
        Loki.verbose("Hello")
        let line = #line

        let date = formatter.string(from: Date())
        let finalString = "[\(date)] [VERBOSE] [:LoggingTests.swift:\(line - 1) testLevelMismatch()] Hello"
        XCTAssertEqual(backend.string, finalString)
        logWritten.fulfill()

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }

    func testSubLevels() {
        let levels: [LogLevel] = [.debug, .verbose, .info, .warn, .error]
        for level in levels {
            for sublevel in levels {
                Loki.backends = []
                let backend = StringBackend()
                Loki.addBackend(backend)
                Loki.logLevel = level
                let formatter = getDateFormatter()
                Loki.dateFormatter = formatter
                Loki.log(sublevel, "Hi")
                let line = #line

                if level.rawValue <= sublevel.rawValue {
                    let date = formatter.string(from: Date())
                    let finalString = "[\(date)] [\(sublevel)] [:LoggingTests.swift:\(line - 1) testSubLevels()] Hi"
                    XCTAssertEqual(backend.string, finalString)
                } else {
                    XCTAssertEqual(backend.string, "")
                }
            }
        }
    }
}
