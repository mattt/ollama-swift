// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Ollama",
    platforms: [
        .macOS(.v13),
        .macCatalyst(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "Ollama",
            targets: ["Ollama"])
    ],
    targets: [
        .target(
            name: "Ollama",
            dependencies: [])
    ]
)
