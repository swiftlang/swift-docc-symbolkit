/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2023 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
import SymbolKit

class ValueConstraintsTests: XCTestCase {
    func testValueConstraintsCanBeDecoded() throws {
        let jsonData = """
          {
            "accessLevel" : "public",
            "identifier" : {
              "interfaceLanguage" : "data",
              "precise" : "data:example:Dictionary@property1"
            },
            "kind" : {
              "displayName" : "Dictionary Key",
              "identifier" : "dictionaryKey"
            },
            "names" : {
              "title" : "property1"
            },
            "pathComponents": [],
            "minimum": 3,
            "maximum": 3.5,
            "default": "str",
            "allowedValues": ["a", 1, null],
        }
        """.data(using: .utf8)
        
        let decoder = JSONDecoder()
        let symbol = try decoder.decode(SymbolGraph.Symbol.self, from: jsonData!)
        
        XCTAssertEqual(symbol.minimum, .integer(3))
        XCTAssertEqual(symbol.maximum, .float(3.5))
        XCTAssertEqual(symbol.defaultValue, .string("str"))
        
        let allowedValues = try XCTUnwrap(symbol.allowedValues)
        XCTAssertEqual(allowedValues.count, 3)
        XCTAssertEqual(allowedValues[0], .string("a"))
        XCTAssertEqual(allowedValues[1], .integer(1))
        XCTAssertEqual(allowedValues[2], .null)
    }
}

