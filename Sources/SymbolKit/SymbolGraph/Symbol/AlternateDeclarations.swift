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
    @available(*, deprecated, message: "This type is now unused; alternate declaration information is stored in AlternateSymbols instead.")
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

    /// A mixin to hold alternate symbol information for a symbol.
    ///
    /// This mixin is created while a symbol graph is decoded,
    /// to hold distinct information for symbols with the same precise identifier.
    public struct AlternateSymbols: Mixin, Codable {
        public static let mixinKey = "alternateSymbols"

        public struct AlternateSymbol: Codable {
            /// The doc comment for the alternate symbol.
            public let docComment: SymbolGraph.LineList?

            /// The mixins for the alternate symbol.
            public var mixins: [String: Mixin] = [:]

            public init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: SymbolGraph.Symbol.CodingKeys.self)
                self.docComment = try container.decodeIfPresent(SymbolGraph.LineList.self, forKey: .docComment)

                for key in container.allKeys {
                    guard let info = SymbolGraph.Symbol.CodingKeys.mixinCodingInfo[key.stringValue] ?? decoder.registeredSymbolMixins?[key.stringValue] else {
                        continue
                    }

                    mixins[key.stringValue] = try info.decode(container)
                }
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: SymbolGraph.Symbol.CodingKeys.self)

                try container.encodeIfPresent(docComment, forKey: .docComment)

                for (key, mixin) in mixins {
                    guard let info = SymbolGraph.Symbol.CodingKeys.mixinCodingInfo[key] ?? encoder.registeredSymbolMixins?[key] else {
                        continue
                    }

                    try info.encode(mixin, &container)
                }
            }

            public init(symbol: SymbolGraph.Symbol) {
                self.docComment = symbol.docComment
                self.mixins = symbol.mixins
            }

            /// Whether this alternate has no information and should be discarded.
            public var isEmpty: Bool {
                docComment == nil && mixins.isEmpty
            }

            /// Convenience accessor to fetch declaration fragments from the mixins dictionary.
            public var declarationFragments: DeclarationFragments? {
                self.mixins[DeclarationFragments.mixinKey] as? DeclarationFragments
            }

            /// Convenience accessor to fetch function signature information from the mixins dictionary.
            public var functionSignature: FunctionSignature? {
                self.mixins[FunctionSignature.mixinKey] as? FunctionSignature
            }
        }

        public init(alternateSymbols: [AlternateSymbol]) {
            self.alternateSymbols = alternateSymbols
        }

        /// The list of alternate symbol information.
        public var alternateSymbols: [AlternateSymbol]
    }

    /// Convenience accessor to fetch alternate declarations for this symbol.
    public var alternateDeclarations: [DeclarationFragments]? {
        alternateSymbols?.alternateSymbols.compactMap(\.declarationFragments)
    }

    /// Convenience accessor to fetch alternate symbol information.
    ///
    /// Returns `nil` if there were no alternate symbols found when decoding the symbol graph.
    public var alternateSymbols: AlternateSymbols? {
        mixins[AlternateSymbols.mixinKey] as? AlternateSymbols
    }

    /// Convenience accessor to fetch a specific mixin from this symbol's alternate symbols.
    ///
    /// Because the mixin key is inferred from the type parameter,
    /// the easiest way to call this method is by assigning it to a variable with an appropriate type:
    ///
    /// ```swift
    /// let alternateFunctionSignatures: [SymbolGraph.Symbol.FunctionSignature]? = symbol.alternateSymbolMixins()
    /// ```
    ///
    /// If there are multiple alternate symbols and only some of them have the requested mixin,
    /// any missing data is removed from the resulting array via a `compactMap`.
    public func alternateSymbolMixins<M: Mixin>(mixinKey: String = M.mixinKey) -> [M]? {
        alternateSymbols?.alternateSymbols.compactMap({ $0.mixins[mixinKey] as? M })
    }

    internal mutating func addAlternateDeclaration(from symbol: SymbolGraph.Symbol) {
        let alternate = AlternateSymbols.AlternateSymbol(symbol: symbol)
        guard !alternate.isEmpty else { return }

        if var alternateSymbols = mixins[AlternateSymbols.mixinKey] as? AlternateSymbols {
            alternateSymbols.alternateSymbols.append(alternate)
            mixins[AlternateSymbols.mixinKey] = alternateSymbols
        } else {
            mixins[AlternateSymbols.mixinKey] = AlternateSymbols(alternateSymbols: [alternate])
        }
    }
}
