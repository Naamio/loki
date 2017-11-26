import Foundation
import SwiftyRequest

/// Protocol to be implemented by any backend.
public protocol LokiBackend {
    func writeLog(_ logData: LogMessage)
}

public class ConsoleBackend {}

extension ConsoleBackend: LokiBackend {
    public func writeLog(_ logData: LogMessage) {
        print("\(logData.toString())")
    }
}

public class HttpBackend {
    let hostUrl: String
    public var hostAuth: String? = nil

    public init(url: String) {
        hostUrl = url
    }
}

extension HttpBackend: LokiBackend {
    public func writeLog(_ logData: LogMessage) {
        let request = RestRequest(method: .post, url: hostUrl)
        let jsonData = try! JSONEncoder().encode(logData)
        request.messageBody = jsonData
        request.headerParameters["Content-Length"] = String(format: "%d", jsonData.count)
        if let authToken = hostAuth {
            request.headerParameters["Authorization"] = "Bearer \(authToken)"
        }

        request.responseData(completionHandler: { resp in
            if let _ = resp.response {
                // FIXME: Check status code
            } else {
                // FIXME: How should we log errors here?
            }
        })
    }
}
