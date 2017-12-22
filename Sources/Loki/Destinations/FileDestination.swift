import Foundation

/// File destination for logging at the given path.
public class FileDestination {
    let url: URL

    public init?(inPath: String) {
        let fileManager = FileManager()
        if fileManager.createFile(atPath: inPath, contents: nil) &&
           fileManager.isWritableFile(atPath: inPath) {
            url = URL(fileURLWithPath: inPath)
        } else {
            return nil
        }
    }
}

extension FileDestination: BaseDestination {
    public func writeLog(_ logData: LogMessage) {
        let log = logData.toString() + "\n"
        if var data = log.data(using: .utf8) {
            do {
                if let fileHandle = FileHandle(forWritingAtPath: url.path) {
                    defer {
                        fileHandle.closeFile()
                    }
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                } else {
                    try data.write(to: url, options: .atomic)
                }
            } catch {
                // FIXME: handle write error?
            }
        } else {
            // FIXME: handle encoding error?
        }
    }
}
