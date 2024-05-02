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

        let defaultImplementationSymbols = relationships.filter({ $0.kind == .defaultImplementationOf }).map(\.source)

        let symbolsByPath = [OverloadKey: [SymbolGraph.Symbol]](
            grouping: symbols.values
                .filter({ !defaultImplementationSymbols.contains($0.identifier.precise) })
                .filter(\.kind.identifier.isOverloadableKind),
            by: { .init(path: $0.pathComponents, kind: $0.kind.identifier) }
        )

        var newRelationships = [Relationship]()

        for overloadSymbols in symbolsByPath.values where overloadSymbols.count > 1 {
            let sortedOverloads: [Symbol] = overloadSymbols.sorted(
                by: Symbol.sortForOverloads(
                    orderByDeclaration: overloadSymbols.allSatisfy({ $0.declarationFragments != nil })))
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

/// Compares two symbols for ordering within an overload group.
///
/// This is the underlying implementation for both versions of `sortForOverloads(orderByDeclaration:)`.
/// This method will use the given accessors to compare two symbols (single or unified) in the
/// following manner:
///
/// - If we aren't meant to compare by declaration (`orderByDeclaration` is false), perform a
///   lexicographical comparison between the symbols' identifiers, as fetched by `getIdentifier`.
/// - If we are meant to compare by declaration (`orderByDeclaration` is true):
///   - Fetch both symbols' declarations with `getDeclaration`.
///   - If the declarations are equal, fall back to comparing by identifier.
///   - Otherwise, perform a lexicographical comparison on the declarations.
///
/// - Parameters:
///   - lhs: The first symbol to compare.
///   - rhs: The second symbol to compare.
///   - orderByDeclaration: Whether to sort by declaration fragments or by precise identifier.
///   - getDeclaration: A function to render a declaration for a symbol.
///   - getIdentifier: A function to get a symbol's precise identifier.
/// - Returns: A comparator suitable for sorting an array of symbols for an overload group.
fileprivate func isDeclarationBefore<S>(
    _ lhs: S, _ rhs: S, orderByDeclaration: Bool,
    getDeclaration: ((S) -> String),
    getIdentifier: ((S) -> String)
) -> Bool {
    if orderByDeclaration {
        let lhsDeclaration = getDeclaration(lhs)
        let rhsDeclaration = getDeclaration(rhs)
        if lhsDeclaration == rhsDeclaration {
            return getIdentifier(lhs) < getIdentifier(rhs)
        } else {
            return lhsDeclaration < rhsDeclaration
        }
    } else {
        return getIdentifier(lhs) < getIdentifier(rhs)
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

    /// Returns a sort comparator suitable for sorting symbols within an overload group.
    ///
    /// The sort order for overloads follows the following algorithm:
    /// - If `orderByDeclaration` is false, symbols are sorted by their precise identifier.
    /// - If `orderByDeclaration` is true, symbols are sorted by their ``DeclarationFragments``
    ///   mixin, falling back to their precise identifier if their declarations are equal.
    internal static func sortForOverloads(orderByDeclaration: Bool) -> ((Self, Self) -> Bool) {
        return { isDeclarationBefore(
            $0, $1, orderByDeclaration: orderByDeclaration,
            getDeclaration: { $0.declarationFragments!.rendered },
            getIdentifier: { $0.identifier.precise }
        )}
    }
}

extension UnifiedSymbolGraph.Symbol {
    /// If a symbol has declaration fragments mixins, returns the one that lexicographically sorts first.
    var firstAvailableDeclaration: String? {
        let uniqueDeclarations = Set(declarationFragments.values.map(\.rendered))
        return uniqueDeclarations.sorted().first
    }

    /// Returns a sort comparator suitable for sorting symbols within an overload group.
    ///
    /// The sort order for overloads follows the following algorithm:
    /// - If `orderByDeclaration` is false, symbols are sorted by their unique identifier.
    /// - If `orderByDeclaration` is true, symbols are sorted by their declaration (as returned by
    ///   ``firstAvailableDeclaration``), falling back to their unique identifier if their
    ///   declarations are equal.
    internal static func sortForOverloads(orderByDeclaration: Bool) -> ((UnifiedSymbolGraph.Symbol, UnifiedSymbolGraph.Symbol) -> Bool) {
        return { isDeclarationBefore(
            $0, $1, orderByDeclaration: orderByDeclaration,
            getDeclaration: { $0.firstAvailableDeclaration! },
            getIdentifier: { $0.uniqueIdentifier }
        )}
    }
}

internal extension [SymbolGraph.Symbol.DeclarationFragments.Fragment] {
    var rendered: String {
        map(\.spelling).joined()
    }
}
