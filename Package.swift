// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Doo",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.1"),
    ],
    targets: [
        .executableTarget(
            name: "Doo",
            dependencies: ["HotKey"],
            path: "Doo"
        ),
    ]
)
