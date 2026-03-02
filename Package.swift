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
        .target(
            name: "DooKit",
            dependencies: ["HotKey"],
            path: "Sources/DooKit"
        ),
        .executableTarget(
            name: "Doo",
            dependencies: ["DooKit", "HotKey"],
            path: "Sources/Doo"
        ),
        .testTarget(
            name: "DooTests",
            dependencies: ["DooKit"],
            path: "Tests/DooTests"
        ),
    ]
)
