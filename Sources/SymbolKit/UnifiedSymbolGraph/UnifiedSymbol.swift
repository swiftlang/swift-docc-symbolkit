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
            self.mixins[selector] = symbol.mixins
        }
    }
}

extension UnifiedSymbolGraph.Symbol: Encodable {
    enum CodingKeys: String, CaseIterable, CodingKey {
        // Base
        case uniqueIdentifier
        case mainGraphSelectors
        case modules
        case kind
        case pathComponents
        case type
        case names
        case docComment
        case accessLevel
        case mixins
    }

    private struct EncodableModule: Encodable {
        var selector: UnifiedSymbolGraph.Selector
        var module: SymbolGraph.Module
    }

    private struct EncodableKind: Encodable {
        var selector: UnifiedSymbolGraph.Selector
        var kind: SymbolGraph.Symbol.Kind
    }

    private struct EncodablePathComponents: Encodable {
        var selector: UnifiedSymbolGraph.Selector
        var pathComponents: [String]
    }

    private struct EncodableNames: Encodable {
        var selector: UnifiedSymbolGraph.Selector
        var names: SymbolGraph.Symbol.Names
    }

    private struct EncodableDocComment: Encodable {
        var selector: UnifiedSymbolGraph.Selector
        var docComment: SymbolGraph.LineList
    }

    private struct EncodableAccessLevel: Encodable {
        var selector: UnifiedSymbolGraph.Selector
        var accessLevel: SymbolGraph.Symbol.AccessControl
    }

    private struct EncodableMixins: Encodable {
        var selector: UnifiedSymbolGraph.Selector
        var mixins: [String: Mixin]

        enum CodingKeys: CodingKey {
            case selector
            case mixinKey(SymbolGraph.Symbol.CodingKeys)

            init?(intValue: Int) { return nil }

            init?(stringValue: String) {
                if stringValue == "selector" {
                    self = .selector
                } else if let key = SymbolGraph.Symbol.CodingKeys(stringValue: stringValue) {
                    self = .mixinKey(key)
                } else {
                    return nil
                }
            }

            var stringValue: String {
                switch self {
                case .selector: return "selector"
                case .mixinKey(let key): return key.stringValue
                }
            }

            var intValue: Int? { return nil }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(selector, forKey: .selector)

            // This is copied from SymbolGraph.Symbol's encoding method
            for (key, mixin) in mixins {
                let mixKey = SymbolGraph.Symbol.CodingKeys(rawValue: key)!
                let key = CodingKeys.mixinKey(mixKey)
                switch mixKey {
                case .availability:
                    try container.encode(mixin as! SymbolGraph.Symbol.Availability, forKey: key)
                case .declarationFragments:
                    try container.encode(mixin as! SymbolGraph.Symbol.DeclarationFragments, forKey: key)
                case .isReadOnly:
                    try container.encode(mixin as! SymbolGraph.Symbol.Mutability, forKey: key)
                case .swiftExtension:
                    try container.encode(mixin as! SymbolGraph.Symbol.Swift.Extension, forKey: key)
                case .swiftGenerics:
                    try container.encode(mixin as! SymbolGraph.Symbol.Swift.Generics, forKey: key)
                case .functionSignature:
                    try container.encode(mixin as! SymbolGraph.Symbol.FunctionSignature, forKey: key)
                case .spi:
                    try container.encode(mixin as! SymbolGraph.Symbol.SPI, forKey: key)
                case .snippet:
                    try container.encode(mixin as! SymbolGraph.Symbol.Snippet, forKey: key)
                case .location:
                    try container.encode(mixin as! SymbolGraph.Symbol.Location, forKey: key)
                default:
                    fatalError("Unknown mixin key \(mixKey.rawValue)!")
                }
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Base

        try container.encode(uniqueIdentifier, forKey: .uniqueIdentifier)
        try container.encode(mainGraphSelectors, forKey: .mainGraphSelectors)
        try container.encodeIfPresent(type, forKey: .type)

        let encodedModules = modules.map({ EncodableModule(selector: $0.key, module: $0.value) })
        if !encodedModules.isEmpty {
            try container.encode(encodedModules, forKey: .modules)
        }

        let encodedKinds = kind.map({ EncodableKind(selector: $0.key, kind: $0.value) })
        if !encodedKinds.isEmpty {
            try container.encode(encodedKinds, forKey: .kind)
        }

        let encodedPathComponents = pathComponents.map({ EncodablePathComponents(selector: $0.key, pathComponents: $0.value) })
        if !encodedPathComponents.isEmpty {
            try container.encode(encodedPathComponents, forKey: .pathComponents)
        }

        let encodedNames = names.map({ EncodableNames(selector: $0.key, names: $0.value) })
        if !encodedNames.isEmpty {
            try container.encode(encodedNames, forKey: .names)
        }

        let encodedDocComments = docComment.map({ EncodableDocComment(selector: $0.key, docComment: $0.value) })
        if !encodedDocComments.isEmpty {
            try container.encode(encodedDocComments, forKey: .docComment)
        }

        let encodedAccessLevels = accessLevel.map({ EncodableAccessLevel(selector: $0.key, accessLevel: $0.value) })
        if !encodedAccessLevels.isEmpty {
            try container.encode(encodedAccessLevels, forKey: .accessLevel)
        }

        let encodedMixins = mixins.map({ EncodableMixins(selector: $0.key, mixins: $0.value) })
        if !encodedMixins.isEmpty {
            try container.encode(encodedMixins, forKey: .mixins)
        }
    }
}
