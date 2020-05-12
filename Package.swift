// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "AllCache",
    products: [
        .library(
            name: "AllCache",
            targets: ["AllCache"]),
        ],
    dependencies: [
        .package(url: "https://github.com/JuanjoArreola/Logg.git", from: "2.3.0"),
        .package(url: "https://github.com/JuanjoArreola/AsyncRequest.git", from: "2.3.0")
    ],
    targets: [
        .target(
            name: "AllCache",
            dependencies: ["Logg", "AsyncRequest"],
            path: "Sources"
        ),
        .testTarget(
            name: "AllCacheTests",
            dependencies: ["AllCache"],
            path: "Tests"
        )
    ]
)
