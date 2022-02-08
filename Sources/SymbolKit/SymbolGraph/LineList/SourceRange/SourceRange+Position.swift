/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.LineList.SourceRange {
    /**
     Represents a cursor position in text.
     */
    public struct Position: Equatable, Codable {
        /**
         The zero-based line number of a document.
         */
        public var line: Int

        /**
         The zero-based *byte offset* into a line.
         */
        public var character: Int
        
        /**
         Creates a new cursor position with the given line number and character offset.
         */
        public init(line: Int, character: Int) {
            self.line = line
            self.character = character
        }
    }
}
