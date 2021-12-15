/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

/**
 A symbol graph is a set of *nodes* that represent the symbols in a module and
 a set of directed *edges* that represent the relationships between symbols.
 */
public struct SymbolGraph: Codable {
    /// Metadata about the symbol graph.
    public var metadata: Metadata

    /// The module that this symbol graph represents.
    public var module: Module

    /// The symbols in a module: the nodes in a graph, mapped by precise identifier.
    public var symbols: [String: Symbol]

    /// The relationships between symbols: the edges in a graph.
    public var relationships: [Relationship]

    public init(metadata: Metadata, module: Module, symbols: [Symbol], relationships: [Relationship]) {
        self.metadata = metadata
        self.module = module
        self.symbols = [String: Symbol](symbols.lazy.map({ ($0.identifier.precise, $0) }), uniquingKeysWith: { old, new in
            SymbolGraph._symbolToKeepInCaseOfPreciseIdentifierConflict(old, new)
        })
        self.relationships = relationships
    }

    // MARK: - Codable

    public enum CodingKeys: String, CodingKey {
        case metadata
        case module
        case symbols
        case relationships
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let metadata = try container.decode(Metadata.self, forKey: .metadata)
        let module = try container.decode(Module.self, forKey: .module)
        let symbols = try container.decode([Symbol].self, forKey: .symbols)
        let relationships = try container.decode([Relationship].self, forKey: .relationships)
        self.init(metadata: metadata, module: module, symbols: symbols, relationships: relationships)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(module, forKey: .module)
        try container.encode(Array(symbols.values), forKey: .symbols)
        try container.encode(relationships, forKey: .relationships)
    }

    public static func _symbolToKeepInCaseOfPreciseIdentifierConflict(_ lhs: Symbol, _ rhs: Symbol) -> Symbol {
        if lhs.declarationContainsAsyncKeyword() {
            return rhs
        } else if rhs.declarationContainsAsyncKeyword() {
            return lhs
        } else {
            // It's not expected to ever end up here, but if we do, we return the symbol with the longer name
            // to have consistent results.
            return lhs.names.title.count < rhs.names.title.count ? rhs : lhs
        }
    }
}

extension SymbolGraph.Symbol {
    fileprivate func declarationContainsAsyncKeyword() -> Bool {
        return (mixins[DeclarationFragments.mixinKey] as? DeclarationFragments)?.declarationFragments.contains(where: { fragment in
            fragment.kind == .keyword && fragment.spelling == "async"
        }) == true
    }
}
