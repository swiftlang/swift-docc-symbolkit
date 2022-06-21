/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
@testable import SymbolKit

class SymbolTests: XCTestCase {
    
    func testIsDocCommentFromSameModuleAsSymbol() throws {
        // nil doc comment
        do {
            let jsonData = encodedSymbol(withDocComment: nil).data(using: .utf8)!
            let symbol = try JSONDecoder().decode(SymbolGraph.Symbol.self, from: jsonData)

            XCTAssertNil(symbol._isDocCommentFromSameModule)
            XCTAssertNil(symbol.isDocCommentFromSameModule(symbolModuleName: "Test"))
        }
        
        // without range information
        do {
            let jsonData = encodedSymbol(withDocComment:
                (lines: ["First line", "Second line"], rangeStart: nil, moduleName: nil, fileName: nil)
            ).data(using: .utf8)!
            let symbol = try JSONDecoder().decode(SymbolGraph.Symbol.self, from: jsonData)

            XCTAssertEqual(symbol._isDocCommentFromSameModule, false)
            XCTAssertEqual(symbol.isDocCommentFromSameModule(symbolModuleName: "Test"), false)
        }
        
        // with range information
        do {
            let jsonData = encodedSymbol(withDocComment:
                (lines: ["First line", "Second line"], rangeStart: (line: 2, character: 4), moduleName: nil, fileName: nil)
            ).data(using: .utf8)!
            let symbol = try JSONDecoder().decode(SymbolGraph.Symbol.self, from: jsonData)

            XCTAssertEqual(symbol._isDocCommentFromSameModule, true)
            XCTAssertEqual(symbol.isDocCommentFromSameModule(symbolModuleName: "Test"), true)
        }
        
        // empty doc comment
        do {
            let jsonData = encodedSymbol(withDocComment:
                (lines: [], rangeStart: (line: 2, character: 4), moduleName: nil, fileName: nil)
            ).data(using: .utf8)!
            let symbol = try JSONDecoder().decode(SymbolGraph.Symbol.self, from: jsonData)

            XCTAssertNil(symbol._isDocCommentFromSameModule)
            XCTAssertNil(symbol.isDocCommentFromSameModule(symbolModuleName: "Test"))
        }
    }
    
    func testDocCommentModuleInformation() throws {
        let jsonData = encodedSymbol(withDocComment:
            (lines: ["First line", "Second line"], rangeStart: nil, moduleName: "ModuleName", fileName: "file name")
        ).data(using: .utf8)!
        let symbol = try JSONDecoder().decode(SymbolGraph.Symbol.self, from: jsonData)

        XCTAssertEqual(symbol.docComment?.moduleName, "ModuleName")
        XCTAssertEqual(symbol.docComment?.url?.isFileURL, true)
        XCTAssertEqual(symbol.docComment?.url?.pathComponents.last, "file name")
        
        XCTAssertEqual(symbol.isDocCommentFromSameModule(symbolModuleName: "ModuleName"), true)
        XCTAssertEqual(symbol.isDocCommentFromSameModule(symbolModuleName: "Test"), false)
    }

    /// Check that a Location mixin without position information still decodes a symbol graph without throwing.
    func testMalformedLocationDoesNotThrow() throws {
        let inputGraph = """
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
    "precise" : "precise-identifier",
    "interfaceLanguage" : "swift"
  },
  "names" : {
    "title" : "something()"
  },
  "location" : {
    "uri" : "file:///path/to/someSource.swift"
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
      "spelling" : "() -> "
    },
    {
      "kind" : "keyword",
      "spelling" : "Any"
    }
  ]
}
""".data(using: .utf8)!

        let symbol = try JSONDecoder().decode(SymbolGraph.Symbol.self, from: inputGraph)
        XCTAssertNil(symbol.mixins[SymbolGraph.Symbol.Location.mixinKey])
    }
    
}

// MARK: Test Data

private func encodedSymbol(withDocComment: (lines: [String], rangeStart: (line: Int, character: Int)?, moduleName: String?, fileName: String?)?) -> String {
    let docCommentJSON: String
    if let withDocComment = withDocComment {
        let lineList = SymbolGraph.LineList(withDocComment.lines.enumerated().map { index, text in
            let range = withDocComment.rangeStart.map { line, character in
                SymbolGraph.LineList.SourceRange(
                    start: SymbolGraph.LineList.SourceRange.Position(line: line + index, character: character),
                    end:   SymbolGraph.LineList.SourceRange.Position(line: line + index, character: character + text.count)
                )
            }
            return SymbolGraph.LineList.Line(text: text, range: range)
        }, url: withDocComment.fileName.map({ URL(fileURLWithPath: $0) }), moduleName: withDocComment.moduleName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(lineList)
        docCommentJSON = String(data: data, encoding: .utf8)!
    } else {
        docCommentJSON = "null"
    }
    
    return """
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
    "precise" : "precise-identifier",
    "interfaceLanguage" : "swift"
  },
  "names" : {
    "title" : "something()"
  },
  "docComment" : \(docCommentJSON),
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
      "spelling" : "() -> "
    },
    {
      "kind" : "keyword",
      "spelling" : "Any"
    }
  ]
}
"""
}
