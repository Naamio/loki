/// Protocol to be implemented by any destination.
public protocol BaseDestination {

    /// Writes a log message to the destination.
    ///
    ///  - parameter: logData Log data encapsulated as a `LogMessage` object.
    func writeLog(_ logData: LogMessage)
}
