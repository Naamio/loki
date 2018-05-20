import Foundation
import Crypto

import Loki

// platform-dependent import frameworks to get device details
// valid values for os(): OSX, iOS, watchOS, tvOS, Linux
// in Swift 3 the following were added: FreeBSD, Windows, Android
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
var DEVICE_MODEL: String {
    get {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
#else
let DEVICE_MODEL = ""
#endif

#if os(iOS) || os(tvOS)
var DEVICE_NAME = UIDevice.current.name
#else
// under watchOS UIDevice is not existing, http://apple.co/26ch5J1
let DEVICE_NAME = ""
#endif

/// Loki HTTP destination for sending messages to another server.
/// This currently utilizes `Kitura` and `SwiftyRequest`.
public class HTTPDestination: BaseDestination {
    
    // destination
    override public var defaultHashValue: Int {return 3}
    
    /// Host authorization string.
    public var hostAuth: String? = nil
    
    public var hostURL: String
    
    public var entriesFileURL = URL(fileURLWithPath: "")
    
    public var sendingFileURL = URL(fileURLWithPath: "")
    
    public var showNSLog = false // executes toNSLog statements to debug the class
    
    public var encryptionKey = ""
    
    let fileManager = FileManager.default
    
    let isoDateFormatter = DateFormatter()
    
    private let minAllowedThreshold = 1  // over-rules SendingPoints.Threshold
    
    private let maxAllowedThreshold = 1000  // over-rules SendingPoints.Threshold
    
    private var sendingInProgress = false
    
    private var initialSending = true
    
    private let entriesFileName: String = "http_entries.json"
    
    private let sendingfileName: String = "http_entries_sending.json"
    
    /// Initialize a new `HTTPDestination` instance
    /// with a given URL.
    public init(url: String) {
        // TODO: Check the URL is valid. / Change the type.
        hostURL = url
        super.init()
        
        // setup where to write the json files
        var baseURL: URL?
        
        #if os(OSX)
        if let url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            baseURL = url
            // try to use ~/Library/Application Support/APP NAME instead of ~/Library/Application Support
            if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String {
                do {
                    if let appURL = baseURL?.appendingPathComponent(appName, isDirectory: true) {
                        try fileManager.createDirectory(at: appURL,
                                                        withIntermediateDirectories: true, attributes: nil)
                        baseURL = appURL
                    }
                } catch {
                    // it is too early in the class lifetime to be able to use toNSLog()
                    print("Warning! Could not create folder ~/Library/Application Support/\(appName).")
                }
            }
        }
        #else
        #if os(tvOS)
        // tvOS can just use the caches directory
        if let url = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            baseURL = url
        }
        #elseif os(Linux)
        // Linux is using /var/cache
        let baseDir = "/var/cache/"
        entriesFileURL = URL(fileURLWithPath: baseDir + entriesFileName)
        sendingFileURL = URL(fileURLWithPath: baseDir + sendingfileName)
        #else
        // iOS and watchOS are using the app’s document directory
        if let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            baseURL = url
        }
        #endif
        #endif
        
        #if !os(Linux)
        if let baseURL = baseURL {
            // is just set for everything but not Linux
            entriesFileURL = baseURL.appendingPathComponent(entriesFileName,
                                                            isDirectory: false)
            sendingFileURL = baseURL.appendingPathComponent(sendingfileName,
                                                            isDirectory: false)
        }
        #endif
    }
    
    override public var asynchronously: Bool {
        get {
            return false
        }
        set {
            return
        }
    }

    override public func send(_ level: LogLevel, text: String, file: String,
                                function: String, line: Int, thread: String, context: Any?) -> String? {

        let reportLocation: [String: Any] = ["filePath": file, "lineNumber": line, "functionName": function]
        var httpContext: [String: Any] = ["reportLocation": reportLocation]
        
        if let context = context as? [String: Any] {
            if let httpRequestContext =  context["httpRequest"] as? [String: Any] {
                httpContext["httpRequest"] = httpRequestContext
            }
            
            if let user = context["user"] as? String {
                httpContext["user"] = user
            }
        }
        
        let payloadDictionary: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "serviceContext": [
                "url": hostURL
            ],
            "thread": thread,
            "message": text,
            "severity": level.description,
            "context": httpContext
        ]
        
        let finalLogString: String
        
        do {
            finalLogString = try jsonString(obj: payloadDictionary)
        } catch {
            let uncrashableLogString = "{\"context\":{\"reportLocation\":{\"filePath\": \"\(file)\"" +
                ",\"functionName\":\"\(function)\"" +
                ",\"lineNumber\":\(line)},\"severity\"" +
                ":\"CRITICAL\",\"message\":\"Error encoding " +
            "JSON log entry. You may be losing log messages!\"}"
            finalLogString = uncrashableLogString.description
        }
        
        _ = saveToFile(finalLogString, url: entriesFileURL)
        
        return finalLogString
    }
    
    // MARK: File Handling
    /// appends a string as line to a file.
    /// returns boolean about success
    func saveToFile(_ str: String, url: URL, overwrite: Bool = false) -> Bool {
        do {
            if fileManager.fileExists(atPath: url.path) == false || overwrite {
                // create file if not existing
                let line = str + "\n"
                try line.write(to: url, atomically: true, encoding: String.Encoding.utf8)
            } else {
                // append to end of file
                let fileHandle = try FileHandle(forWritingTo: url)
                _ = fileHandle.seekToEndOfFile()
                let line = str + "\n"
                if let data = line.data(using: String.Encoding.utf8) {
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            }
            return true
        } catch {
            toNSLog("Error! Could not write to file \(url).")
            return false
        }
    }
    
    func sendFileExists() -> Bool {
        return fileManager.fileExists(atPath: sendingFileURL.path)
    }
    
    func renameJsonToSendFile() -> Bool {
        do {
            try fileManager.moveItem(at: entriesFileURL, to: sendingFileURL)
            return true
        } catch {
            toNSLog("HTTP Destination could not rename json file.")
            return false
        }
    }
    
    /// returns optional array of log dicts from a file which has 1 json string per line
    func logsFromFile(_ url: URL) -> [[String:Any]]? {
        var lines = 0
        do {
            // try to read file, decode every JSON line and put dict from each line in array
            let fileContent = try String(contentsOfFile: url.path, encoding: .utf8)
            let linesArray = fileContent.components(separatedBy: "\n")
            var dicts = [[String: Any]()] // array of dictionaries
            for lineJSON in linesArray {
                lines += 1
                if lineJSON.first == "{" && lineJSON.last == "}" {
                    // try to parse json string into dict
                    if let data = lineJSON.data(using: .utf8) {
                        do {
                            if let dict = try JSONSerialization.jsonObject(with: data,
                                                                           options: .mutableContainers) as? [String:Any] {
                                if !dict.isEmpty {
                                    dicts.append(dict)
                                }
                            }
                        } catch {
                            var msg = "Error! Could not parse "
                            msg += "line \(lines) in file \(url)."
                            toNSLog(msg)
                        }
                    }
                }
            }
            dicts.removeFirst()
            return dicts
        } catch {
            toNSLog("Error! Could not read file \(url).")
        }
        return nil
    }
    
    /// returns AES-256 CBC encrypted optional string
    func encrypt(_ str: String) -> String? {

        var plainText: String?

        do {
            let cipherText = try AES256.encrypt(str, key: encryptionKey)
            plainText = String(data: cipherText, encoding: String.Encoding.utf8) as String?
        } catch {

        }
        
        return plainText
    }
    
    /// Delete file to get started again
    func deleteFile(_ url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            toNSLog("Warning! Could not delete file \(url).")
        }
        return false
    }
    
    // MARK: Debug Helpers
    /// log String to toNSLog. Used to debug the class logic
    func toNSLog(_ str: String) {
        if showNSLog {
            #if os(Linux)
            print("HTTP: \(str)")
            #else
            NSLog("HTTP: \(str)")
            #endif
        }
    }
    
    private func jsonString(obj: Dictionary<String, Any>) throws -> String {
        let json = try JSONSerialization.data(withJSONObject: obj, options: [])
        guard let string = String(data: json, encoding: .utf8) else {
            throw HTTPError.serialization
        }
        return string
    }
}

private enum HTTPError: Error {
    case serialization
}
