import Foundation

open class BaseDestination: Destination, Hashable {
    
    static func getDateFormatter() -> DateFormatter {
        /// Default ISO datetime formatting.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return formatter
    }

    /// output format pattern, see documentation for syntax
    open var format = "$DHH:mm:ss.SSS$d $C$L$c $N.$F:$l - $M"
    
    /// runs in own serial background thread for better performance
    open var asynchronously = true
    
    /// do not log any message which has a lower level than this one
    open var minLevel = LogLevel.verbose
    
    // each destination class must have an own hashValue Int
    lazy public var hashValue: Int = self.defaultHashValue
    
    var debugPrint = false // set to true to debug the internal filter logic of the class
    
    /// Dispatch queue to which logging should be done async
    var queue: DispatchQueue?
    
    var reset = ""
    var escape = ""
    
    var filters = [FilterType]()
    let dateFormatter = BaseDestination.getDateFormatter()
    let startDate = Date()
    
    open var defaultHashValue: Int {
        return 0
    }
    
    public init() {
        let uuid = UUID().uuidString
        let queueLabel = "loki-queue-" + uuid
        queue = DispatchQueue(label: queueLabel, target: queue)
    }
    
    open func send(_ message: LogMessage) -> String?  {
        return self.send(message, thread: "", context: nil)
    }
    
    open func send(_ message: LogMessage, thread: String, context: Any?) -> String? {
        return self.send(message.level, text: message.text, file: message.file, function: message.function, line: message.line, thread: thread, context: context)
    }
    
    /// send / store the formatted log message to the destination
    /// returns the formatted log message for processing by inheriting method
    /// and for unit tests (nil if error)
    open func send(_ level: LogLevel, text: String, file: String,
                   function: String, line: Int, thread: String, context: Any?) -> String? {
        
        if format.hasPrefix("$J") {
            return messageToJSON(level, text: text, thread: thread,
                                 file: file, function: function, line: line, context: context)
            
        } else {
            return formatMessage(format, level: level, text: text, thread: thread,
                                 file: file, function: function, line: line, context: context)
        }
    }
    
    /// returns the log message based on the format pattern
    func formatMessage(_ format: String, level: LogLevel, text: String, thread: String,
        file: String, function: String, line: Int, context: Any? = nil) -> String {

        var message = ""
        let phrases: [String] = format.components(separatedBy: "$")

        for phrase in phrases where !phrase.isEmpty {
                let firstChar = phrase[phrase.startIndex]
                let rangeAfterFirstChar = phrase.index(phrase.startIndex, offsetBy: 1)..<phrase.endIndex
                let remainingPhrase = phrase[rangeAfterFirstChar]

                switch firstChar {
                case "L":
                    message += levelWord(level) + remainingPhrase
                case "M":
                    message += text + remainingPhrase
                case "T":
                    message += thread + remainingPhrase
                case "N":
                    // name of file without suffix
                    message += fileNameWithoutSuffix(file) + remainingPhrase
                case "n":
                    // name of file with suffix
                    message += fileNameOfFile(file) + remainingPhrase
                case "F":
                    message += function + remainingPhrase
                case "l":
                    message += String(line) + remainingPhrase
                case "D":
                    // start of datetime format
                    message += formatDate(String(remainingPhrase))
                case "d":
                    message += remainingPhrase
                case "U":
                    message += uptime() + remainingPhrase
                case "Z":
                    // start of datetime format in UTC timezone
                    message += formatDate(String(remainingPhrase), timeZone: "UTC")
                case "z":
                    message += remainingPhrase
                case "c":
                    message += reset + remainingPhrase
                case "X":
                    // add the context
                    if let cx = context {
                        message += String(describing: cx).trimmingCharacters(in: .whitespacesAndNewlines) + remainingPhrase
                    }
                default:
                    message += phrase
                }
        }
        return message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// returns the log payload as optional JSON string
    func messageToJSON(_ level: LogLevel, text: String,
        thread: String, file: String, function: String, line: Int, context: Any? = nil) -> String? {
        var dict: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "level": level.rawValue,
            "text": text,
            "file": file,
            "function": function,
            "line": line,
            "thread": thread,
            ]
        if let cx = context {
            dict["context"] = cx
        }
        return jsonStringFromDict(dict)
    }

