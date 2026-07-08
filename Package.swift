// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RateLimitAgent",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "RateLimitAgent",
            dependencies: [],
            path: "Sources/RateLimitAgent",
            linkerSettings: []
        )
    ]
)
