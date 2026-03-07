// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StockTracker",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "StockTracker",
            path: "Sources/StockTracker"
        ),
        .testTarget(
            name: "StockTrackerTests",
            dependencies: ["StockTracker"],
            path: "Tests/StockTrackerTests"
        )
    ]
)
