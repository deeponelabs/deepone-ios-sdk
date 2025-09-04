// swift-tools-version: 5.7
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
    ],
    targets: [
        .target(
            name: "DeepOneSDK",
            dependencies: ["DeepOneNetworking"],
            path: "DeepOneSDK",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath(".")
            ]
        ),
    ]
)
