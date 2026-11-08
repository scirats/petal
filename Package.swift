// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Petal",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Petal", targets: ["Petal"]),
        .executable(name: "petalctl", targets: ["petalctl"]),
        .library(name: "PetalCore", targets: ["PetalCore"]),
        .library(name: "PetalCLI", targets: ["PetalCLI"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/MrKai77/Luminare.git",
            revision: "7958d31278ad054abf0a7cf19e5ae700399a812f"
        ),
    ],
    targets: [
        .target(name: "PetalCore"),
        .target(name: "PetalCLI", dependencies: ["PetalCore"]),
        .executableTarget(
            name: "Petal",
            dependencies: [
                "PetalCore",
                .product(name: "Luminare", package: "Luminare"),
            ]
        ),
        .executableTarget(name: "petalctl", dependencies: ["PetalCLI"]),
        .testTarget(name: "PetalCoreTests", dependencies: ["PetalCore"]),
        .testTarget(name: "PetalCLITests", dependencies: ["PetalCLI", "PetalCore"]),
    ],
    swiftLanguageModes: [.v6]
)
