// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "WorldClock",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "WorldClock",
            path: "Sources/WorldClock",
            linkerSettings: [
                .linkedFramework("AppKit")
            ]
        )
    ]
)
