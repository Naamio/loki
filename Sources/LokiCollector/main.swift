import Loki

Loki.addBackend(ConsoleBackend())
LokiCollector.start(listenPort: 8000, authorize: true)
