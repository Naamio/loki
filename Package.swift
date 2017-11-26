// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Loki",
    products: [
        .library(
            name: "Loki",
            targets: ["Loki"]),
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/SwiftyRequest.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Loki",
            dependencies: ["SwiftyRequest"]),
        .testTarget(
            name: "LokiTests",
            dependencies: ["Loki"]),
    ]
)
