/// Protocol to be implemented by any destination.
public protocol Destination {

    /// Sends a log message to the destination.
    ///
    ///  - parameter: message Log data encapsulated as a `LogMessage` object.
    func send(_ message: LogMessage) -> String?
    
    func send(_ message: LogMessage, thread: String, context: Any?) -> String?
    
    func send(_ level: LogLevel, text: String, file: String,
    function: String, line: Int, thread: String, context: Any?) -> String?
}
