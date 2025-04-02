/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
@testable import SymbolKit

class SemanticVersionTests: XCTestCase {
    typealias SemanticVersion = SymbolGraph.SemanticVersion
    
    func testVersionInit() {
        let version = SemanticVersion(major: 1, minor: 2, patch: 3, prerelease: "beta", buildMetadata: "enableX")
        
        XCTAssertEqual(version.major, 1)
        XCTAssertEqual(version.minor, 2)
        XCTAssertEqual(version.patch, 3)
        XCTAssertEqual(version.prerelease, "beta")
        XCTAssertEqual(version.buildMetadata, "enableX")
    }

    func testDecodeSemanticVersionWithIntPreRelease() throws {
        let inputJson: String = """
        {
          "major": 1,
          "minor": 2,
          "patch": 3,
          "prerelease": 4
        }
        """

        let version = try JSONDecoder().decode(SemanticVersion.self, from: inputJson.data(using: .utf8)!)

        XCTAssertEqual(version.major, 1)
        XCTAssertEqual(version.minor, 2)
        XCTAssertEqual(version.patch, 3)
        XCTAssertEqual(version.prerelease, "4")
    }

    func testDecodeSemanticVersionWithStringPreRelease() throws {
        let inputJson: String = """
        {
          "major": 1,
          "minor": 2,
          "patch": 3,
          "prerelease": "4"
        }
        """

        let version = try JSONDecoder().decode(SemanticVersion.self, from: inputJson.data(using: .utf8)!)

        XCTAssertEqual(version.major, 1)
        XCTAssertEqual(version.minor, 2)
        XCTAssertEqual(version.patch, 3)
        XCTAssertEqual(version.prerelease, "4")
    }

    func testDecodeSemanticVersionWithNoPreRelease() throws {
        let inputJson: String = """
        {
          "major": 1,
          "minor": 2,
          "patch": 3
        }
        """

        let version = try JSONDecoder().decode(SemanticVersion.self, from: inputJson.data(using: .utf8)!)

        XCTAssertEqual(version.major, 1)
        XCTAssertEqual(version.minor, 2)
        XCTAssertEqual(version.patch, 3)
        XCTAssertNil(version.prerelease)
    }
}
