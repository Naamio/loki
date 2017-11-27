import Loki

let consoleBackend = ConsoleBackend()
Loki.addBackend(consoleBackend)     // add backend for collector's internal logging

LokiCollector.addBackend(consoleBackend)    // add backend for collector itself
LokiCollector.start(listenPort: 8000)
