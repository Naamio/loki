import Dispatch
import Foundation

import Loki
import LokiCollector

func getEnvVariable(_ variable: String) -> String? {
    return ProcessInfo.processInfo.environment[variable]
}

guard let port = Int(getEnvVariable("LOKI_SERVICE_PORT") ?? "8000") else {
    print("Invalid port value")
    exit(1)
}

let consoleDestination = ConsoleDestination()
Loki.addDestination(consoleDestination)     // add destination for logging

if let logPath = getEnvVariable("FILE") {
    let file = FileDestination() 
    file.url = URL(fileURLWithPath: logPath)
    Loki.addDestination(file)
}

LokiCollector.start(listenPort: port)
