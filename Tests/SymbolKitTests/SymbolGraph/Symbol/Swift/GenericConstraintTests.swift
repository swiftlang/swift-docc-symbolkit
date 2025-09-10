/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2023-2025 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
@testable import SymbolKit

class GenericConstraintTests: XCTestCase {

    func testInitializeConformance() throws {
        let jsonString = """
        {
            "kind": "conformance",
            "lhs": "Self",
            "rhs": "Hashable",
        }
        """
        let jsonData = Data(jsonString.utf8)
        let jsonConstraint = try JSONDecoder().decode(SymbolGraph.Symbol.Swift.GenericConstraint.self, from: jsonData)
        let constraint = SymbolGraph.Symbol.Swift.GenericConstraint(
            kind: .conformance,
            leftTypeName: "Self",
            rightTypeName: "Hashable"
        )
        XCTAssertEqual(jsonConstraint, constraint)
    }

    func testInitializeSuperclass() throws {
        let jsonString = """
        {
            "kind": "superclass",
            "lhs": "Self",
            "rhs": "String",
        }
        """
        let jsonData = Data(jsonString.utf8)
        let jsonConstraint = try JSONDecoder().decode(SymbolGraph.Symbol.Swift.GenericConstraint.self, from: jsonData)
        let constraint = SymbolGraph.Symbol.Swift.GenericConstraint(
            kind: .superclass,
            leftTypeName: "Self",
            rightTypeName: "String"
        )
        XCTAssertEqual(jsonConstraint, constraint)
    }

    func testInitializeSameType() throws {
        let jsonString = """
        {
            "kind": "sameType",
            "lhs": "Self",
            "rhs": "Problem",
        }
        """
        let jsonData = Data(jsonString.utf8)
        let jsonConstraint = try JSONDecoder().decode(SymbolGraph.Symbol.Swift.GenericConstraint.self, from: jsonData)
        let constraint = SymbolGraph.Symbol.Swift.GenericConstraint(
            kind: .sameType,
            leftTypeName: "Self",
            rightTypeName: "Problem"
        )
        XCTAssertEqual(jsonConstraint, constraint)
    }

    func testInitializeSameShape() throws {
        let jsonString = """
        {
            "kind": "sameShape",
            "lhs": "T1",
            "rhs": "T2",
        }
        """
        let jsonData = Data(jsonString.utf8)
        let jsonConstraint = try JSONDecoder().decode(SymbolGraph.Symbol.Swift.GenericConstraint.self, from: jsonData)
        let constraint = SymbolGraph.Symbol.Swift.GenericConstraint(
            kind: .sameShape,
            leftTypeName: "T1",
            rightTypeName: "T2"
        )
        XCTAssertEqual(jsonConstraint, constraint)
    }
}
