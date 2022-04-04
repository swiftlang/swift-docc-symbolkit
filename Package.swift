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
import Foundation

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
            dependencies: [],
            swiftSettings: librarySwiftSettings()
        ),
        .testTarget(
            name: "SymbolKitTests",
            dependencies: ["SymbolKit"]),
    ]
)

func librarySwiftSettings() -> [SwiftSetting]? {
    let manifestLocation = URL(fileURLWithPath: #filePath)

    let enableLibraryEvolutionFileLocation = manifestLocation
        .deletingLastPathComponent()
        .appendingPathComponent(".enable-library-evolution")
    
    // If there is a `.enable-library-evolution` file as a sibling of this package manifest
    // build libraries with library evolution enabled.
    if FileManager.default.fileExists(atPath: enableLibraryEvolutionFileLocation.path) {
        return [
            .unsafeFlags(["-enable-library-evolution"])
        ]
    } else {
        return []
    }
}
