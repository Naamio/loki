import XCTest

@testable import LokiTests
@testable import LokiHTTPTests

XCTMain([
    testCase(LoggingTests.allTests),
    testCase(FileDestinationTests.allTests),
    testCase(HTTPDestinationTests.allTests),
])
