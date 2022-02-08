/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol {
    /**
     A mix-in that specifies whether a symbol is immutable in its host language.

     For example, a constant member `let x = 1` in a Swift structure
     would have `isReadOnly` set to `true`.
     */
    public struct Mutability: Mixin, Equatable, Codable {
        public static let mixinKey = "isReadOnly"

        /**
         Whether a symbol is *immutable* or "read-only".
         */
        public var isReadOnly: Bool
        
        /// Creates a mutability mix-in with the given Boolean value.
        public init(isReadOnly: Bool) {
            self.isReadOnly = isReadOnly
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            isReadOnly = try container.decode(Bool.self)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(isReadOnly)
        }
    }
}
