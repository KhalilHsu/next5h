// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Next5h",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Next5h",
            targets: ["Next5h"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Next5h",
            dependencies: [],
            path: "Sources/Next5h"
        ),
        .testTarget(
            name: "Next5hTests",
            dependencies: ["Next5h"],
            path: "Tests/Next5hTests"
        )
    ]
)
