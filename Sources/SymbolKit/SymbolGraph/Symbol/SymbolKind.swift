/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol {
    /// A description of a symbol's kind, such as a structure or protocol.
    public struct Kind: Equatable, Codable {
        /// A unique identifier for this symbol's kind.
        public var identifier: KindIdentifier

        /// A display name for a kind of symbol.
        ///
        /// For example, a Swift class might use `"Class"`.
        /// This display name should not be abbreviated:
        /// for instance, use `"Structure"` instead of `"Struct"` if applicable.
        public var displayName: String

        /// Initializes a new ``SymbolGraph/Symbol/Kind-swift.struct`` with an already-parsed
        /// ``SymbolGraph/Symbol/KindIdentifier`` and display name.
        public init(parsedIdentifier: KindIdentifier, displayName: String) {
            identifier = parsedIdentifier
            self.displayName = displayName
        }

        /// Initializes a new ``SymbolGraph/Symbol/Kind-swift.struct`` by parsing a new
        /// ``SymbolGraph/Symbol/KindIdentifier`` from the given identifier string, and combining it
        /// with a display name.
        @available(*, deprecated, message: "Use init(rawIdentifier:displayName:) instead")
        public init(identifier: String, displayName: String) {
            self.init(rawIdentifier: identifier, displayName: displayName)
        }

        /// Initializes a new ``SymbolGraph/Symbol/Kind-swift.struct`` by parsing a new
        /// ``SymbolGraph/Symbol/KindIdentifier`` from the given identifier string, and combining it
        /// with a display name.
        public init(rawIdentifier: String, displayName: String) {
            identifier = KindIdentifier(identifier: rawIdentifier)
            self.displayName = displayName
        }
    }
}
