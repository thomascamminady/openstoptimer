// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "OpenStopTimerKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "OpenStopTimerKit",
            targets: ["OpenStopTimerKit"]
        )
    ],
    targets: [
        .target(
            name: "OpenStopTimerKit"
        ),
        .testTarget(
            name: "OpenStopTimerKitTests",
            dependencies: ["OpenStopTimerKit"]
        )
    ]
)
