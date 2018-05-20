import XCTest

@testable import LokiTests

XCTMain([
    testCase(FileDestinationTests.allTests),
    testCase(ConsoleDestinationTests.allTests),
])
