/// A single log unit passed to any logging destination.
public struct LogMessage: Codable {
    /// The source from which this log originated (manually set by the user).
    public let source: String
    /// Timestamp in ISO datetime format (UTC).
    public let date: String
    /// Level on which this log was thrown.
    public let level: LogLevel
    /// Log message
    public let text: String
    /// Final component (file name) of the source from which this log originated.
    public let file: String
    /// Line number from which this log originated.
    public let line: Int
    /// Function which emitted this log.
    public let function: String
}

extension LogMessage {
    /// Convert this log unit into a human-readable line.
    public func toString() -> String {
        return "[\(date)] [\(level)] [\(source):\(file):\(line) \(function)] \(text)"
    }
}
