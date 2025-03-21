// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Ollama",
    platforms: [
        .macOS(.v13),
        .macCatalyst(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16),
    ],
    products: [
        .library(
            name: "Ollama",
            targets: ["Ollama"])
    ],
    dependencies: [
        .package(url: "https://github.com/loopwork-ai/JSONSchema", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Ollama",
            dependencies: [
                .product(name: "JSONSchema", package: "JSONSchema")
            ])
    ]
)
