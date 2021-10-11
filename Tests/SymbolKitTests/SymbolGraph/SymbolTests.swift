/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
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

            XCTAssertNil(symbol.isDocCommentFromSameModule)
        }
        
        // without range information
        do {
            let jsonData = encodedSymbol(withDocComment:
                (lines: ["First line", "Second line"], rangeStart: nil)
            ).data(using: .utf8)!
            let symbol = try JSONDecoder().decode(SymbolGraph.Symbol.self, from: jsonData)

            XCTAssertEqual(symbol.isDocCommentFromSameModule, false)
        }
        
        // with range information
        do {
            let jsonData = encodedSymbol(withDocComment:
                (lines: ["First line", "Second line"], rangeStart: (line: 2, character: 4))
            ).data(using: .utf8)!
            let symbol = try JSONDecoder().decode(SymbolGraph.Symbol.self, from: jsonData)

            XCTAssertEqual(symbol.isDocCommentFromSameModule, true)
        }
        
        // empty doc comment
        do {
            let jsonData = encodedSymbol(withDocComment:
                (lines: [], rangeStart: (line: 2, character: 4))
            ).data(using: .utf8)!
            let symbol = try JSONDecoder().decode(SymbolGraph.Symbol.self, from: jsonData)

            XCTAssertNil(symbol.isDocCommentFromSameModule)
        }
    }
    
}

// MARK: Test Data

private func encodedSymbol(withDocComment: (lines: [String], rangeStart: (line: Int, character: Int)?)?) -> String {
    
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
        })
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
