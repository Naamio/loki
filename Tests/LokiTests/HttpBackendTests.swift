import Foundation
import Kitura
import SwiftyRequest
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
        ("testAuthorizedLog", testAuthorizedLog),
        ("testUnauthorized", testUnauthorized),
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

    func testAuthorizedLog() {
        let router = LokiCollector.initializeRoutes(authToken: "foobar")
        Kitura.addHTTPServer(onPort: 8000, with: router)
        Kitura.start()

        let logReceived = expectation(description: "server received log")
        let backend = TestBackend(callback: { logData in
            XCTAssertEqual(logData.text, "Booya")
            logReceived.fulfill()
        })

        LokiCollector.addBackend(backend)
        let httpClient = HttpBackend(url: "http://0.0.0.0:8000/")
        httpClient.hostAuth = "foobar"
        Loki.addBackend(httpClient)
        Loki.logLevel = .info
        Loki.info("Booya")

        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error)
        }
    }

    func testUnauthorized() {
        let router = LokiCollector.initializeRoutes(authToken: "foobar")
        Kitura.addHTTPServer(onPort: 8000, with: router)
        Kitura.start()

        let requestRejected = expectation(description: "Request rejected")
        let request = RestRequest(method: .post, url: "http://0.0.0.0:8000/")
        let logData = LogMessage(date: "", level: "", text: "", path: "", line: 0, function: "")
        let jsonData = try! JSONEncoder().encode(logData)
        request.messageBody = jsonData

        request.responseData(completionHandler: { resp in
            let response = resp.response!
            XCTAssertEqual(response.statusCode, 401)
            requestRejected.fulfill()
        })

        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error)
        }
    }
}
