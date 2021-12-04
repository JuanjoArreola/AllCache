// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "AllCache",
    platforms: [
        .macOS(.v12), .iOS(.v15), .tvOS(.v15), .watchOS(.v8)
    ],
    products: [
        .library(
            name: "AllCache",
            targets: ["AllCache", "ImageCache"]),
        ],
    dependencies: [],
    targets: [
        .target(
            name: "AllCache",
            dependencies: []
        ),
        .target(
            name: "ImageCache",
            dependencies: ["AllCache"]
        ),
        .testTarget(
            name: "AllCacheTests",
            dependencies: ["AllCache"]
        ),
        .testTarget(
            name: "ImageCacheTests",
            dependencies: ["ImageCache"]
        )
    ]
)
