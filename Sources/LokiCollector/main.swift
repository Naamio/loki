import Foundation
import Loki

func getEnvVariable(_ variable: String) -> String? {
    return ProcessInfo.processInfo.environment[variable]
}

guard let port = Int(getEnvVariable("PORT") ?? "8000") else {
    print("Invalid port value")
    exit(0)
}

Loki.logLevel = LogLevel(getEnvVariable("LOG") ?? "INFO") ?? .info

let consoleBackend = ConsoleBackend()
Loki.addBackend(consoleBackend)     // add backend for collector's internal logging

LokiCollector.addBackend(consoleBackend)    // add backend for collector itself
LokiCollector.start(listenPort: port)
