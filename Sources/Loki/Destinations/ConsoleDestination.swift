/// Console destination for logging messages in stdout
public class ConsoleDestination {
    public init() {}
}

extension ConsoleDestination: BaseDestination {
    public func writeLog(_ logData: LogMessage) {
        print("\(logData.toString())")
    }
}
