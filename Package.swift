// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LCLogger",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "LCLogger",
            targets: ["LCLogger"]
        )
    ],
    targets: [
        .target(
            name: "LCLogger"
        ),
        .testTarget(
            name: "LCLoggerTests",
            dependencies: ["LCLogger"]
        )
    ]
)
