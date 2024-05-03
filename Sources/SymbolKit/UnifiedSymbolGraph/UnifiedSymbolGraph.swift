/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021-2024 Apple Inc. and the Swift project authors
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
    @available(*, deprecated, message: "Use unifiedRelationships and orphanRelationships instead")
    public var relationships: [SymbolGraph.Relationship] {
        var allRelations = mergeRelationships(Array(relationshipsByLanguage.values.joined()))
        allRelations.append(contentsOf: self.orphanRelationships)
        return allRelations
    }

    /// The relationships between symbols, separated by the language's view those relationships are
    /// relevant in.
    public var relationshipsByLanguage: [Selector: [SymbolGraph.Relationship]]

    /// A list of relationships between symbols, for which neither the source nor target were able
    /// to be matched with an appropriate symbol in the collected graphs.
    public var orphanRelationships: [SymbolGraph.Relationship]

    public init?(fromSingleGraph graph: SymbolGraph, at url: URL) {
        let (_, isMainGraph) = GraphCollector.moduleNameFor(graph, at: url)

        self.moduleName = graph.module.name
        self.moduleData = [url: graph.module]
        self.metadata = [url: graph.metadata]
        self.symbols = graph.symbols.mapValues { UnifiedSymbolGraph.Symbol(fromSingleSymbol: $0, module: graph.module, isMainGraph: isMainGraph) }
        self.relationshipsByLanguage = [:]
        self.orphanRelationships = []
        loadRelationships(fromGraph: graph)
    }
}

extension UnifiedSymbolGraph {
    func loadRelationships(fromGraph graph: SymbolGraph) {
        var newRelations: [Selector: [SymbolGraph.Relationship]] = [:]

        for rel in graph.relationships {
            // associate each relationship with a selector based on the symbol(s) it references
            let selectors: [Selector]
            if let sourceSym = graph.symbols[rel.source] {
                selectors = [Selector(interfaceLanguage: sourceSym.identifier.interfaceLanguage, platform: graph.module.platform.name)]
            } else if let targetSym = graph.symbols[rel.target] {
                selectors = [Selector(interfaceLanguage: targetSym.identifier.interfaceLanguage, platform: graph.module.platform.name)]
            } else if let unifiedSourceSym = self.symbols[rel.source] {
                selectors = unifiedSourceSym.mainGraphSelectors
            } else if let unifiedTargetSym = self.symbols[rel.target] {
                selectors = unifiedTargetSym.mainGraphSelectors
            } else {
                // If we can't find the appropriate selector(s) to use, consider the relationship an
                // orphan and save it for later.
                self.orphanRelationships.append(rel)
                continue
            }

            for selector in selectors {
                if !newRelations.keys.contains(selector) {
                    newRelations[selector] = []
                }

                newRelations[selector]!.append(rel)
            }
        }

        for (key: selector, value: relations) in newRelations {
            self.relationshipsByLanguage[selector] = mergeRelationships(self.relationshipsByLanguage[selector, default: []], relations)
        }
    }

    /// Merge the given lists of ``SymbolGraph/Relationship``s.
    ///
    /// This function will deduplicate relationships based on their source, target, and kind. If it sees a duplicate, it will keep the first one it sees.
    func mergeRelationships(_ relationsList: [SymbolGraph.Relationship]...)
    -> [SymbolGraph.Relationship] {
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

        let allRelations = relationsList.joined()

        // deduplicate the combined relationships array by source/target/kind
        // FIXME: Actually merge relationships if they have different mixins (rdar://84267943)
        let map = [:].merging(allRelations.map({ RelationKey.makePair(fromRelation: $0) }), uniquingKeysWith: { r1, r2 in r1 })

        return Array(map.values)
    }

    /// Scans over ``orphanRelationships`` and sorts any whose source/target symbols were loaded
    /// after the relationship was.
    ///
    /// Since relationships are added to ``relationshipsByLanguage`` based on what symbols are
    /// available when the relationship is being loaded, a relationship can be considered an
    /// "orphan" even when it's not, if the symbol graphs are loaded in a certain order. This
    /// method was added to ensure that these relationships can be properly assigned a language
    /// even if the symbol information isn't in the same symbol graph.
    internal func collectOrphans() {
        var newRelations: [Selector: [SymbolGraph.Relationship]] = [:]
        var remainingOrphans: [SymbolGraph.Relationship] = []
        for rel in self.orphanRelationships {
            let selectors: [Selector]
            if let unifiedSourceSym = self.symbols[rel.source] {
                selectors = unifiedSourceSym.mainGraphSelectors
            } else if let unifiedSourceSym = self.symbols[rel.target] {
                selectors = unifiedSourceSym.mainGraphSelectors
            } else {
                remainingOrphans.append(rel)
                continue
            }

            for selector in selectors {
                if !newRelations.keys.contains(selector) {
                    newRelations[selector] = []
                }

                newRelations[selector]!.append(rel)
            }
        }

        for (key: selector, value: relations) in newRelations {
            self.relationshipsByLanguage[selector] = mergeRelationships(self.relationshipsByLanguage[selector, default: []], relations)
        }

        self.orphanRelationships = remainingOrphans
    }

