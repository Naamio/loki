import Foundation
import XCTest

@testable import Loki

class StringBackend {
    var string = ""
}

extension StringBackend: LokiBackend {
    public func writeLog(_ text: String) {
        self.string += text
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
    ]

    func testNormalLog() {
        let logWritten = expectation(description: "log written to string")
        let backend = StringBackend()

        let formatter = getDateFormatter()
        Loki.dateFormatter = formatter
        Loki.addBackend(backend)
        Loki.log(.info, "Hi")       // This affects line number
        logWritten.fulfill()

        let date = formatter.string(from: Date())
        XCTAssertEqual(backend.string,
                       "[\(date)] [INFO] [LoggingTests.swift:35 testNormalLog()] Hi")

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }
}
