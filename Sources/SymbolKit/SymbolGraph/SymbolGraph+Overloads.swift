/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2024 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph {
    public mutating func createOverloadGroupSymbols() {
        struct OverloadKey: Hashable {
            let path: [String]
            let kind: SymbolGraph.Symbol.KindIdentifier
        }

        var symbolsByPath = [OverloadKey: [SymbolGraph.Symbol]]()

        for symbol in self.symbols.values {
            if symbol.kind.identifier.isOverloadableKind {
                symbolsByPath[.init(path: symbol.pathComponents, kind: symbol.kind.identifier), default: []].append(symbol)
            }
        }

        var newRelationships = [Relationship]()

        for overloadSymbols in symbolsByPath.values where overloadSymbols.count > 1 {
            let firstOverload = overloadSymbols.first!

            let overloadGroupIdentifier = firstOverload.identifier.precise + Symbol.overloadGroupIdentifierSuffix
            var overloadGroupSymbol = firstOverload
            overloadGroupSymbol.identifier.precise = overloadGroupIdentifier
            overloadGroupSymbol.isVirtual = true

            let simplifiedDeclaration = overloadGroupSymbol.overloadSubheadingFragments()
            overloadGroupSymbol.names.navigator = simplifiedDeclaration
            overloadGroupSymbol.names.subHeading = simplifiedDeclaration

            self.symbols[overloadGroupSymbol.identifier.precise] = overloadGroupSymbol

            // Clone the relationships from the first overload and add them to the overload group
            for relationship in self.relationships where relationship.source == firstOverload.identifier.precise {
                var newRelationship = relationship
                newRelationship.source = overloadGroupIdentifier
                newRelationships.append(newRelationship)
            }
            for relationship in self.relationships where relationship.target == firstOverload.identifier.precise {
                var newRelationship = relationship
                newRelationship.target = overloadGroupIdentifier
                newRelationships.append(newRelationship)
            }

            // Make new 'overloadOf' relationships between the overloaded symbols and the new overload group
            for overloadSymbol in overloadSymbols {
                newRelationships.append(.init(
                    source: overloadSymbol.identifier.precise,
                    target: overloadGroupIdentifier,
                    kind: .overloadOf,
                    targetFallback: nil))
            }
        }

        if !newRelationships.isEmpty {
            self.relationships.append(contentsOf: newRelationships)
        }
    }
}

extension SymbolGraph.Symbol {
    public static let overloadGroupIdentifierSuffix = "::OverloadGroup"

    public var isOverloadGroup: Bool {
        self.identifier.precise.hasSuffix(Self.overloadGroupIdentifierSuffix)
    }
}
