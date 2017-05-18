import PackageDescription

let package = Package(
    name: "AllCache",
    dependencies: [
        .Package(url: "https://github.com/JuanjoArreola/Logg.git", majorVersion: 1),
        .Package(url: "https://github.com/JuanjoArreola/AsyncRequest.git", majorVersion: 1)
    ]
)
