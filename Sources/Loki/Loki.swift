import Dispatch
import Foundation

/// The public logging API to be used by outsiders.
public class Loki {
    /// Default formatter.
    public static var dateFormatter = Loki.getDateFormatter()
    /// Backends used by the logger
    public static var destinations = [BaseDestination]()
    /// Level of logging output.
    public static var logLevel = LogLevel.info
    /// Dispatch queue to which logging should be done async
    public static var dispatchQueue: DispatchQueue?
    /// Name of the app.
    public static var sourceName: String = ""

    static func getDateFormatter() -> DateFormatter {
        /// Default ISO datetime formatting.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return formatter
    }

    /// Add a configured destination to this logger.
    public static func addDestination(_ destination: BaseDestination) {
        Loki.destinations.append(destination)
    }

    /// Check whether we're logging the given level
    /// (also checks whether we have any available destinations).
    public static func isLogging(_ level: LogLevel) -> Bool {
        if Loki.destinations.isEmpty || Loki.logLevel == .none {
            return false
        }

        return Loki.logLevel.rawValue <= level.rawValue
    }

    /// Pass the log message unit to the configured destinations.
    /// (also takes care of async logging)
    public static func logToBackend(_ log: LogMessage) {
        if let queue = Loki.dispatchQueue {
            queue.async {
                for destination in Loki.destinations {
                    destination.writeLog(log)
                }
            }
        } else {
            for destination in Loki.destinations {
                destination.writeLog(log)
            }
        }
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
        let fileName = NSURL(fileURLWithPath: filePath).lastPathComponent!
        let log = LogMessage(source: sourceName, date: date, level: level, text: msg,
                             fileName: fileName, line: lineNum, function: functionName)
        Loki.logToBackend(log)
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
