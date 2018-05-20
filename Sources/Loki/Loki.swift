import Dispatch
import Foundation

/// The public logging API to be used by outsiders.
public class Loki {
    /// Backends used by the logger
    open private(set) static var destinations = Set<BaseDestination>()
    
    /// Name of the app.
    public static var sourceName: String = ""

    /// returns boolean about success
    @discardableResult
    open class func addDestination(_ destination: BaseDestination) -> Bool {
        if destinations.contains(destination) {
            return false
        }
        destinations.insert(destination)
        return true
    }
    
    /// returns boolean about success
    @discardableResult
    open class func removeDestination(_ destination: BaseDestination) -> Bool {
        if destinations.contains(destination) == false {
            return false
        }
        destinations.remove(destination)
        return true
    }
    
    /// if you need to start fresh
    open class func removeAllDestinations() {
        destinations.removeAll()
    }
    
    /// returns the amount of destinations
    open class func countDestinations() -> Int {
        return destinations.count
    }

    /// Log a debug message.
    open class func debug(_ text: String,
                            function: String = #function,
                            line: Int = #line,
                            file: String = #file,
                            context: Any? = nil)
    {
        Loki.log(.debug, text, function: function,
                 line: line, file: file, context: context)
    }

    /// Log a verbose message.
    open class func verbose(_ text: String,
                                function: String = #function,
                                line: Int = #line,
                                file: String = #file,
                                context: Any? = nil)
    {
        Loki.log(.verbose, text, function: function,
                 line: line, file: file, context: context)
    }

    /// Log an informational message.
    open class func info(_ text: String,
                            function: String = #function,
                            line: Int = #line,
                            file: String = #file,
                            context: Any? = nil)
    {
        Loki.log(.info, text, function: function,
                 line: line, file: file, context: context)
    }

    /// Log a warning message.
    open class func warn(_ text: String,
                            function: String = #function,
                            line: Int = #line,
                            file: String = #file,
                            context: Any? = nil)
    {
        Loki.log(.warning, text, function: function,
                 line: line, file: file, context: context)
    }

    /// Log an error message.
    open class func error(_ text: String,
                            function: String = #function,
                            line: Int = #line,
                            file: String = #file,
                            context: Any? = nil)
    {
        Loki.log(.error, text, function: function,
                 line: line, file: file, context: context)
    }
    
    /// Check whether we're logging the given level
    /// (also checks whether we have any available destinations).
    public static func isLogging(_ level: LogLevel) -> Bool {
        if Loki.destinations.isEmpty || level == .none {
            return false
        }

        return true
    }
    
    /// internal helper which dispatches send to dedicated queue if minLevel is ok
    public class func send(_ message: LogMessage, thread: String, context: Any?) {
        
        var resolvedMessage: String?
        
        destinations.forEach({ dest in
            
            guard let queue = dest.queue else {
                return
            }
            
            resolvedMessage = resolvedMessage == nil && dest.hasMessageFilters() ? "\(message.text)" : resolvedMessage
            if dest.shouldLevelBeLogged(message.level, path: message.file, function: message.function, message: resolvedMessage) {
                if dest.asynchronously {
                    queue.async {
                        _ = dest.send(message, thread: thread, context: context)
                    }
                } else {
                    queue.sync {
                        _ = dest.send(message, thread: thread, context: context)
                    }
                }
            }
        })
    }
    
    /// Generic logging function.
    public class func log(_ level: LogLevel, _ text: String,
                          function: String = #function,
                          line: Int = #line,
                          file: String = #file,
                          context: Any? = nil)
    {
        if !Loki.isLogging(level) {
            return
        }
        
        let date = BaseDestination.getDateFormatter().string(from: Date())
        let file = URL(fileURLWithPath: file).lastPathComponent
        let log = LogMessage(source: sourceName, date: date, level: level, text: text,
                             file: file, line: line, function: function)
        Loki.send(log, thread: threadName(), context: context)
    }
    
    /// returns the current thread name
    class func threadName() -> String {
        
        #if os(Linux)
        // Not yet implemented in Swift on Linux:
        // > import Foundation
        // > Thread.isMainThread
        return ""
        #else
        if Thread.isMainThread {
            return ""
        } else {
            let threadName = Thread.current.name
            if let threadName = threadName, !threadName.isEmpty {
                return threadName
            } else {
                return String(format: "%p", Thread.current)
            }
        }
        #endif
    }

}
