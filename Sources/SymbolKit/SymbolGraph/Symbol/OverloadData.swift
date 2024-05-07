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

extension UnifiedSymbolGraph.Symbol {
    /// Convenience accessor to fetch unified overload data for this symbol.
    public var unifiedOverloadData: SymbolGraph.Symbol.OverloadData? {
        unifiedMixins[SymbolGraph.Symbol.OverloadData.mixinKey] as? SymbolGraph.Symbol.OverloadData
    }
}
