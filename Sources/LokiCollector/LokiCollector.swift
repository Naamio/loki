import Foundation
import Kitura
import Loki

public class LokiCollector {
    static func initializeRoutes(requiresAuth: Bool) -> Router {
        let router = Router()

        if requiresAuth {
            let authToken = "\(UUID())"
            print("Authorization: \(authToken)")
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
                let data = try request.read(as: LogMessage.self)
                print("\(data.toString())")
                response.statusCode = .OK
            } catch let err {
                Loki.error("Cannot obtain log message from request: \(err)")
                response.statusCode = .badRequest
            }
        }

        return router
    }

    public static func start(listenPort: Int, authorize: Bool) {
        let router = initializeRoutes(requiresAuth: authorize)
        Kitura.addHTTPServer(onPort: listenPort, with: router)
        Kitura.run()
    }
}
