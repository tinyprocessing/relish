// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RelishCLI",
    defaultLocalization: "en",
    platforms: [.macOS("13.0")],
    products: [
        .executable(name: "relish", targets: ["relish"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .exactItem("1.1.3")),
        .package(url: "https://github.com/tuist/xcodeproj.git", .exactItem("8.9.0")),
        .package(url: "https://github.com/jpsim/Yams.git", .exactItem("4.0.6")),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .exactItem("0.9.15")),
        .package(url: "https://github.com/mxcl/Version.git", .exactItem("2.0.1")),
        .package(url: "https://github.com/ChargePoint/xcparse", .exactItem("2.3.1")),
        .package(url: "https://github.com/apple/swift-syntax.git", .exactItem("508.0.0")),
        .package(url: "https://github.com/kylef/JSONSchema.swift", .exactItem("0.6.0"))
    ],
    targets: [
        .executableTarget(
            name: "relish",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
                .product(name: "XcodeProj", package: "XcodeProj"),
                .product(name: "Version", package: "Version"),
                .product(name: "XCParseCore", package: "xcparse"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "JSONSchema", package: "JSONSchema.swift")
            ], path: "Sources"
        )
    ]
)
