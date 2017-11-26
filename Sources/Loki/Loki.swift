import Dispatch
import Foundation

/// The public logging API to be used by outsiders.
public class Loki {
    /// Default formatter.
    static var dateFormatter = Loki.getDateFormatter()
    /// Backends used by the logger
    static var backends = [LokiBackend]()
    /// Level of logging output.
    public static var logLevel = LogLevel.info
    /// Whether async logging is enabled
    public static var dispatchQueue: DispatchQueue?

    static func getDateFormatter() -> DateFormatter {
        /// Default ISO datetime formatting.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return formatter
    }

    public static func addBackend(_ backend: LokiBackend) {
        Loki.backends.append(backend)
    }

    /// Check whether we're logging the given level
    /// (also checks whether we have any available backends).
    public static func isLogging(_ level: LogLevel) -> Bool {
        if Loki.backends.isEmpty {
            return false
        }

        return Loki.logLevel == level
    }

    /// Generic logging function.
    public static func log(_ level: LogLevel, _ msg: String,
                           functionName: String = #function,
                           lineNum: Int = #line,
                           filePath: String = #file)
    {
        if !Loki.isLogging(level) {
            return
        }

        let date = dateFormatter.string(from: Date())
        let path = NSURL(fileURLWithPath: filePath).lastPathComponent!
        let message = "[\(date)] [\(level)] [\(path):\(lineNum) \(functionName)] \(msg)"
        if let queue = Loki.dispatchQueue {
            queue.async {
                for backend in Loki.backends {
                    backend.writeLog(message)
                }
            }
        } else {
            for backend in Loki.backends {
                backend.writeLog(message)
            }
        }
    }
}
