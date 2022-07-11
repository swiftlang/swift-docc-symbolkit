/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension UnifiedSymbolGraph {
    /// A combined symbol from multiple languages' views of the same symbol.
    public class Symbol {
        /// The unique identifier for the symbol.
        ///
        /// This is intended to be unique across languages, and is used to select symbol information to combine.
        public var uniqueIdentifier: String

        /// The selector that originated from the "main module" symbol graph, as opposed to an extension.
        public var mainGraphSelectors: [Selector]

        public var modules: [Selector: SymbolGraph.Module]

        /// The kind of symbol.
        public var kind: [Selector: SymbolGraph.Symbol.Kind]

        /// A short convenience path that uniquely identifies a symbol when there are no ambiguities using only URL-compatible characters.
        ///
        /// See ``SymbolGraph/Symbol/pathComponents`` for more information. This is separated per-language to allow for language-specific symbol/module/namespace names to reference the symbol.
        public var pathComponents: [Selector: [String]]

        /// If the static type of a symbol is known, the precise identifier of
        /// the symbol that declares the type.
        public var type: String?

        /// The context-specific names of a symbol.
        public var names: [Selector: SymbolGraph.Symbol.Names]

        /// The in-source documentation comment attached to a symbol.
        public var docComment: [Selector: SymbolGraph.LineList]

        /// The access level of the symbol.
        public var accessLevel: [Selector: SymbolGraph.Symbol.AccessControl]

        /// If true, the symbol was created implicitly and not from source.
        public var isVirtual: [Selector: Bool]

        /// Information about a symbol that is not necessarily common to all symbols.
        public var mixins: [Selector: [String: Mixin]]

        /// Initialize a combined symbol view from a single symbol.
        public init(fromSingleSymbol sym: SymbolGraph.Symbol, module: SymbolGraph.Module, isMainGraph: Bool) {
            let lang = sym.identifier.interfaceLanguage
            let selector = Selector(interfaceLanguage: lang, platform: module.platform.name)

            self.uniqueIdentifier = sym.identifier.precise
            self.mainGraphSelectors = []
            if isMainGraph {
                self.mainGraphSelectors.append(selector)
            }
            self.modules = [selector: module]
            self.kind = [selector: sym.kind]
            self.pathComponents = [selector: sym.pathComponents]
            self.type = sym.type
            self.names = [selector: sym.names]
            self.docComment = [:]
            if let docComment = sym.docComment {
                self.docComment[selector] = docComment
            }
            self.accessLevel = [selector: sym.accessLevel]
            self.isVirtual = [selector: sym.isVirtual]
            self.mixins = [selector: sym.mixins]
        }

        /// Add the given symbol to this unified view.
        ///
        /// - Warning: `symbol` must refer to the same symbol as this view (i.e. their precise identifiers must be the same).
        ///
        /// - Parameters:
        ///   - symbol: The symbol to add to this view.
        public func mergeSymbol(symbol: SymbolGraph.Symbol, module: SymbolGraph.Module, isMainGraph: Bool) {
            precondition(self.uniqueIdentifier == symbol.identifier.precise)

            let selector = Selector(
                interfaceLanguage: symbol.identifier.interfaceLanguage,
                platform: module.platform.name)

            if isMainGraph && !self.mainGraphSelectors.contains(selector) {
                self.mainGraphSelectors.append(selector)
            }

            // Add a new variant to the fields that track it
            self.modules[selector] = module
            self.kind[selector] = symbol.kind
            self.pathComponents[selector] = symbol.pathComponents
            self.names[selector] = symbol.names
            self.docComment[selector] = symbol.docComment
            self.accessLevel[selector] = symbol.accessLevel
            self.isVirtual[selector] = symbol.isVirtual
            self.mixins[selector] = symbol.mixins
        }
    }
}
