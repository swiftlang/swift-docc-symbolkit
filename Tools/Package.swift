// swift-tools-version:5.5
/*
 This source file is part of the Swift.org open source project
 Copyright (c) 2023 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception
 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import PackageDescription

let package = Package(
    name: "Tools",
    products: [
        .executable(name: "dump-unified-graph", targets: ["dump-unified-graph"]),
    ],
    dependencies: [
        .package(name: "SymbolKit", path: "../."),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.2"),
    ],
    targets: [
        .executableTarget(
            name: "dump-unified-graph",
            dependencies: [
                .product(name: "SymbolKit", package: "SymbolKit"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "dump-unified-graph"
        ),
    ]
)