// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Doo",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.1"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "DooCore",
            path: "Sources/DooCore"
        ),
        .target(
            name: "DooKit",
            dependencies: ["DooCore", "HotKey"],
            path: "Sources/DooKit"
        ),
        .target(
            name: "DooCLILib",
            dependencies: [
                "DooCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/DooCLILib"
        ),
        .executableTarget(
            name: "Doo",
            dependencies: ["DooKit", "HotKey"],
            path: "Sources/Doo"
        ),
        .executableTarget(
            name: "DooCLI",
            dependencies: ["DooCore", "DooCLILib"],
            path: "Sources/DooCLI"
        ),
        .testTarget(
            name: "DooTests",
            dependencies: ["DooKit", "DooCore"],
            path: "Tests/DooTests"
        ),
        .testTarget(
            name: "DooCLITests",
            dependencies: ["DooCLILib", "DooCore"],
            path: "Tests/DooCLITests"
        ),
    ]
)
