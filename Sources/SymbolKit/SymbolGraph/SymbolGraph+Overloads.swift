/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2024 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph {
    /// Create "overload group" symbols based on name and kind collisions.
    ///
    /// For this method, an "overload" is a symbol whose ``Symbol/pathComponents`` and
    /// ``Symbol/kind`` are the same as another symbol in the same symbol graph. Such symbols are
    /// usually found in languages that allow for function overloading based on parameter or return
    /// types.
    ///
    /// When this method is called, it first looks for any symbols with an overloadable symbol kind
    /// (see ``Symbol/KindIdentifier/isOverloadableKind``) which collide on both kind and path. It
    /// then sorts these colliding symbols in one of two ways:
    ///
    /// 1. If all the colliding symbols have ``Symbol/DeclarationFragments``, these declarations are
    ///    condensed into strings by their ``Symbol/DeclarationFragments/Fragment/spelling``, which
    ///    are then sorted.
    /// 2. Otherwise, the symbols are sorted by their unique identifier.
    ///
    /// The symbol that appears first in this sorting is then cloned to create an "overload group".
    /// This symbol will have a unique identifier based on the original symbol, but suffixed with
    /// ``Symbol/overloadGroupIdentifierSuffix``. New ``Relationship/Kind/overloadOf``
    /// relationships are created between the colliding symbols and the new overload group symbol.
    /// In addition, any existing relationships the original symbol had are also cloned for the
    /// overload group.
    public mutating func createOverloadGroupSymbols() {
        struct OverloadKey: Hashable {
            let path: [String]
            let kind: SymbolGraph.Symbol.KindIdentifier
        }

        let symbolsByPath = [OverloadKey: [SymbolGraph.Symbol]](
            grouping: symbols.values.filter(\.kind.identifier.isOverloadableKind),
            by: { .init(path: $0.pathComponents, kind: $0.kind.identifier) }
        )

        var newRelationships = [Relationship]()

        for overloadSymbols in symbolsByPath.values where overloadSymbols.count > 1 {
            let sortedOverloads: [Symbol]
            if overloadSymbols.allSatisfy({ $0.declarationFragments != nil }) {
                sortedOverloads = overloadSymbols.sorted(by: { $0.declarationFragments! < $1.declarationFragments! })
            } else {
                sortedOverloads = overloadSymbols.sorted(by: { $0.identifier.precise < $1.identifier.precise })
            }
            let firstOverload = sortedOverloads.first!

            let overloadGroupIdentifier = firstOverload.identifier.precise + Symbol.overloadGroupIdentifierSuffix
            var overloadGroupSymbol = firstOverload
            overloadGroupSymbol.identifier.precise = overloadGroupIdentifier
            overloadGroupSymbol.isVirtual = true

            if let simplifiedDeclaration = overloadGroupSymbol.overloadSubheadingFragments() {
                overloadGroupSymbol.names.navigator = simplifiedDeclaration
                overloadGroupSymbol.names.subHeading = simplifiedDeclaration
            }

            self.symbols[overloadGroupSymbol.identifier.precise] = overloadGroupSymbol

            // Clone the relationships from the first overload and add them to the overload group
            for relationship in self.relationships {
                if relationship.source == firstOverload.identifier.precise {
                    var newRelationship = relationship
                    newRelationship.source = overloadGroupIdentifier
                    newRelationships.append(newRelationship)
                } else if relationship.target == firstOverload.identifier.precise {
                    var newRelationship = relationship
                    newRelationship.target = overloadGroupIdentifier
                    newRelationships.append(newRelationship)
                }
            }

            for overloadIndex in sortedOverloads.indices {
                let overloadSymbol = sortedOverloads[overloadIndex]
                // Make new 'overloadOf' relationships between the overloaded symbols and the new overload group
                newRelationships.append(.init(
                    source: overloadSymbol.identifier.precise,
                    target: overloadGroupIdentifier,
                    kind: .overloadOf,
                    targetFallback: nil))

                // Add overload data to each symbol
                let overloadData = Symbol.OverloadData(
                    overloadGroupIdentifier: overloadGroupIdentifier,
                    overloadGroupIndex: overloadIndex)
                self.symbols[overloadSymbol.identifier.precise]?.mixins[Symbol.OverloadData.mixinKey] = overloadData
            }
        }

        if !newRelationships.isEmpty {
            self.relationships.append(contentsOf: newRelationships)
        }
    }
}

extension SymbolGraph.Symbol {
    /// A suffix added to the precise identifier string for overload group symbols created by
    /// ``SymbolGraph/createOverloadGroupSymbols()``.
    public static let overloadGroupIdentifierSuffix = "::OverloadGroup"

    /// Whether the precise identifier string for this symbol contains the suffix added by
    /// ``SymbolGraph/createOverloadGroupSymbols()``.
    public var isOverloadGroup: Bool {
        self.identifier.precise.hasSuffix(Self.overloadGroupIdentifierSuffix)
    }
}

fileprivate extension [SymbolGraph.Symbol.DeclarationFragments.Fragment] {
    static func < (lhs: Self, rhs: Self) -> Bool {
        let renderedLhs = lhs.map(\.spelling).joined()
        let renderedRhs = rhs.map(\.spelling).joined()

        return renderedLhs < renderedRhs
    }
}
