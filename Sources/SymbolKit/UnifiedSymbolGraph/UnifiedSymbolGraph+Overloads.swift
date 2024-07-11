/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2024 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

/// A graph holding information about overloaded symbols in a ``UnifiedSymbolGraph``.
class Overloads {
    var overloadGroups: [OverloadKey: [UnifiedSymbolGraph.Symbol]] = [:]

    func calculateOverloadGroups(forSymbol symbol: UnifiedSymbolGraph.Symbol) {
        let interfaceLanguages = Set(symbol.allSelectors.map(\.interfaceLanguage))
        let keys = interfaceLanguages.compactMap({ OverloadKey(fromUnifiedSymbol: symbol, interfaceLanguage: $0) })

        for key in keys where key.kind.isOverloadableKind {
            overloadGroups[key, default: []].append(symbol)
        }
    }
}

extension Overloads {
    /// A key structure used to group overloaded symbols together.
    struct OverloadKey: Hashable {
        let interfaceLanguage: String
        let path: [String]
        let kind: SymbolGraph.Symbol.KindIdentifier

        public init?(fromUnifiedSymbol symbol: UnifiedSymbolGraph.Symbol, interfaceLanguage: String) {
            let kinds = Set(symbol.kind.filter({ $0.key.interfaceLanguage == interfaceLanguage }).values.map(\.identifier))
            let paths = Set(symbol.pathComponents.filter({ $0.key.interfaceLanguage == interfaceLanguage }).values)

            guard kinds.count == 1, paths.count == 1 else {
                // If a symbol has different paths or different symbol kinds in its constituent
                // symbol graphs, then it shouldn't participate in overloads.
                return nil
            }

            self.interfaceLanguage = interfaceLanguage
            self.kind = kinds.first!
            self.path = paths.first!
        }
    }
}

extension UnifiedSymbolGraph {
    func createOverloadGroupSymbols() {
        // If the individual symbol graphs had overload groups created, clear them from the symbols
        // and relationships listings before continuing.
        if !self.overloadGroupsFromOriginalGraphs.isEmpty {
            self.symbols = self.symbols.filter({ !self.overloadGroupsFromOriginalGraphs.contains($0.key) })
            self.relationshipsByLanguage = self.relationshipsByLanguage.mapValues({ relationships in
                relationships.filter({ relationship in
                    !self.overloadGroupsFromOriginalGraphs.contains(relationship.source) &&
                    !self.overloadGroupsFromOriginalGraphs.contains(relationship.target) &&
                    relationship.kind != .overloadOf
                })
            })
        }

        // Calculate all the overload keys for the remaining symbols.
        let overloadData = Overloads()
        for symbol in symbols.values {
            overloadData.calculateOverloadGroups(forSymbol: symbol)
        }

        for (overloadKey, var overloadedSymbols) in overloadData.overloadGroups where overloadedSymbols.count > 1 {
            overloadedSymbols.sort(by: Symbol.sortForOverloads(
                orderByDeclaration: overloadedSymbols.allSatisfy({
                    !$0.declarationFragments.isEmpty
                })))

            let firstOverload = overloadedSymbols.first!
            let overloadGroupIdentifier = firstOverload.uniqueIdentifier + SymbolGraph.Symbol.overloadGroupIdentifierSuffix
            let overloadGroupSymbol = Symbol(
                cloning: firstOverload,
                uniqueIdentifier: overloadGroupIdentifier,
                withSelectorsFromSourceLanguage: overloadKey.interfaceLanguage)

            self.symbols[overloadGroupIdentifier] = overloadGroupSymbol
            self.overloadGroupSymbols.insert(overloadGroupIdentifier)

            var overloadSelectors: Set<Selector> = []
            for overloadedSymbol in overloadedSymbols {
                overloadSelectors.formUnion(overloadedSymbol.selectors(forLanguage: overloadKey.interfaceLanguage))
            }

            // Clone the relationships from the first overload and add them to the overload group
            for selector in overloadSelectors {
                var newRelationships = (relationshipsByLanguage[selector] ?? []).filter({
                    $0.target == firstOverload.uniqueIdentifier || $0.source == firstOverload.uniqueIdentifier
                }).map({ relationship in
                    var relationship = relationship
                    if relationship.source == firstOverload.uniqueIdentifier {
                        relationship.source = overloadGroupIdentifier
                    } else if relationship.target == firstOverload.uniqueIdentifier {
                        relationship.target = overloadGroupIdentifier
                    }
                    return relationship
                })

                // Add in new relationships from the overloaded symbols to the overload group
                for symbol in overloadedSymbols where symbol.allSelectors.contains(selector) {
                    newRelationships.append(.init(
                        source: symbol.uniqueIdentifier,
                        target: overloadGroupIdentifier,
                        kind: .overloadOf,
                        targetFallback: nil))
                }

                if !newRelationships.isEmpty {
                    relationshipsByLanguage[selector, default: []].append(contentsOf: newRelationships)
                }
            }

            for overloadIndex in overloadedSymbols.indices {
                let overloadedSymbol = overloadedSymbols[overloadIndex]

                overloadedSymbol.unifiedMixins[SymbolGraph.Symbol.OverloadData.mixinKey] =
                    SymbolGraph.Symbol.OverloadData(
                        overloadGroupIdentifier: overloadGroupIdentifier,
                        overloadGroupIndex: overloadIndex)
            }
        }
    }
}

extension UnifiedSymbolGraph.Symbol {
    convenience init(
        cloning original: UnifiedSymbolGraph.Symbol,
        uniqueIdentifier: String,
        withSelectorsFromSourceLanguage sourceLanguage: String? = nil
    ) {
        self.init(uniqueIdentifier: uniqueIdentifier)

        let selectors: [UnifiedSymbolGraph.Selector]
        if let sourceLanguage = sourceLanguage {
            selectors = original.selectors(forLanguage: sourceLanguage)
        } else {
            selectors = original.allSelectors
        }

        self.mainGraphSelectors = original.mainGraphSelectors.filter({ selectors.contains($0) })

        self.modules = original.modules.filter({ selectors.contains($0.key) })
        self.kind = original.kind.filter({ selectors.contains($0.key) })
        self.pathComponents = original.pathComponents.filter({ selectors.contains($0.key) })
        self.type = original.type
        self.names = original.names.filter({ selectors.contains($0.key) })
        self.docComment = original.docComment.filter({ selectors.contains($0.key) })
        self.accessLevel = original.accessLevel.filter({ selectors.contains($0.key) })
        self.isVirtual = original.isVirtual.filter({ selectors.contains($0.key) })
        self.mixins = original.mixins.filter({ selectors.contains($0.key) })
    }

    func selectors(forLanguage language: String) -> [UnifiedSymbolGraph.Selector] {
        self.allSelectors.filter({ $0.interfaceLanguage == language })
    }
}
