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
        ("testServerLogging", testServerLogging),
        ("testClientLogging", testClientLogging),
        ("testServerAuthorization", testServerAuthorization),
        ("testClientAuthorization", testClientAuthorization),
        ("testUnauthorized", testUnauthorized),
    ]

    override func setUp() {
        Loki.sourceName = ""
        Loki.backends = []
        Loki.logLevel = .info
        super.setUp()
    }

    override func tearDown() {
        Kitura.stop()
        super.tearDown()
    }

    func prepareRequestForLog(_ logData: LogMessage? = nil,
                              auth: String? = nil) -> RestRequest {
        let request = RestRequest(method: .post, url: "http://0.0.0.0:8000/")
        if let logData = logData {
            let jsonData = try! JSONEncoder().encode(logData)
            request.messageBody = jsonData
        }

        if let token = auth {
            request.headerParameters["Authorization"] = "Bearer \(token)"
        }

        return request
    }

    func testServerLogging() {
        let router = LokiCollector.initializeRoutes(authToken: nil)
        Kitura.addHTTPServer(onPort: 8000, with: router)
        Kitura.start()

        let logReceived = expectation(description: "server received log")
        let backend = TestBackend(callback: { logData in
            XCTAssertEqual(logData.source, "testApp")
            XCTAssertEqual(logData.text, "Booya")
            XCTAssertEqual(logData.level, .info)
            XCTAssertEqual(logData.function, "someFunc()")
            XCTAssertEqual(logData.fileName, "someFile.swift")
            logReceived.fulfill()
        })

        Loki.addBackend(backend)
        let logData = LogMessage(source: "testApp", date: "", level: .info, text: "Booya",
                                 fileName: "someFile.swift", line: 0, function: "someFunc()")
        let request = prepareRequestForLog(logData)
        request.responseData(completionHandler: { resp in
            XCTAssertEqual(resp.response!.statusCode, 200)
        })

        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error)
        }
    }

    func testClientLogging() {
        let router = Router()
        let logSent = expectation(description: "log sent to server")
        router.post("/*") { req, resp, next in
            let logData = try! req.read(as: LogMessage.self)
            XCTAssertEqual(logData.text, "Hola!")
            resp.statusCode = .OK
            logSent.fulfill()
            next()
        }

        Kitura.addHTTPServer(onPort: 8000, with: router)
        Kitura.start()

        let httpClient = HttpBackend(url: "http://0.0.0.0:8000")
        Loki.addBackend(httpClient)
        Loki.info("Hola!")

        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error)
        }
    }

    func testServerAuthorization() {
        let router = LokiCollector.initializeRoutes(authToken: "foobar")
        Kitura.addHTTPServer(onPort: 8000, with: router)
        Kitura.start()

        let logReceived = expectation(description: "server received log")
        let backend = TestBackend(callback: { logData in
            XCTAssertEqual(logData.text, "Booya")
            logReceived.fulfill()
        })

        Loki.addBackend(backend)

        let logData = LogMessage(source: "", date: "", level: .info, text: "Booya",
                                 fileName: "", line: 0, function: "")
        let request = prepareRequestForLog(logData, auth: "foobar")
        request.responseData(completionHandler: { resp in
            XCTAssertEqual(resp.response!.statusCode, 200)
        })

        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error)
        }
    }

    func testClientAuthorization() {
        let router = Router()
        let logSent = expectation(description: "log sent to server")
        router.post("/*") { req, resp, next in
            XCTAssertEqual(req.headers["Authorization"], "Bearer foobar")
            let logData = try! req.read(as: LogMessage.self)
            XCTAssertEqual(logData.text, "Boo!")
            resp.statusCode = .OK
            logSent.fulfill()
            next()
        }

        Kitura.addHTTPServer(onPort: 8000, with: router)
        Kitura.start()

        let httpClient = HttpBackend(url: "http://0.0.0.0:8000")
        httpClient.hostAuth = "foobar"
        Loki.addBackend(httpClient)
        Loki.info("Boo!")

        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error)
        }
    }

    func testUnauthorized() {
        let router = LokiCollector.initializeRoutes(authToken: "foobar")
        Kitura.addHTTPServer(onPort: 8000, with: router)
        Kitura.start()

        let requestRejected = expectation(description: "Request rejected")
        let request = prepareRequestForLog()
        request.responseData(completionHandler: { resp in
            XCTAssertEqual(resp.response!.statusCode, 401)
            requestRejected.fulfill()
        })

        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error)
        }
    }
}
