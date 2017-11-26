import Dispatch
import Foundation

/// The public logging API to be used by outsiders.
public class Loki {
    /// Default formatter.
    public static var dateFormatter = Loki.getDateFormatter()
    /// Backends used by the logger
    public static var backends = [LokiBackend]()
    /// Level of logging output.
    public static var logLevel = LogLevel.info
    /// Dispatch queue to which logging should be done async
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
        if Loki.backends.isEmpty || Loki.logLevel == .none {
            return false
        }

        return Loki.logLevel.rawValue <= level.rawValue
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
        let log = LogMessage(date: date, level: level.description, text: msg,
                             path: path, line: lineNum, function: functionName)

        if let queue = Loki.dispatchQueue {
            queue.async {
                for backend in Loki.backends {
                    backend.writeLog(log)
                }
            }
        } else {
            for backend in Loki.backends {
                backend.writeLog(log)
            }
        }
    }

    /// Log a debug message.
    public static func debug(_ msg: String,
                             functionName: String = #function,
                             lineNum: Int = #line,
                             filePath: String = #file)
    {
        Loki.log(.debug, msg, functionName: functionName,
                 lineNum: lineNum, filePath: filePath)
    }

    /// Log a verbose message.
    public static func verbose(_ msg: String,
                               functionName: String = #function,
                               lineNum: Int = #line,
                               filePath: String = #file)
    {
        Loki.log(.verbose, msg, functionName: functionName,
                 lineNum: lineNum, filePath: filePath)
    }

    /// Log an informational message.
    public static func info(_ msg: String,
                           functionName: String = #function,
                           lineNum: Int = #line,
                           filePath: String = #file)
    {
        Loki.log(.info, msg, functionName: functionName,
                 lineNum: lineNum, filePath: filePath)
    }

    /// Log a warning message.
    public static func warn(_ msg: String,
                            functionName: String = #function,
                            lineNum: Int = #line,
                            filePath: String = #file)
    {
        Loki.log(.warn, msg, functionName: functionName,
                 lineNum: lineNum, filePath: filePath)
    }

    /// Log an error message.
    public static func error(_ msg: String,
                             functionName: String = #function,
                             lineNum: Int = #line,
                             filePath: String = #file)
    {
        Loki.log(.error, msg, functionName: functionName,
                 lineNum: lineNum, filePath: filePath)
    }
}
