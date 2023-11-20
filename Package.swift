// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "evm-dev-station",
  platforms: [.macOS(.v14)],
  products: [
    // The package produces these things which "target" aka use the
    // things in target
    .library(name: "EVMUI", targets: ["EVMUI"]),
    .library(name: "DevStationCommon", targets: ["DevStationCommon"])
  ],
  dependencies: [
    .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
    .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.5.1"),
    .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0-beta.1")
  ],
  targets: [
    .target(name: "DevStationCommon",
            dependencies: [
              "BigInt",
              "CryptoSwift",
              .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            path: "Sources/DevStationCommon"),
    .binaryTarget(name: "EVMBridge", path: "EVMBridgeLibrary.xcframework"),
    .target(
      name:"EVMUI",
      dependencies: ["DevStationCommon"],
      path: "Sources/EVMUI"
    ),
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .executableTarget(
      name: "evm-dev-station",
      dependencies: [
        "EVMBridge",
        "EVMUI",
        "DevStationCommon",
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
      ],
      path: "Sources/DevStation",
      linkerSettings: [
        .unsafeFlags(["-Xlinker", "-sectcreate", 
                      "-Xlinker", "__TEXT",
                      "-Xlinker", "__info_plist", 
                      "-Xlinker", "Sources/Resources/Info.plist" 
                     ])]
    ),
    // remember to define the @_cdecls necessary for linking to work
    .executableTarget(
      name: "quick-test",
      dependencies: [
        "EVMBridge",
        "DevStationCommon",
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
      ],
      path: "Sources/QuickTest"
    )
  ]
)
