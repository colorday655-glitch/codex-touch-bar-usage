// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "CodexTouchBar",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "CodexUsageCore", targets: ["CodexUsageCore"]),
        .executable(name: "codex-usage", targets: ["codex-usage"]),
    ],
    targets: [
        .target(name: "CodexUsageCore"),
        .executableTarget(name: "codex-usage", dependencies: ["CodexUsageCore"]),
        .testTarget(name: "CodexUsageCoreTests", dependencies: ["CodexUsageCore"]),
    ]
)

