/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2023 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
@testable import SymbolKit

class ReferenceLocationTests: XCTestCase {
    typealias ReferenceLocation = SymbolGraph.Relationship.ReferenceLocation

    func testRoundTrip() throws {
        let referenceLocation = ReferenceLocation(
            range: .init(
                start: .init(line: 14, character: 0),
                end: .init(line: 14, character: 6)),
            uri: "file://file.swift"
        )
        var source = SymbolGraph.Relationship(source: "source", target: "target", kind: .references, targetFallback: nil)
        source[mixin: ReferenceLocation.self] = referenceLocation

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encodedRelationship = try encoder.encode(source)
        let decoded = try decoder.decode(SymbolGraph.Relationship.self, from: encodedRelationship)

        XCTAssertEqual(source, decoded)
        XCTAssertEqual(decoded[mixin: ReferenceLocation.self], referenceLocation)
    }
}
