import Foundation

/// Console destination for logging messages in stdout
public class ConsoleDestination: BaseDestination {
    
    override public var defaultHashValue: Int { return 1 }
    
    /// use NSLog instead of print, default is false
    public var useNSLog = false
    
    override public init() {
        super.init()
    }
    
    // print to Xcode Console. uses full base class functionality
    override public func send(_ level: LogLevel, text: String, file: String, function: String, line: Int, thread: String, context: Any? = nil) -> String? {
        let formattedString = super.send(level, text: text, file: file, function: function, line: line, thread: thread, context: context)
        
        if let str = formattedString {
            if useNSLog {
                #if os(Linux)
                print(str)
                #else
                NSLog("%@", str)
                #endif
            } else {
                print(str)
            }
        }
        return formattedString
    }
}
