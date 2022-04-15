/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

/// A combined ``SymbolGraph`` from multiple languages' views of the same module.
public class UnifiedSymbolGraph {

    /// The module that these combined symbol graphs represent.
    public var moduleName: String

    /// The decoded metadata about the module being represented, indexed by the file path of the symbol graph it was decoded from.
    ///
    /// Some module symbol graphs contain different metadata (e.g. platform it was rendered for, "bystander" modules, etc), and this allows users of unified graph data to load individual graphs' module data.
    public var moduleData: [URL: SymbolGraph.Module]

    /// Metadata about the individual symbol graphs that were combined together, indexed by the file path of each input symbol graph.
    public var metadata: [URL: SymbolGraph.Metadata]

    /// The symbols in the module, indexed by precise identifier.
    public var symbols: [String: UnifiedSymbolGraph.Symbol]

    /// The relationships between symbols.
    public var relationships: [SymbolGraph.Relationship]

    public init?(fromSingleGraph graph: SymbolGraph, at url: URL) {
        let (_, isMainGraph) = GraphCollector.moduleNameFor(graph, at: url)

        self.moduleName = graph.module.name
        self.moduleData = [url: graph.module]
        self.metadata = [url: graph.metadata]
        self.symbols = graph.symbols.mapValues { UnifiedSymbolGraph.Symbol(fromSingleSymbol: $0, module: graph.module, isMainGraph: isMainGraph) }
        self.relationships = graph.relationships
    }
}

extension UnifiedSymbolGraph {
    /// Merge the given list of ``SymbolGraph/Relationship``s with the list in this graph.
    ///
    /// This function will deduplicate relationships based on their source, target, and kind. If it sees a duplicate, it will keep the first one it sees.
    func mergeRelationships(with otherRelations: [SymbolGraph.Relationship]) {
        struct RelationKey: Hashable {
            let source: String
            let target: String
            let kind: SymbolGraph.Relationship.Kind

            init(fromRelation relationship: SymbolGraph.Relationship) {
                self.source = relationship.source
                self.target = relationship.target
                self.kind = relationship.kind
            }

            static func makePair(fromRelation relationship: SymbolGraph.Relationship) -> (RelationKey, SymbolGraph.Relationship) {
                return (RelationKey(fromRelation: relationship), relationship)
            }
        }

        // first add the new relations to this one
        self.relationships.append(contentsOf: otherRelations)

        // deduplicate the combined relationships array by source/target/kind
        // FIXME: Actually merge relationships if they have different mixins (rdar://84267943)
        let map = [:].merging(self.relationships.map({ RelationKey.makePair(fromRelation: $0) }), uniquingKeysWith: { r1, r2 in r1 })

        self.relationships = Array(map.values)
    }

    /// Merge the given symbol graph with this one.
    public func mergeGraph(graph: SymbolGraph, at url: URL) {
        let (_, isMainGraph) = GraphCollector.moduleNameFor(graph, at: url)

        self.metadata[url] = graph.metadata
        self.moduleData[url] = graph.module

        self.mergeRelationships(with: graph.relationships)

        for (key: precise, value: sym) in graph.symbols {
            if let existingSymbol = self.symbols[precise] {
                existingSymbol.mergeSymbol(symbol: sym, module: graph.module, isMainGraph: isMainGraph)
            } else {
                self.symbols[precise] = Symbol(fromSingleSymbol: sym, module: graph.module, isMainGraph: isMainGraph)
            }
        }
    }
}

extension UnifiedSymbolGraph {
    /// A combination of interface language and list of platforms that allows a symbol to be distinguished from another when unifying symbol graphs.
    public struct Selector: Equatable, Hashable, Encodable {
        /// The interface language used for the symbol.
        public let interfaceLanguage: String

        /// The platform that the symbol was built for.
        ///
        /// If the symbol graph that the symbol was sourced from does not contain a `module.platform.operatingSystem`, this will be `nil`.
        public let platform: String?

        public init(interfaceLanguage: String, platform: String?) {
            self.interfaceLanguage = interfaceLanguage
            self.platform = platform
        }

        /// Creates a ``UnifiedSymbolGraph/Selector`` for the given symbol graph's language and platform.
        ///
        /// If `graph` has no symbols, this will return `nil`.
        public init?(forSymbolGraph graph: SymbolGraph) {
            guard let lang = graph.symbols.first?.value.identifier.interfaceLanguage else { return nil }

            self.interfaceLanguage = lang
            self.platform = graph.module.platform.name
        }
    }
}