    /// returns the string of a level
    func levelWord(_ level: LogLevel) -> String {
        return level.description
    }
    
    /// returns the filename of a path
    func fileNameOfFile(_ file: String) -> String {
        let fileParts = file.components(separatedBy: "/")
        if let lastPart = fileParts.last {
            return lastPart
        }
        return ""
    }
    
    /// returns the filename without suffix (= file ending) of a path
    func fileNameWithoutSuffix(_ file: String) -> String {
        let fileName = fileNameOfFile(file)
        
        if !fileName.isEmpty {
            let fileNameParts = fileName.components(separatedBy: ".")
            if let firstPart = fileNameParts.first {
                return firstPart
            }
        }
        return ""
    }
    
    /// returns a formatted date string
    /// optionally in a given abbreviated timezone like "UTC"
    func formatDate(_ dateFormat: String, timeZone: String = "") -> String {
        if !timeZone.isEmpty {
            dateFormatter.timeZone = TimeZone(abbreviation: timeZone)
        }
        dateFormatter.dateFormat = dateFormat
        //let dateStr = formatter.string(from: NSDate() as Date)
        let dateStr = dateFormatter.string(from: Date())
        return dateStr
    }
    
    /// returns a uptime string
    func uptime() -> String {
        let interval = Date().timeIntervalSince(startDate)
        
        let hours = Int(interval) / 3600
        let minutes = Int(interval / 60) - Int(hours * 60)
        let seconds = Int(interval) - (Int(interval / 60) * 60)
        let milliseconds = Int(interval.truncatingRemainder(dividingBy: 1) * 1000)
        
        return String(format: "%0.2d:%0.2d:%0.2d.%03d", arguments: [hours, minutes, seconds, milliseconds])
    }
    
    /// returns the json-encoded string value
    /// after it was encoded by jsonStringFromDict
    func jsonStringValue(_ jsonString: String?, key: String) -> String {
        guard let str = jsonString else {
            return ""
        }
        
        // remove the leading {"key":" from the json string and the final }
        let offset = key.count + 5
        let endIndex = str.index(str.startIndex,
                                 offsetBy: str.count - 2)
        let range = str.index(str.startIndex, offsetBy: offset)..<endIndex
        
        return String(str[range])
    }
    
