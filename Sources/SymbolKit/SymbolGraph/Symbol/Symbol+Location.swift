/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol {
    /**
     The place where a symbol was originaly declared in a source file.

     This information may not always be available for many reasons, such
     as compiler infrastructure limitations, or filesystem security concerns.
     */
    public struct Location: Mixin {
        public static let mixinKey = "location"

        /**
         The URI of the file in which the symbol was originally declared,
         suitable for display in a user interface.
         */
        public var uri: String

        /**
         The range of the declaration in the file, not including its documentation comment.
         */
        public var position: SymbolGraph.LineList.SourceRange.Position
    }
}