    /// If there were overload groups created by ``SymbolGraph/createOverloadGroupSymbols()``,
    /// recalculate their ``SymbolGraph/Symbol/OverloadData`` and store it in
    /// ``UnifiedSymbolGraph/Symbol/unifiedMixins``.
    internal func combineOverloadGroups() {
        // There are three main situations where a symbol's overload data would be different:
        //
        // 1. A symbol is not overloaded in one symbol graph, but is overloaded by a sibling symbol
        //    in another symbol graph.
        // 2. A group of overloads contains a different set of symbols between different symbol
        //    graphs, but the same symbol was chosen to be cloned as the overload group symbol.
        // 3. A group of overloads contains a different set of symbols between different symbol
        //    graphs, but different symbols were chosen to be cloned as their respective overload
        //    group symbols.
        //
        // In situation 1, the unified relationships match the most complete picture of all the
        // overloads (in that there is an overload group that exists and there are relationships
        // that point to it), but the symbol that is in both graphs only has an OverloadData mixin
        // connected to the selector for one symbol graph. Depending on how the mixins are loaded
        // later, this could lead to an inconsistent view where an `overloadOf` relationship exists,
        // but the client doesn't load the matching OverloadData mixin. In this case, we should
        // effectively promote the OverloadData to the whole-graph scope.
        //
        // In situation 2, we have symbols that look roughly like this:
        //
        // ┌───────────────────────────┐  ┌───────────────────────────┐
        // │ overloadA (1) ─┬─► groupA │  │ overloadA (1) ─┬─► groupA │
        // │ overloadB (2) ─┤          │  │ overloadC (2) ─┤          │
        // │ overloadC (3) ─┘          │  │ overloadD (3) ─┘          │
        // └───────────────────────────┘  └───────────────────────────┘
        //
        // The unified relationships are still consistent (there's one overload-group symbol and all
        // the overloaded symbols point to it), but `overloadC` has different OverloadData depending
        // on which selector you're using: In one graph it's at index 3, but in the other graph it's
        // at index 2. In this case we need to recalculate the overload indices based on an ordering
        // that takes all of the overloaded symbols into account.
        //
        // Finally, in situation 3 the relationship graph looks like this:
        //
        // ┌───────────────────────────────────────────┐
        // │                 overloadA (1) ─┬─► groupA │
        // │ groupB ◄─┬─ (1) overloadB (2) ─┘          │
        // │          └─ (2) overloadC                 │
        // └───────────────────────────────────────────┘
        //
        // In addition to overloadB having different indices per graph, the unified relationships
        // are also inconsistent: there are two overload groups that refer to different subsets of
        // symbols! In this case, we need to recalculate the overload indices like in situation 2
        // above, but we also need to determine which overload group to keep as the "canonical" one.
        // Since overload group symbols are by definition going to be generated by SymbolKit, when
        // they're introduced into a unified symbol graph we can remove any that don't describe a
        // "unified overload group" in this way, along with any relationships that point to them.
        //
        // In all three situations, we can generalize the solution with the following steps:
        //
        // 1. For each overload group, check the constituent symbols to see if they're part of
        //    another overload group. Collect the symbols and groups as you go.
        //    a. If you find other overload groups, recursively check for other overload groups
        //       until no new groups are found.
        // 2. Sort the collected symbols with the same comparator as
        //    `SymbolGraph.createOverloadGroupSymbols()`.
        // 3. Find the overload group symbol matching the first overload in the resulting order, and
        //    ensure that it contains `overloadOf` relationships to all the overloaded symbols.
        // 4. For each symbol, create a new OverloadData instance referencing the unified overload
        //    group and the computed index in the sort order. Save it in the symbol's `unifiedMixins`.
        // 5. If there were other overload group symbols, remove them from the symbol graph, along
        //    with any relationships that referenced them.

        /// A mapping of overload group symbols to their individual overloads.
        var overloadGroups: [String: Set<String>] = [:]
        /// A mapping of overloaded symbols to the overload groups they are part of.
        var overloadGroupsBySymbol: [String: Set<String>] = [:]
        /// A collection of all the overload groups that have been processed.
        var processedOverloadGroups: Set<String> = []

        for relationship in self.relationshipsByLanguage.flatMap(\.value)
            where relationship.kind == SymbolGraph.Relationship.Kind.overloadOf
        {
            overloadGroups[relationship.target, default: []].insert(relationship.source)
            overloadGroupsBySymbol[relationship.source, default: []].insert(relationship.target)
        }

        for overloadGroup in overloadGroups.keys {
            guard !processedOverloadGroups.contains(overloadGroup) else {
                // If this overload group was a sibling to another overload group, don't try to
                // process it again.
                continue
            }
            var siblingOverloadGroups: Set<String> = []
            var overloadedSymbols: Set<String> = []
            var pendingOverloadGroups: Set<String> = [overloadGroup]

            // 1. Collect all the overloaded symbols and all the overload groups they belong to.
            while !pendingOverloadGroups.isEmpty {
                for processingOverloadGroup in pendingOverloadGroups {
                    pendingOverloadGroups.remove(processingOverloadGroup)
                    siblingOverloadGroups.insert(processingOverloadGroup)

                    for overloadedSymbol in overloadGroups[processingOverloadGroup]! {
                        overloadedSymbols.insert(overloadedSymbol)
                        for otherOverloadGroup in overloadGroupsBySymbol[overloadedSymbol]! {
                            if !siblingOverloadGroups.contains(otherOverloadGroup),
                               !pendingOverloadGroups.contains(otherOverloadGroup)
                            {
                                pendingOverloadGroups.insert(otherOverloadGroup)
                            }
                        }
                    }
                }
            }

            guard !overloadedSymbols.isEmpty else { continue }

            // 2. Sort the overloaded symbols with the same comparator as `SymbolGraph.createOverloadGroupSymbols()`.
            var allSymbolsHaveDeclaration = true
            let sortedOverloads = overloadedSymbols.map({ identifier in
                let symbol = symbols[identifier]!
                if !symbol.mixins.values.contains(where: { $0.keys.contains(SymbolGraph.Symbol.DeclarationFragments.mixinKey) }) {
                    allSymbolsHaveDeclaration = false
                }
                return symbol
            }).sorted(by: Symbol.sortForOverloads(orderByDeclaration: allSymbolsHaveDeclaration))
            let firstOverload = sortedOverloads.first!
            let computedOverloadGroup = firstOverload.uniqueIdentifier + SymbolGraph.Symbol.overloadGroupIdentifierSuffix

            guard siblingOverloadGroups.contains(computedOverloadGroup) else {
                assertionFailure(
                """
                UnifiedSymbolGraph.combineOverloadGroups found a candidate overload group that didn't
                match any existing overload group from its constituent symbol graphs.

                The unified graph found that \(firstOverload.uniqueIdentifier) should be the default
                overload, but the constituent symbol graphs contained the following overload groups:
                \(siblingOverloadGroups)
                """
                )
                continue
            }

            for overloadIndex in sortedOverloads.indices {
                let overloadedSymbol = sortedOverloads[overloadIndex]

                // 3. Ensure that all the overloaded symbols have `overloadOf` relationships pointing
                // to the computed overload group.
                for selector in overloadedSymbol.mainGraphSelectors {
                    let newRelationship = SymbolGraph.Relationship(
                        source: overloadedSymbol.uniqueIdentifier,
                        target: computedOverloadGroup,
                        kind: .overloadOf,
                        targetFallback: nil)
                    if relationshipsByLanguage[selector]?.contains(where: { otherRelationship in
                        otherRelationship.source == newRelationship.source &&
                        otherRelationship.target == newRelationship.target &&
                        otherRelationship.kind == newRelationship.kind
                    }) != true {
                        relationshipsByLanguage[selector, default: []].append(newRelationship)
                    }
                }

                // 4. Create a new OverloadData instance and save it to the overloaded symbol.
                let overloadData = SymbolGraph.Symbol.OverloadData(
                    overloadGroupIdentifier: computedOverloadGroup,
                    overloadGroupIndex: overloadIndex)
                overloadedSymbol.unifiedMixins[SymbolGraph.Symbol.OverloadData.mixinKey] = overloadData
            }

            // 5. If there were any other overload groups that pointed to the same symbols, remove
            // them from the unified graph, along with any relationships that included them.
            processedOverloadGroups.formUnion(siblingOverloadGroups)
            for siblingOverloadGroup in siblingOverloadGroups where siblingOverloadGroup != computedOverloadGroup {
                symbols.removeValue(forKey: siblingOverloadGroup)
            }
            siblingOverloadGroups.remove(computedOverloadGroup)
            for selector in relationshipsByLanguage.keys {
                relationshipsByLanguage[selector]?.removeAll(where: { relationship in
                    siblingOverloadGroups.contains(relationship.source) ||
                    siblingOverloadGroups.contains(relationship.target)
                })
            }
        }
    }

    /// Merge the given symbol graph with this one.
    public func mergeGraph(graph: SymbolGraph, at url: URL) {
        let (_, isMainGraph) = GraphCollector.moduleNameFor(graph, at: url)

        self.metadata[url] = graph.metadata
        self.moduleData[url] = graph.module

        for (key: precise, value: sym) in graph.symbols {
            if let existingSymbol = self.symbols[precise] {
                existingSymbol.mergeSymbol(symbol: sym, module: graph.module, isMainGraph: isMainGraph)
            } else {
                self.symbols[precise] = Symbol(fromSingleSymbol: sym, module: graph.module, isMainGraph: isMainGraph)
            }
        }

        loadRelationships(fromGraph: graph)
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
