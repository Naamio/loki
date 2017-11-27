import Foundation
import Kitura
import XCTest

@testable import Loki

class TestBackend: LokiBackend {
    let callback: (LogMessage) -> Void

    init(callback: @escaping (LogMessage) -> Void) {
        self.callback = callback
    }

    public func writeLog(_ logData: LogMessage) {
        self.callback(logData)
    }
}

class HttpBackendTests: XCTestCase {
    static var allTests = [
        ("testNormalLog", testNormalLog),
    ]

    override func setUp() {
        Loki.backends = []
        LokiCollector.backends = []
        super.setUp()
    }

    override func tearDown() {
        Kitura.stop()
        super.tearDown()
    }

    func testNormalLog() {
        let router = LokiCollector.initializeRoutes(authToken: nil)
        Kitura.addHTTPServer(onPort: 8000, with: router)
        Kitura.start()

        let logReceived = expectation(description: "server received log")
        let backend = TestBackend(callback: { logData in
            XCTAssertEqual(logData.text, "Booya")
            XCTAssertEqual(logData.level, "INFO")
            XCTAssertEqual(logData.function, "testNormalLog()")
            XCTAssertEqual(logData.path, "HttpBackendTests.swift")
            logReceived.fulfill()
        })

        LokiCollector.addBackend(backend)
        Loki.addBackend(HttpBackend(url: "http://0.0.0.0:8000/"))
        Loki.logLevel = .info
        Loki.info("Booya")

        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error)
        }
    }
}
