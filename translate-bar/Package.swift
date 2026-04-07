// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "TranslateBar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "TranslateBar",
            path: "Sources/TranslateBar",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("WebKit"),
                .linkedFramework("Carbon")
            ]
        )
    ]
)
