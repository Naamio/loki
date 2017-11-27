import XCTest
@testable import LokiTests

XCTMain([
    testCase(LoggingTests.allTests),
    testCase(HttpBackendTests.allTests),
    testCase(FileBackendTests.allTests),
])
