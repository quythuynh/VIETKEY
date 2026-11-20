// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VietKeyCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "VietEngine", targets: ["VietEngine"]),
        .library(name: "VietCharset", targets: ["VietCharset"]),
    ],
    targets: [
        // Swift standard library only.
        .target(name: "VietEngine"),
        .target(name: "VietCharset"),
        .testTarget(
            name: "VietKeyCoreTests",
            dependencies: ["VietEngine", "VietCharset"]
        ),
    ]
)
