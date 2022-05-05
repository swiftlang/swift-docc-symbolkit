/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2022 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

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
