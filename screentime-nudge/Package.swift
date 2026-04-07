// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "NudgeBar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "NudgeBar",
            path: "Sources/NudgeBar",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics")
            ]
        )
    ]
)
