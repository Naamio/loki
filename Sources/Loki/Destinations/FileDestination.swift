import Foundation

/// File destination for logging at the given path.
public class FileDestination: BaseDestination {
    
    public var url: URL?

    override public var defaultHashValue: Int { 
        return 2
    }
    
    let fileManager = FileManager.default
    
    var fileHandle: FileHandle?

    public override init() {
        // platform-dependent logfile directory default
        var baseURL: URL?
        #if os(OSX)
            if let url = fileManager.urls(for:.cachesDirectory, in: .userDomainMask).first {
                baseURL = url
                // try to use ~/Library/Caches/APP NAME instead of ~/Library/Caches
                if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String {
                    do {
                        if let appURL = baseURL?.appendingPathComponent(appName, isDirectory: true) {
                            try fileManager.createDirectory(at: appURL,
                                                            withIntermediateDirectories: true, attributes: nil)
                            baseURL = appURL
                        }
                    } catch {
                        print("Warning! Could not create folder /Library/Caches/\(appName)")
                    }
                }
            }
        #else
            #if os(Linux)
                baseURL = URL(fileURLWithPath: "/var/cache")
            #else
                // iOS, watchOS, etc. are using the caches directory
                if let url = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                    baseURL = url
                }
            #endif
        #endif

        if let baseURL = baseURL {
            self.url = baseURL.appendingPathComponent("loki.log", isDirectory: false)
        }
        super.init()

        reset = "\u{001b}[0m"
        escape = "\u{001b}[38;5;"
    }
    
    deinit {
        // close file handle if set
        if let fileHandle = fileHandle {
            fileHandle.closeFile()
        }
    }
    
    // append to file. uses full base class functionality
    override public func send(_ level: LogLevel, text: String,
                              file: String, function: String, line: Int, thread: String, context: Any? = nil) -> String? {
        let formattedString = super.send(level, text: text, file: file, function: function, line: line, thread: thread, context: context)
        
        if let str = formattedString {
            _ = saveToFile(str: str)
        }
        return formattedString
    }
    
    /// appends a string as line to a file.
    /// returns boolean about success
    private func saveToFile(str: String) -> Bool {
        guard let url = self.url else {
            return false
        }
        
        do {
            if fileManager.fileExists(atPath: url.path) == false {
                // create file if not existing
                let line = str + "\n"
                try line.write(to: url, atomically: true, encoding: .utf8)
                
                #if os(iOS) || os(watchOS)
                if #available(iOS 10.0, watchOS 3.0, *) {
                    var attributes = try fileManager.attributesOfItem(atPath: url.path)
                    attributes[FileAttributeKey.protectionKey] = FileProtectionType.none
                    try fileManager.setAttributes(attributes, ofItemAtPath: url.path)
                }
                #endif
            } else {
                // append to end of file
                if fileHandle == nil {
                    // initial setting of file handle
                    fileHandle = try FileHandle(forWritingTo: url as URL)
                }
                if let fileHandle = fileHandle {
                    _ = fileHandle.seekToEndOfFile()
                    let line = str + "\n"
                    if let data = line.data(using: String.Encoding.utf8) {
                        fileHandle.write(data)
                    }
                }
            }
            return true
        } catch {
            print("Loki File Destination could not write to file \(url).")
            return false
        }
    }
}
