// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "AllCache",
    products: [
        .library(
            name: "AllCache",
            targets: ["AllCache", "ImageCache"]),
        ],
    dependencies: [
        .package(url: "https://github.com/JuanjoArreola/ShallowPromises.git", from: "0.7.1"),
        .package(url: "https://github.com/JuanjoArreola/Logg.git", from: "2.4.0")
    ],
    targets: [
        .target(
            name: "AllCache",
            dependencies: ["ShallowPromises", "Logg"]
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
