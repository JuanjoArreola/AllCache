import PackageDescription

let package = Package(
    name: "AllCache",
    dependencies: [
        .Package(url: "https://github.com/JuanjoArreola/Logg.git", majorVersion: 1)
    ]
)
