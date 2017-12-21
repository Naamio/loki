import Dispatch
import Foundation
import Kitura

import Loki

/// HTTP destination for collecting logs sent by different services.
public class LokiCollector {
    /// Initialize routes for the collector. It accepts POST data
    /// to any route. If we specify an authorization token, then it'll
    /// check the `Bearer` token in incoming requests against the given token.
    static func initializeRoutes(authToken: String?) -> Router {
        let router = Router()

        if let authToken = authToken {
            router.post("/*") { request, response, next in
                let header = request.headers["Authorization"] ?? "       "
                let idx = header.index(header.startIndex, offsetBy: 7)
                if authToken == header[idx...] {
                    next()
                } else {
                    Loki.debug("Authorization failed for request.")
                    response.statusCode = .unauthorized
                    try response.end()
                }
            }
        }

        router.post("/*") { request, response, next in
            do {
                let logData = try request.read(as: LogMessage.self)
                if Loki.isLogging(logData.level) {
                    Loki.logToBackend(logData)
                }

                response.statusCode = .OK
            } catch {
                Loki.debug("Invalid payload for request.")
                response.statusCode = .badRequest
            }

            try response.end()
        }

        return router
    }

    //// Spawn a server at the specified port and serve indefinitely.
    public static func start(listenPort: Int,
                             authorizeWith: String? = nil)
    {
        let router = initializeRoutes(authToken: authorizeWith)
        Kitura.addHTTPServer(onPort: listenPort, with: router)
        Kitura.run()
    }
}
