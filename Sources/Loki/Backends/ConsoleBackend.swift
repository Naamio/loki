/// Console backend for logging messages in stdout
public class ConsoleBackend {
    public init() {}
}

extension ConsoleBackend: LokiBackend {
    public func writeLog(_ logData: LogMessage) {
        print("\(logData.toString())")
    }
}
