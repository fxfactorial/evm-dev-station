// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "evm-dev-station",
  platforms: [.macOS(.v14)],
  products: [
    // this is the wrapper as module for golang code
    .library(
      name: "EVMBridge",
      targets: ["EVMBridge"]),
    .library(name: "EVMUI", targets: ["EVMUI"]),
    .library(name: "DevStationCommon", targets: ["DevStationCommon"])
  ],
  dependencies: [
    // .package(url: "https://github.com/Boilertalk/Web3.swift.git", from: "0.8.4")
    .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
    .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.5.1"),
    // .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.0.3"))
  ],
  targets: [
    .target(name: "DevStationCommon",
            dependencies: [
              // .product(name: "Web3ContractABI", package: "Web3.swift"),
              // "Web3ContractABI",
              "BigInt",
              "CryptoSwift",
              // .product(name: "Collections", package: "swift-collections")
            ],
            path: "Sources/DevStationCommon"),
    .target(
      name: "EVMBridge",
      resources: [
        // technically not even needed!
        .copy("../../libevm-bridge.a"),
        .process("../../libevm-bridge.a")
      ],
      linkerSettings: [.unsafeFlags(["-L."]), .linkedLibrary("evm-bridge")]
    ),
    // so that xcode can use this "scheme" and we can use #preview
    .target(
      name:"EVMUI",
      dependencies: ["DevStationCommon"],
      path: "Sources/EVMUI"
    ),
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .executableTarget(
      name: "evm-dev-station",
      dependencies: ["EVMBridge", "EVMUI", "DevStationCommon"],
      path: "Sources/DevStation"
    ),
    .executableTarget(
      name: "quick-test",
      dependencies: ["EVMBridge", "DevStationCommon"],
      path: "Sources/QuickTest"
    )
  ]
)
