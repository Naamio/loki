/// Protocol to be implemented by any destination.
public protocol BaseDestination {
    func writeLog(_ logData: LogMessage)
}
