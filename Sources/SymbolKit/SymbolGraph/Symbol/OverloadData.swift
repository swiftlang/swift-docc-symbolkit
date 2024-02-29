/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2024 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol {
    /// A mixin to hold data about overloads of a symbol.
    ///
    /// This mixin is generated in ``SymbolGraph/createOverloadGroupSymbols()`` to hold information
    /// about detected overloads of the symbol.
    public struct OverloadData: Mixin {
        public static var mixinKey: String = "overloadData"

        /// The precise identifier of the generated "overload group" symbol that references this overload.
        public let overloadGroupIdentifier: String

        /// The sorted index of this overload in its overload group.
        ///
        /// When creating overload groups, symbols are sorted by one of two metrics:
        ///
        /// 1. If all the symbols in an overload group have ``DeclarationFragments`` information,
        ///    the declarations are flattened into a string by their
        ///    ``DeclarationFragments/Fragment/spelling`` and sorted lexicographically.
        /// 2. Otherwise, the symbols are sorted by their precise identifiers.
        ///
        /// If this sort index is `0`, i.e. it came first in the sorting, then the overload group
        /// is created by cloning this symbol's data, and should reference the same declaration,
        /// documentation comment, etc.
        public let overloadGroupIndex: Int

        public init(overloadGroupIdentifier: String, overloadGroupIndex: Int) {
            self.overloadGroupIdentifier = overloadGroupIdentifier
            self.overloadGroupIndex = overloadGroupIndex
        }
    }

    /// Convenience accessor to fetch overload data for this symbol.
    public var overloadData: OverloadData? {
        mixins[SymbolGraph.Symbol.OverloadData.mixinKey] as? SymbolGraph.Symbol.OverloadData
    }
}
