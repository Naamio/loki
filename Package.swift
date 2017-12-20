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
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/Kitura.git", from: "2.0.0"),
        .package(url: "https://github.com/IBM-Swift/SwiftyRequest.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Loki",
            dependencies: ["SwiftyRequest", "Kitura"]),
        .target(
            name: "LokiCollector",
            dependencies: ["Loki"]
        ),
        .target(
            name: "LokiDaemon",
            dependencies: ["LokiCollector"]),
        .testTarget(
            name: "LokiTests",
            dependencies: ["Loki", "LokiCollector"]),
    ]
)
