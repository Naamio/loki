/// Protocol to be implemented by any backend.
public protocol LokiBackend {
    func writeLog(_ logData: LogMessage)
}
