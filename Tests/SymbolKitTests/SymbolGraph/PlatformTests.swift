/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
import SymbolKit

class PlatformTests: XCTestCase {
    func testValidOperatingSystems() {
        let testPairs: [(inputName: String, expectedName: String)] = [
            ("macos", "macOS"),
            ("macosx", "macOS"),
            ("ios", "iOS"),
            ("tvos", "tvOS"),
            ("watchos", "watchOS"),
            ("visionos", "visionOS"),
            ("linux", "Linux"),
        ]

        for (inputName, expectedName) in testPairs {
            let platform = SymbolGraph.Platform(
                architecture: nil,
                vendor: nil,
                operatingSystem: .init(name: inputName),
                environment: nil
            )

            XCTAssertEqual(platform.name, expectedName, "'\(inputName)' should be a valid OS identifier.")
        }
    }

    func testUnknownOperatingSystemName() {
        let platform = SymbolGraph.Platform(
            architecture: nil,
            vendor: nil,
            operatingSystem: SymbolGraph.OperatingSystem(name: "unknown platform"),
            environment: nil
        )

        XCTAssertEqual(platform.name, "unknown platform")
    }

    func testMacCatalystName() {
        let platform = SymbolGraph.Platform(
            architecture: nil,
            vendor: nil,
            operatingSystem: SymbolGraph.OperatingSystem(name: "ios"),
            environment: "macabi"
        )

        XCTAssertEqual(platform.name, "macCatalyst", "'ios' should return macCatalyst when set with 'macabi'.")
    }
}
