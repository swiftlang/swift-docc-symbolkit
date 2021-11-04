/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

extension SymbolGraph {
    /**
     A relationship between two `Symbol`s; a directed edge in a graph.
     */
    public struct Relationship: Codable {
        /// The precise identifier of the symbol that has a relationship.
        public var source: String

        /// The precise identifier of the symbol that the `source` is related to.
        public var target: String

        /// The type of relationship that this edge represents.
        public var kind: Kind

        /// A fallback display name for the target if its module's symbol graph
        /// is not available.
        public var targetFallback: String?

        /// Extra information about a relationship that is not necessarily common to all relationships
        public var mixins: [String: Mixin] = [:]

        enum CodingKeys: String, CaseIterable, CodingKey {
            // Base
            case source
            case target
            case kind
            case targetFallback

            // Mixins
            case swiftConstraints
            case sourceOrigin

            static var mixinKeys: Set<CodingKeys> {
                return [
                    .swiftConstraints,
                    .sourceOrigin
                ]
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            source = try container.decode(String.self, forKey: .source)
            target = try container.decode(String.self, forKey: .target)
            kind = try container.decode(Kind.self, forKey: .kind)
            targetFallback = try container.decodeIfPresent(String.self, forKey: .targetFallback)
            let mixinKeys = Set(container.allKeys).intersection(CodingKeys.mixinKeys)
            for key in mixinKeys {
                if let decoded = try decodeMixinForKey(key, from: container) {
                    mixins[key.stringValue] = decoded
                }
            }
        }

        func decodeMixinForKey(_ key: CodingKeys, from container: KeyedDecodingContainer<CodingKeys>) throws -> Mixin? {
            switch key {
            case .swiftConstraints:
                return try container.decode(Swift.GenericConstraints.self, forKey: key)
            case .sourceOrigin:
                return try container.decode(SourceOrigin.self, forKey: key)
            default:
                return nil
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            // Base

            try container.encode(kind, forKey: .kind)
            try container.encode(source, forKey: .source)
            try container.encode(target, forKey: .target)
            try container.encode(targetFallback, forKey: .targetFallback)

            // Mixins

            for (key, mixin) in mixins {
                let key = CodingKeys(rawValue: key)!
                switch key {
                case .swiftConstraints:
                    try container.encode(mixin as! Swift.GenericConstraints, forKey: key)
                case .sourceOrigin:
                    try container.encode(mixin as! SourceOrigin, forKey: key)
                default:
                    fatalError("Unknown mixin key \(key.rawValue)!")
                }
            }
        }

        public init(source: String, target: String, kind: Kind, targetFallback: String?) {
            self.source = source
            self.target = target
            self.kind = kind
            self.targetFallback = targetFallback
        }
    }
}

extension SymbolGraph.Relationship {
    /// The kind of relationship.
    public struct Kind: Codable, RawRepresentable, Equatable, Hashable {
        public var rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        /**
         A symbol `A` is a member of another symbol `B`.

         For example, a method or field of a class would be
         a member of that class.

         The implied inverse of this relationship is that
         symbol `B` is the owner of a member symbol `A`.
         */
        public static let memberOf = Kind(rawValue: "memberOf")

        /**
         A symbol `A` conforms to an interface/protocol symbol `B`.

         For example, a class `C` that conforms to protocol `P` in Swift would
         use this relationship.

         The implied inverse of this relationship is that
         a symbol `B` that has a conformer `A`.
         */
        public static let conformsTo = Kind(rawValue: "conformsTo")

        /**
         A symbol `A` inherits another symbol `B`.

         For example, a derived class inherits from a base class,
         or a protocol that refines another protocol would use this relationship.

         The implied inverse of this relationship is that
         a symbol `B` is a base of another symbol `A`.
         */
        public static let inheritsFrom = Kind(rawValue: "inheritsFrom")

        /**
         A symbol `A` serves as a default implementation of
         an interface requirement `B`.

         The implied inverse of this relationship is that
         an interface requirement `B` has a default implementation of `A`.
         */
        public static let defaultImplementationOf = Kind(rawValue: "defaultImplementationOf")

        /**
         A symbol `A` overrides another symbol `B`, typically through inheritance.

         The implied inverse of this relationship is that
         a symbol `A` is the base of symbol `B`.
         */
        public static let overrides = Kind(rawValue: "overrides")

        /**
         A symbol `A` is a requirement of interface `B`.

         The implied inverse of this relationship is that
         an interface `B` has a requirement of `A`.
         */
        public static let requirementOf = Kind(rawValue: "requirementOf")

        /**
         A symbol `A` is an optional requirement of interface `B`.

         The implied inverse of this relationship is that
         an interface `B` has an optional requirement of `A`.
         */
        public static let optionalRequirementOf = Kind(rawValue: "optionalRequirementOf")
    }
}

// MARK: - Mixins

extension SymbolGraph.Relationship {
    /// A mixin defining a source symbol's origin.
    public struct SourceOrigin: Mixin, Codable, Hashable {
        public static var mixinKey = "sourceOrigin"

        /// Precise Identifier
        public var identifier: String

        /// Display Name
        public var displayName: String
        
        public init(identifier: String, displayName: String) {
            self.identifier = identifier
            self.displayName = displayName
        }

        enum CodingKeys: String, CodingKey {
            case identifier, displayName
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.identifier = try container.decode(String.self, forKey: .identifier)
            self.displayName = try container.decode(String.self, forKey: .displayName)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(identifier, forKey: .identifier)
            try container.encode(displayName, forKey: .displayName)
        }
    }

    /// A view of a relationship in terms of the Swift programming language.
    public var swift: Swift {
        return .init(relationship: self)
    }

    /// A view of a relationship in terms of the Swift programming language.
    public struct Swift {
        /// The relationship that may have Swift-specific information.
        public var relationship: SymbolGraph.Relationship

        public init(relationship: SymbolGraph.Relationship) {
            self.relationship = relationship
        }

        /// The generic constraints on a relationship.
        ///
        /// > Note: `conformsTo` relationships may have constraints for *conditional conformance*.
        public var genericConstraints: [SymbolGraph.Symbol.Swift.GenericConstraint] {
            guard let genericConstraints = relationship.mixins[GenericConstraints.mixinKey] as? GenericConstraints else {
                return []
            }
            return genericConstraints.constraints
        }
    }
}

extension SymbolGraph.Relationship.Swift {
    /// A mixin collecting Swift generic constraints.
    public struct GenericConstraints: Mixin, Codable, Hashable {
        public static var mixinKey = "swiftConstraints"

        /// Generic constraints.
        public var constraints: [SymbolGraph.Symbol.Swift.GenericConstraint]

        public init(constraints: [SymbolGraph.Symbol.Swift.GenericConstraint]) {
            self.constraints = constraints
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.constraints = try container.decode([SymbolGraph.Symbol.Swift.GenericConstraint].self)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(constraints)
        }
    }
}
