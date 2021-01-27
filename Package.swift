// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "gatekeeper",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "Gatekeeper",
            targets: ["Gatekeeper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.38.0"),
    ],
    targets: [
        .target(
            name: "Gatekeeper",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ]),
        .testTarget(
            name: "GatekeeperTests",
            dependencies: [
                "Gatekeeper",
                .product(name: "XCTVapor", package: "vapor")
            ]),
    ]
)
