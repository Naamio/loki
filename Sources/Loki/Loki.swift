import Dispatch
import Foundation

/// The public logging API to be used by outsiders.
public class Loki {
    /// Default ISO datetime formatting.
    let defaultDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    /// Default formatter.
    let dateFormatter = DateFormatter()
    /// Backends used by the logger
    public var backends = [LokiBackend]()
    /// Level of logging output.
    public static var logLevel = LogLevel.info
    /// Whether async logging is enabled
    public static var dispatchQueue: DispatchQueue?

    /// Check whether we're logging the given level
    /// (also checks whether we have any available backends).
    public func isLogging(_ level: LogLevel) -> Bool {
        if backends.isEmpty {
            return false
        }

        return Loki.logLevel == level
    }

    /// Generic logging function.
    public func log(level: LogLevel, msg: String,
                    functionName: String = #function,
                    lineNum: Int = #line,
                    fileName: String = #file)
    {
        if !isLogging(level) {
            return
        }

        let date = dateFormatter.string(from: Date())
        let message = "[\(date)] [\(level)] [\(fileName):\(lineNum) \(functionName)] \(msg)"
        if let queue = Loki.dispatchQueue {
            queue.async {
                for backend in self.backends {
                    backend.writeLog(message)
                }
            }
        } else {
            for backend in self.backends {
                backend.writeLog(message)
            }
        }
    }
}
