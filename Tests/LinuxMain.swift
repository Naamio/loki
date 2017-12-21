import XCTest
@testable import LokiTests

XCTMain([
    testCase(LoggingTests.allTests),
    testCase(HttpDestinationTests.allTests),
    testCase(FileDestinationTests.allTests),
])
