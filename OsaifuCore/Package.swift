// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OsaifuCore",
    platforms: [.iOS("27.0"), .macOS("27.0"), .watchOS("27.0")],
    products: [
        .library(name: "OsaifuCore", targets: ["OsaifuCore"])
    ],
    targets: [
        .target(name: "OsaifuCore")
    ]
)
