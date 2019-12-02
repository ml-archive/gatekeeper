// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Gatekeeper",
    platforms: [
       .macOS(.v10_14)
    ],
    products: [
        .library(name: "Gatekeeper", targets: ["Gatekeeper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta")
    ],
    targets: [
        .target(name: "Gatekeeper", dependencies: ["Vapor"]),
        .testTarget(name: "GatekeeperTests", dependencies: ["Gatekeeper"]),
    ]
)
