# Loki

`Loki` is a generic logging library for Swift applications. It supports asynchronous logging, 
multiple destinations and also offers some default destination for logging.

## Usage

You can import and use it like so,

``` swift
import Loki

Loki.sourceName = "Foobar"  // Name of the app (optional)
Loki.logLevel = .info       // default (supports 4 other levels)

let console = ConsoleDestination()      // define console destination (stdout)
Loki.addDestination(console)

if let file = FileDestination(inPath: "/tmp/foo.log") {
    Loki.addDestination(file)   // log to file
}

let queue = DispatchQueue(label: "logging", qos: .utility)
Loki.dispatchQueue = queue          // queue for async logging

// Now you can log stuff
Loki.info("Hola!")
```

This logs something like below in console and the file,

```
[1970-01-01T00:00:01.000Z] [INFO] [:main.swift:20 testing] Hola!
```

### Global logging

You may have multiple services in your platform, and you cannot pay a visit to 
all the services all the time. When it comes to microservices, you need a 
centralized logging service.

There are multiple options.

If you don't have a lot of services, then you can share the volume, and maintain 
a shared log file (like `/var/global.log`). In such a case, all the applications 
could have the same file destination.

On the other hand, if you have a lot of services, then it makes sense to have a 
HTTP destination. That's where `LokiCollector` comes in. It serves as your 
centralized logging service.

``` swift
import Loki

let console = ConsoleDestination()
Loki.addDestination(console)
Loki.logLevel = .info   // filter log messages on the server end

// Spin up the server with an (optional) authorization check.
LokiCollector.start(listenPort: 8000, authorizeWith: "foobar")
```

Assuming the service address is `1.2.3.4`, we can now do the following 
in the application.

``` swift
let httpClient = HttpDestination(url: "http://1.2.3.4:8000")
httpClient.hostAuth = "foobar"
Loki.addDestination(httpClient)

Loki.error("Whee!")
```

This logs something like below in the service console,

```
[1970-01-01T00:00:01.000Z] [ERROR] [:main.swift:10 testing] Whee!
```
