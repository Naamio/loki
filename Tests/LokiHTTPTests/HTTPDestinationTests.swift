import Foundation
import XCTest

@testable import Loki
@testable import LokiHTTP

class HTTPDestinationTests: XCTestCase {

    var platform = HTTPDestinationTests(encryptionKey: "")

    override func setUp() {
        super.setUp()
        Loki.removeAllDestinations()
    }
}
    