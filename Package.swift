import PackageDescription

let package = Package(
    name: "Gatekeeper",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2)
    ]
)
