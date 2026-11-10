// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OsaifuCore",
    platforms: [.iOS("27.0"), .macOS("27.0"), .watchOS("27.0")],
    products: [
        // One product, three targets. An app links this and then imports the
        // layer it actually needs, so the compiler keeps them apart.
        .library(name: "OsaifuCore", targets: ["OsaifuModel", "OsaifuSync", "OsaifuUI"])
    ],
    targets: [
        // The records, the money and the analytics. Foundation and SwiftData,
        // and nothing else: no SwiftUI, no CloudKit, no WidgetKit.
        .target(name: "OsaifuModel"),

        // What the platform can tell us about sync, and how to ask WidgetKit
        // to draw again.
        .target(name: "OsaifuSync", dependencies: ["OsaifuModel"]),

        // The few views and the colours that every app shares.
        .target(name: "OsaifuUI", dependencies: ["OsaifuModel", "OsaifuSync"]),

        .testTarget(
            name: "OsaifuCoreTests",
            dependencies: ["OsaifuModel", "OsaifuSync", "OsaifuUI"]
        )
    ]
)
