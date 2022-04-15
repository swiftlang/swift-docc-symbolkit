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

let package = Package(
    name: "SymbolKit",
    products: [
        .library(
            name: "SymbolKit",
            targets: ["SymbolKit"]),
    ],
    targets: [
        .target(
            name: "SymbolKit",
            dependencies: []),
        .testTarget(
            name: "SymbolKitTests",
            dependencies: ["SymbolKit"]),
    ]
)
