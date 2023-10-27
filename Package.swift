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
  targets: [
    .target(name: "DevStationCommon", path: "Sources/DevStationCommon"),
    .target(
      name: "EVMBridge",
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
  ]
)
