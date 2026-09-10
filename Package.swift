// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MScroll",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MScroll", targets: ["MScroll"])
    ],
    targets: [
        .executableTarget(name: "MScroll")
    ],
    swiftLanguageModes: [.v5]
)
