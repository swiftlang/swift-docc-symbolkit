/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
@testable import SymbolKit

class SymbolGraphTests: XCTestCase {
    
    func testDecodingSymbolWithCompletionHandler() throws {
        let jsonData = encodedSymbolGraph(withCompletionHandlerVariant: true, withAsyncKeywordVariant: false).data(using: .utf8)!
        let symbolGraph = try JSONDecoder().decode(SymbolGraph.self, from: jsonData)

        XCTAssertEqual(symbolGraph.symbols.count, 1, "Only one of the symbols should be decoded")
        let symbol = try XCTUnwrap(symbolGraph.symbols.values.first)
        let declaration = try XCTUnwrap(symbol.mixins[SymbolGraph.Symbol.DeclarationFragments.mixinKey] as? SymbolGraph.Symbol.DeclarationFragments)

        XCTAssertFalse(declaration.declarationFragments.contains(where: { fragment in
            fragment.kind == .keyword && fragment.spelling == "async"
        }))

        XCTAssertTrue(declaration.declarationFragments.contains(where: { fragment in
            fragment.kind == .externalParameter && fragment.spelling == "completionHandler"
        }))
    }
    
    func testDecodingSymbolWithAsyncKeyword() throws {
        let jsonData = encodedSymbolGraph(withCompletionHandlerVariant: false, withAsyncKeywordVariant: true).data(using: .utf8)!
        let symbolGraph = try JSONDecoder().decode(SymbolGraph.self, from: jsonData)

        XCTAssertEqual(symbolGraph.symbols.count, 1, "Only one of the symbols should be decoded")
        let symbol = try XCTUnwrap(symbolGraph.symbols.values.first)
        let declaration = try XCTUnwrap(symbol.mixins[SymbolGraph.Symbol.DeclarationFragments.mixinKey] as? SymbolGraph.Symbol.DeclarationFragments)

        XCTAssertTrue(declaration.declarationFragments.contains(where: { fragment in
            fragment.kind == .keyword && fragment.spelling == "async"
        }))

        XCTAssertFalse(declaration.declarationFragments.contains(where: { fragment in
            fragment.kind == .externalParameter && fragment.spelling == "completionHandler"
        }))
    }
    
    func testDecodingDuplicateSymbolWithBothVariants() throws {
        let jsonData = encodedSymbolGraph(withCompletionHandlerVariant: true, withAsyncKeywordVariant: true).data(using: .utf8)!
        // This shouldn't fatalError
        let symbolGraph = try JSONDecoder().decode(SymbolGraph.self, from: jsonData)

        XCTAssertEqual(symbolGraph.symbols.count, 1, "Only one of the symbols should be decoded")
        let symbol = try XCTUnwrap(symbolGraph.symbols.values.first)
        let declaration = try XCTUnwrap(symbol.mixins[SymbolGraph.Symbol.DeclarationFragments.mixinKey] as? SymbolGraph.Symbol.DeclarationFragments)

        XCTAssertFalse(declaration.declarationFragments.contains(where: { fragment in
            fragment.kind == .keyword && fragment.spelling == "async"
        }))

        XCTAssertTrue(declaration.declarationFragments.contains(where: { fragment in
            fragment.kind == .externalParameter && fragment.spelling == "completionHandler"
        }))
    }
}

// MARK: Test Data

// This is a symbol with a completion handler closure argument
let symbolWithCompletionBlock = """
    {
      "accessLevel" : "public",
      "kind" : {
        "displayName" : "Instance Method",
        "identifier" : "swift.method"
      },
      "pathComponents" : [
        "ClassName",
        "something(completionHandler:)"
      ],
      "identifier" : {
        "precise" : "same-precise-identifier-for-both",
        "interfaceLanguage" : "swift"
      },
      "names" : {
        "title" : "something(completionHandler:)"
      },
      "declarationFragments" : [
        {
          "kind" : "keyword",
          "spelling" : "func"
        },
        {
          "kind" : "text",
          "spelling" : " "
        },
        {
          "kind" : "identifier",
          "spelling" : "something"
        },
        {
          "kind" : "text",
          "spelling" : "("
        },
        {
          "kind" : "externalParam",
          "spelling" : "completionHandler"
        },
        {
          "kind" : "text",
          "spelling" : ": ("
        },
        {
          "kind" : "keyword",
          "spelling" : "Any"
        },
        {
          "kind" : "text",
          "spelling" : ") -> "
        },
        {
          "kind" : "typeIdentifier",
          "preciseIdentifier" : "s:s4Voida",
          "spelling" : "Void"
        },
        {
          "kind" : "text",
          "spelling" : ")"
        }
      ]
    }
"""

// This is the async keyword variant of the same symbol
let symbolWithAsyncKeyword = """
    {
      "accessLevel" : "public",
      "kind" : {
        "displayName" : "Instance Method",
        "identifier" : "swift.method"
      },
      "pathComponents" : [
        "ClassName",
        "something()"
      ],
      "identifier" : {
        "precise" : "same-precise-identifier-for-both",
        "interfaceLanguage" : "swift"
      },
      "names" : {
        "title" : "something()"
      },
      "declarationFragments" : [
        {
          "kind" : "keyword",
          "spelling" : "func"
        },
        {
          "kind" : "text",
          "spelling" : " "
        },
        {
          "kind" : "identifier",
          "spelling" : "something"
        },
        {
          "kind" : "text",
          "spelling" : "()"
        },
        {
          "kind" : "keyword",
          "spelling" : "async"
        },
        {
          "kind" : "text",
          "spelling" : " -> "
        },
        {
          "kind" : "keyword",
          "spelling" : "Any"
        }
      ]
    }
"""

private func encodedSymbolGraph(withCompletionHandlerVariant: Bool, withAsyncKeywordVariant: Bool) -> String {
    return """
{
  "metadata" : {
    "generator" : "unit-test",
    "formatVersion" : {
      "major" : 1,
      "minor" : 0,
      "patch" : 0
    }
  },
  "relationships" : [

  ],
  "symbols" : [
    \(withCompletionHandlerVariant ? symbolWithCompletionBlock : "")\(withCompletionHandlerVariant && withAsyncKeywordVariant ? "," : "")
    \(withAsyncKeywordVariant ? symbolWithAsyncKeyword : "")
  ],
  "module" : {
    "name" : "ModuleName",
    "platform" : {

    }
  }
}
"""
}
