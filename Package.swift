// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenFreebuds",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "FreebudsMAC", targets: ["FreebudsMAC"]),
        .library(name: "OFBCore", targets: ["OFBCore"]),
        .library(name: "OFBBluetooth", targets: ["OFBBluetooth"]),
        .library(name: "OFBPlatform", targets: ["OFBPlatform"]),
    ],
    targets: [
        // MARK: - SwiftUI App Target
        .executableTarget(
            name: "FreebudsMAC",
            dependencies: ["OFBCore", "OFBBluetooth", "OFBPlatform"],
            path: "FreebudsMAC",
            resources: [
                .process("Assets.xcassets")
            ]
        ),
        // MARK: - Core Logic
        .target(
            name: "OFBCore",
            dependencies: ["OFBBluetooth", "OFBPlatform"],
            path: "Sources/OFBCore"
        ),
        // MARK: - Bluetooth Layer (IOBluetooth)
        .target(
            name: "OFBBluetooth",
            dependencies: [],
            path: "Sources/OFBBluetooth",
            linkerSettings: [
                .linkedFramework("IOBluetooth"),
            ]
        ),
        // MARK: - Platform Services
        .target(
            name: "OFBPlatform",
            dependencies: [],
            path: "Sources/OFBPlatform"
        ),
        // MARK: - Tests
        .testTarget(
            name: "OFBCoreTests",
            dependencies: ["OFBCore"],
            path: "Tests/OFBCoreTests"
        ),
    ]
)
