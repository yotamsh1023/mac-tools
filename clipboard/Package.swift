// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "ClipBoard",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ClipBoard",
            path: "Sources/ClipBoard",
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("AppKit"),
                .linkedLibrary("sqlite3")
            ]
        )
    ]
)
