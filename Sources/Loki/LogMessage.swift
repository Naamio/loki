public struct LogMessage: Codable {
    public let app: String
    public let date: String
    public let level: String
    public let text: String
    public let path: String
    public let line: Int
    public let function: String
}

extension LogMessage {
    public func toString() -> String {
        return "[\(date)] [\(level)] [\(app):\(path):\(line) \(function)] \(text)"
    }
}
