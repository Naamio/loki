import Dispatch
import Foundation
import Kitura

/// HTTP backend for collecting logs sent by different services.
public class LokiCollector {
    public static var dispatchQueue: DispatchQueue?

    /// Collector's backends for writing logs
    public static var backends = [LokiBackend]()

    /// Add a new Loki backend.
    public static func addBackend(_ backend: LokiBackend) {
        LokiCollector.backends.append(backend)
    }

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
                    Loki.info("Authorization failed")
                    response.statusCode = .unauthorized
                    try response.end()
                }
            }
        }

        router.post("/*") { request, response, next in
            do {
                let logData = try request.read(as: LogMessage.self)
                if let queue = LokiCollector.dispatchQueue {
                    queue.async {
                        for backend in LokiCollector.backends {
                            backend.writeLog(logData)
                        }
                    }
                } else {
                    for backend in LokiCollector.backends {
                        backend.writeLog(logData)
                    }
                }

                response.statusCode = .OK
            } catch let err {
                Loki.error("Cannot obtain log message from request: \(err)")
                response.statusCode = .badRequest
            }
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
