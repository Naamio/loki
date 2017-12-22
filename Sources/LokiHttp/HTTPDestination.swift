import Foundation
import SwiftyRequest

import Loki

/// Loki HTTP destination for sending messages to another server.
/// This currently utilizes `Kitura` and `SwiftyRequest`.
public class HTTPDestination {

    let hostUrl: String
    
    /// Host authorization string.
    public var hostAuth: String? = nil

    /// Initialize a new `HTTPDestination` instance
    /// with a given URL.
    public init(url: String) {
        /// TODO: Check the URL is valid. / Change the type.
        hostUrl = url
    }
}

/// MARK: - HTTPDestination: BaseDestination

extension HTTPDestination: BaseDestination {

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
