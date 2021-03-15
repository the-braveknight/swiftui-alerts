// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUIAlerts",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
    ],
    products: [
        .library(name: "SwiftUIAlerts", targets: ["SwiftUIAlerts"])
    ],
    targets: [
        .target(name: "SwiftUIAlerts", dependencies: [], path: "Sources")
    ]
)
