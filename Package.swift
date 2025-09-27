// swift-tools-version: 5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DeepOneSDK",

    products: [
        .library(
            name: "DeepOneSDK",
            targets: ["DeepOneSDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/deeponelabs/deepone-ios-networking.git", from: "1.1.5")
    ],
    targets: [
        .target(
            name: "DeepOneSDK",
            dependencies: [
                .product(name: "DeepOneNetworking", package: "deepone-ios-networking")
            ],
            path: "DeepOneSDK",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath(".")
            ]
        ),
    ]
)
