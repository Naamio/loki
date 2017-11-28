import Dispatch
import Foundation
import Loki

func getEnvVariable(_ variable: String) -> String? {
    return ProcessInfo.processInfo.environment[variable]
}

guard let port = Int(getEnvVariable("LOKI_SERVICE_PORT") ?? "8000") else {
    print("Invalid port value")
    exit(1)
}

Loki.logLevel = LogLevel(getEnvVariable("LOG") ?? "INFO") ?? .info

let consoleBackend = ConsoleBackend()
Loki.addBackend(consoleBackend)     // add backend for logging

if let logPath = getEnvVariable("FILE") {
    if let file = FileBackend(inPath: logPath) {
        Loki.dispatchQueue = DispatchQueue(label: "logging", qos: .utility)
        Loki.addBackend(file)
    } else {
        print("Failed to open file for writing")
        exit(1)
    }
}

LokiCollector.start(listenPort: port)
