// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Glide",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Glide", targets: ["Glide"])
    ],
    targets: [
        .executableTarget(name: "Glide")
    ],
    swiftLanguageModes: [.v5]
)
