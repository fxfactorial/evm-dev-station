// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "evm-dev-station",
  platforms: [.macOS(.v14)],
  // this is the wrapper as module for golang code
  products: [
    .library(
      name: "EVMBridge",
      targets: ["EVMBridge"])
  ],
  targets: [
    .target(
      name: "EVMBridge",
      linkerSettings: [.unsafeFlags(["-L."]), .linkedLibrary("evm-bridge")]
    ),
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .executableTarget(
      name: "evm-dev-station",
      dependencies: ["EVMBridge"],
      path: "Sources/DevStation"
    ),
  ]
)
