// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "AllCache",
    products: [
        .library(
            name: "AllCache",
            targets: ["AllCache"]),
        .library(
            name: "NewCache",
            targets: ["NewCache", "ImageCache"]),
        ],
    dependencies: [
        .package(url: "https://github.com/JuanjoArreola/ShallowPromises.git", from: "0.7.1"),
        .package(url: "https://github.com/JuanjoArreola/Logg.git", from: "2.4.0"),
        .package(url: "https://github.com/JuanjoArreola/AsyncRequest.git", from: "2.4.0")
    ],
    targets: [
        .target(
            name: "AllCache",
            dependencies: ["Logg", "AsyncRequest"]
        ),
        .target(
            name: "NewCache",
            dependencies: ["ShallowPromises"]
        ),
        .target(
            name: "ImageCache",
            dependencies: ["NewCache"]
        ),
        .testTarget(
            name: "AllCacheTests",
            dependencies: ["AllCache"],
            path: "Tests"
        )
    ]
)
