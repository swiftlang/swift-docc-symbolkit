/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2023 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol {
    /// A mixin to hold alternate declarations of a symbol.
    ///
    /// This mixin is created while a symbol graph is decoded, to hold ``DeclarationFragments-swift.struct``
    /// for symbols which share the same precise identifier.
    public struct AlternateDeclarations: Mixin, Codable {
        public static let mixinKey = "alternateDeclarations"

        /// Alternate declarations for this symbol.
        public var declarations: [DeclarationFragments]

        public init(declarations: [DeclarationFragments]) {
            self.declarations = declarations
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            declarations = try container.decode([DeclarationFragments].self)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(declarations)
        }
    }

    /// Convenience accessor to fetch alternate declarations for this symbol.
    public var alternateDeclarations: [DeclarationFragments]? {
        (mixins[AlternateDeclarations.mixinKey] as? AlternateDeclarations)?.declarations
    }

    internal mutating func addAlternateDeclaration(_ declaration: DeclarationFragments) {
        if var alternateDeclarations = mixins[AlternateDeclarations.mixinKey] as? AlternateDeclarations {
            alternateDeclarations.declarations.append(declaration)
            mixins[AlternateDeclarations.mixinKey] = alternateDeclarations
        } else {
            mixins[AlternateDeclarations.mixinKey] = AlternateDeclarations.init(declarations: [declaration])
        }
    }

    internal mutating func addAlternateDeclaration(from symbol: SymbolGraph.Symbol) {
        if let declaration = symbol.mixins[DeclarationFragments.mixinKey] as? DeclarationFragments {
            addAlternateDeclaration(declaration)
        }
    }
}
