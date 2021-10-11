/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
@testable import SymbolKit

class LineListTranslationTests: XCTestCase {
    typealias LineList = SymbolGraph.LineList
    typealias Line = SymbolGraph.LineList.Line
    typealias SourceRange = SymbolGraph.LineList.SourceRange
    typealias SourcePosition = SymbolGraph.LineList.SourceRange.Position

    /// Test that mapping into the same space has no effect.
    func testSameSpace() {
        let fileLines = LineList([
            Line(text: "This is", range: SourceRange(start: SourcePosition(line: 0, character: 0), end: SourcePosition(line: 0, character: 7))),
            Line(text: "a doc comment.", range: SourceRange(start: SourcePosition(line: 1, character: 0), end: SourcePosition(line: 1, character: 14))),
        ])
        for line in 0..<2 {
            for character in 0..<8 {
                let position = SourcePosition(line: line, character: character)
                XCTAssertEqual(position, fileLines.translateToFileSpace(position))
            }
        }

        XCTAssertEqual(SourcePosition(line: 0, character: 0), fileLines.translateToFileSpace(SourcePosition(line: 0, character: 0)))
    }

    /// Test that mapping into a different space goes to the right line and character offset.
    func testDifferentSpace() {
        /**
         As if:

         ```swift
                v      v
            0123456789ABCDEFGHI
         20 /// This is
         21 /// a doc comment.
                ^             ^
         ```
         */
        let fileLines = LineList([
            Line(text: "This is", range: SourceRange(start: SourcePosition(line: 20, character: 4), end: SourcePosition(line: 20, character: 11))),
            Line(text: "a doc comment.", range: SourceRange(start: SourcePosition(line: 21, character: 4), end: SourcePosition(line: 21, character: 18))),
        ])

        XCTAssertEqual(SourcePosition(line: 20, character: 4), fileLines.translateToFileSpace(SourcePosition(line: 0, character: 0)))
        XCTAssertEqual(SourcePosition(line: 21, character: 4), fileLines.translateToFileSpace(SourcePosition(line: 1, character: 0)))
    }

    /// Test that not having source information returns `nil` when trying to map into the file's space.
    func testNoSourceInformation() {
        let fileLines = LineList([
            Line(text: "This is", range: nil),
            Line(text: "a doc comment.", range: nil),
        ])
        for line in 0..<2 {
            for character in 0..<8 {
                XCTAssertNil(fileLines.translateToFileSpace(SourcePosition(line: line, character: character)))
            }
        }
    }
}
