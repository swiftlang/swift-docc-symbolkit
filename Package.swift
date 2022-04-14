// swift-tools-version:5.2
// In order to support users running on the latest Xcodes, please ensure that
// Package@swift-5.5.swift is kept in sync with this file.
/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import PackageDescription
import class Foundation.ProcessInfo

let package = Package(
    name: "SymbolKit",
    products: [
        .library(
            name: "SymbolKit",
            targets: ["SymbolKit"]),
        .executable(
            name: "dump-unified-graph",
            targets: ["dump-unified-graph"]),
    ],
    targets: [
        .target(
            name: "SymbolKit",
            dependencies: []),
        .testTarget(
            name: "SymbolKitTests",
            dependencies: ["SymbolKit"]),
        .executableTarget(
            name: "dump-unified-graph",
            dependencies: [
                "SymbolKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
    ]
)

// If the `SWIFTCI_USE_LOCAL_DEPS` environment variable is set,
// we're building in the Swift.org CI system alongside other projects in the Swift toolchain and
// we can depend on local versions of our dependencies instead of fetching them remotely.
if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
    // Building standalone, so fetch all dependencies remotely.
    package.dependencies += [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "1.0.1")),
    ]
} else {
    // Building in the Swift.org CI system, so rely on local versions of dependencies.
    package.dependencies += [
        .package(path: "../swift-argument-parser"),
    ]
}
