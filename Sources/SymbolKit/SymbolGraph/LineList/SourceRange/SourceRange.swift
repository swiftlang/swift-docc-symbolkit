/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.LineList {
    /**
     Represents a selection in text: a start and end position, a half-open range.
     */
    public struct SourceRange: Equatable, Codable {
        /**
         The range's start position.
         */
        public var start: Position

        /**
         The range's end position.
         */
        public var end: Position
        
        /**
         Creates a new source range with the given start and end position.
         */
        public init(start: Position, end: Position) {
            self.start = start
            self.end = end
        }
    }
}
