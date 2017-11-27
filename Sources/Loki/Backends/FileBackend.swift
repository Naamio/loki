import Foundation

/// File backend for logging at the given path.
public class FileBackend {
    let url: URL

    public init?(inPath: String) {
        let fileManager = FileManager()
        if fileManager.createFile(atPath: inPath, contents: nil) {
            url = URL(fileURLWithPath: inPath)
        } else {
            return nil
        }
    }
}

extension FileBackend: LokiBackend {
    public func writeLog(_ logData: LogMessage) {
        let log = logData.toString() + "\n"
        if let data = log.data(using: .utf8) {
            do {
                try data.write(to: url)
            } catch {
                // FIXME: handle write error?
            }
        } else {
            // FIXME: handle encoding error?
        }
    }
}