    /// turns dict into JSON-encoded string
    func jsonStringFromDict(_ dict: [String: Any]) -> String? {
        var jsonString: String?
        
        // try to create JSON string
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            jsonString = String(data: jsonData, encoding: .utf8)
        } catch {
            print("Logger could not create JSON from dict.")
        }
        return jsonString
    }
    
    ////////////////////////////////
    // MARK: Filters
    ////////////////////////////////
    /// Add a filter that determines whether or not a particular message will be logged to this destination
    public func addFilter(_ filter: FilterType) {
        filters.append(filter)
    }
    
    /// Remove a filter from the list of filters
    public func removeFilter(_ filter: FilterType) {
        let index = filters.index {
            return ObjectIdentifier($0) == ObjectIdentifier(filter)
        }
        
        guard let filterIndex = index else {
            return
        }
        
        filters.remove(at: filterIndex)
    }
    
    /// Answer whether the destination has any message filters
    /// returns boolean and is used to decide whether to resolve
    /// the message before invoking shouldLevelBeLogged
    func hasMessageFilters() -> Bool {
        return !getFiltersTargeting(Filter.TargetType.Message(.Equals([], true)),
                                    fromFilters: self.filters).isEmpty
    }
    
    func getFiltersTargeting(_ target: Filter.TargetType, fromFilters: [FilterType]) -> [FilterType] {
        return fromFilters.filter { filter in
            return filter.getTarget() == target
        }
    }
    
    /// checks if level is at least minLevel or if a minLevel filter for that path does exist
    /// returns boolean and can be used to decide if a message should be logged or not
    func shouldLevelBeLogged(_ level: LogLevel, path: String,
                             function: String, message: String? = nil) -> Bool {
        
        if filters.isEmpty {
            if level.rawValue >= minLevel.rawValue {
                if debugPrint {
                    print("filters is empty and level >= minLevel")
                }
                return true
            } else {
                if debugPrint {
                    print("filters is empty and level < minLevel")
                }
                return false
            }
        }
        
        let (matchedExclude, allExclude) = passedExcludedFilters(level, path: path,
                                                                 function: function, message: message)
        if allExclude > 0 && matchedExclude != allExclude {
            if debugPrint {
                print("filters is not empty and message was excluded")
            }
            return false
        }
        
        let (matchedRequired, allRequired) = passedRequiredFilters(level, path: path,
                                                                   function: function, message: message)
        let (matchedNonRequired, allNonRequired) = passedNonRequiredFilters(level, path: path,
                                                                            function: function, message: message)
        
        // If required filters exist, we should validate or invalidate the log if all of them pass or not
        if allRequired > 0 {
            return matchedRequired == allRequired
        }
        
        // If a non-required filter matches, the log is validated
        if allNonRequired > 0 {  // Non-required filters exist
            if matchedNonRequired > 0 { return true }  // At least one non-required filter matched
            else { return false }  // No non-required filters matched
        }
        
        if level.rawValue < minLevel.rawValue {
            if debugPrint {
                print("filters is not empty and level < minLevel")
            }
            return false
        }
        
        return true
    }
    
    /// returns a tuple of matched and all filters
    func passedRequiredFilters(_ level: LogLevel, path: String,
                               function: String, message: String?) -> (Int, Int) {
        let requiredFilters = self.filters.filter { filter in
            return filter.isRequired() && !filter.isExcluded()
        }
        
        let matchingFilters = applyFilters(requiredFilters, level: level, path: path,
                                           function: function, message: message)
        if debugPrint {
            print("matched \(matchingFilters) of \(requiredFilters.count) required filters")
        }
        
        return (matchingFilters, requiredFilters.count)
    }
    
    /// returns a tuple of matched and all filters
    func passedNonRequiredFilters(_ level: LogLevel,
                                  path: String, function: String, message: String?) -> (Int, Int) {
        let nonRequiredFilters = self.filters.filter { filter in
            return !filter.isRequired() && !filter.isExcluded()
        }
        
        let matchingFilters = applyFilters(nonRequiredFilters, level: level,
                                           path: path, function: function, message: message)
        if debugPrint {
            print("matched \(matchingFilters) of \(nonRequiredFilters.count) non-required filters")
        }
        return (matchingFilters, nonRequiredFilters.count)
    }
    
    /// returns a tuple of matched and all exclude filters
    func passedExcludedFilters(_ level: LogLevel,
                               path: String, function: String, message: String?) -> (Int, Int) {
        let excludeFilters = self.filters.filter { filter in
            return filter.isExcluded()
        }
        
        let matchingFilters = applyFilters(excludeFilters, level: level,
                                           path: path, function: function, message: message)
        if debugPrint {
            print("matched \(matchingFilters) of \(excludeFilters.count) exclude filters")
        }
        return (matchingFilters, excludeFilters.count)
    }
    
    func applyFilters(_ targetFilters: [FilterType], level: LogLevel,
                      path: String, function: String, message: String?) -> Int {
        return targetFilters.filter { filter in
            
            let passes: Bool
            
            if !filter.reachedMinLevel(level) {
                return false
            }
            
            switch filter.getTarget() {
            case .Path(_):
                passes = filter.apply(path)
                
            case .Function(_):
                passes = filter.apply(function)
                
            case .Message(_):
                guard let message = message else {
                    return false
                }
                
                passes = filter.apply(message)
            }
            
            return passes
            }.count
    }
    
}

extension BaseDestination: Equatable {

}

public func == (lhs: BaseDestination, rhs: BaseDestination) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}
