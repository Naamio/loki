import Foundation

/// Based on the LoggerAPI implementation -
/// https://github.com/IBM-Swift/LoggerAPI/blob/c56c3de778680dc0cc30443cde8a211f0fd0c754/Sources/LoggerAPI/Logger.swift#L20
public enum LogLevel: UInt8 {
    /// Log message type for logging a debugging message
    case debug = 1
    /// Log message type for logging messages in verbose mode
    case verbose = 2
    /// Log message type for logging an informational message
    case info = 3
    /// Log message type for logging a warning message
    case warning = 4
    /// Log message type for logging an error message
    case error = 5
}

/// Convert the level into a printable format.
extension LogLevel: CustomStringConvertible {
    public var description: String {
        switch self {
            case .debug:
                return "DEBUG"
            case .verbose:
                return "VERBOSE"
            case .info:
                return "INFO"
            case .warning:
                return "WARNING"
            case .error:
                return "ERROR"
        }
    }
}
