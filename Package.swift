// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Loki",
    products: [
        .executable(
            name: "LokiDaemon",
            targets: ["LokiDaemon"]),
        .library(
            name: "Loki",
            targets: ["Loki"]),
        .library(
            name: "LokiHTTP",
            targets: ["LokiHTTP"]),
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/Kitura", from: "2.3.0"),
        .package(url: "https://github.com/vapor/crypto", from: "3.1.2")
    ],
    targets: [
        .target(
            name: "Loki",
            dependencies: []),
        .target(
            name: "LokiHTTP",
            dependencies: ["Crypto", "Loki", "Kitura"]),
        .target(
            name: "LokiCollector",
            dependencies: ["Loki", "LokiHTTP"]
        ),
        .target(
            name: "LokiDaemon",
            dependencies: ["LokiCollector"]),
        .testTarget(
            name: "LokiTests",
            dependencies: ["Loki", "LokiCollector"])
    ]
)
