import PackageDescription

let package = Package(
    name: "AllCache",
    dependencies: [
        .Package(url: "../Logg", Version(2, 0, 0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "../AsyncRequest", Version(2, 0, 0, prereleaseIdentifiers: ["beta"]))
    ]
)
