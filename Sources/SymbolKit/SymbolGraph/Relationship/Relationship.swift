/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

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
        ///
        /// - Note: If you intend to encode/decode this relationship, make sure to register
        /// any added ``Mixin``s that do not appear on relationships in the standard format
        /// on your coder using ``register(mixins:to:onEncodingError:onDecodingError:)``.
        public var mixins: [String: Mixin] = [:]
        
        /// Extra information about a relationship that is not necessarily common to all relationships
        ///
        /// - Note: If you intend to encode/decode this relationship, make sure to register
        /// any added ``Mixin``s that do not appear on relationships in the standard format
        /// on your coder using ``register(mixins:to:onEncodingError:onDecodingError:)``.
        public subscript<M: Mixin>(mixin mixin: M.Type = M.self) -> M? {
            get {
                mixins[mixin.mixinKey] as? M
            }
            set {
                mixins[mixin.mixinKey] = newValue
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            source = try container.decode(String.self, forKey: .source)
            target = try container.decode(String.self, forKey: .target)
            kind = try container.decode(Kind.self, forKey: .kind)
            targetFallback = try container.decodeIfPresent(String.self, forKey: .targetFallback)
            
            for key in container.allKeys {
                guard let info = CodingKeys.mixinKeys[key.stringValue] ?? decoder.registeredRelationshipMixins?[key.stringValue] else {
                    continue
                }
                
                mixins[info.codingKey.stringValue] = try info.decode(container)
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
                guard let info = CodingKeys.mixinKeys[key] ?? encoder.registeredRelationshipMixins?[key] else {
                    continue
                }
                
                try info.encode(mixin, &container)
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
    struct CodingKeys: CodingKey, Hashable {
        let stringValue: String
        
        init?(stringValue: String) {
            self = CodingKeys(rawValue: stringValue)
        }
        
        init(rawValue: String) {
            self.stringValue = rawValue
        }
        
        // Base
        static let source = CodingKeys(rawValue: "source")
        static let target = CodingKeys(rawValue: "target")
        static let kind = CodingKeys(rawValue: "kind")
        static let targetFallback = CodingKeys(rawValue: "targetFallback")

        // Mixins
        static let swiftConstraints = Swift.GenericConstraints.relationshipCodingInfo
        static let sourceOrigin = SourceOrigin.relationshipCodingInfo
        
        static let mixinKeys: [String: RelationshipMixinCodingInfo] = [
            CodingKeys.swiftConstraints.codingKey.stringValue: Self.swiftConstraints,
            CodingKeys.sourceOrigin.codingKey.stringValue: Self.sourceOrigin,
        ]
        
        static func == (lhs: SymbolGraph.Relationship.CodingKeys, rhs: SymbolGraph.Relationship.CodingKeys) -> Bool {
            lhs.stringValue == rhs.stringValue
        }
        
        func hash(into hasher: inout Hasher) {
            stringValue.hash(into: &hasher)
        }
        
        var intValue: Int? { nil }
        
        init?(intValue: Int) {
            nil
        }
    }
}

extension SymbolGraph.Relationship {
    /// Register types conforming to ``Mixin`` so they can be included when encoding or
    /// decoding relationships.
    ///
    /// If ``SymbolGraph/Relationship`` does not know the concrete type of a ``Mixin``, it cannot encode
    /// or decode that type and thus skipps such entries. Note that ``Mixin``s that occur on relationships
    /// in the default symbol graph format do not have to be registered!
    ///
    /// - Parameter userInfo: A property which allows editing the `userInfo` member of the
    /// `Encoder`/`Decoder` protocol.
    /// - Parameter onEncodingError: Defines the behavior when an error occurs while encoding these types of ``Mixin``s.
    /// You can log warnings and either re-throw or consume the error.
    /// - Parameter onDecodingError: Defines the behavior when an error occurs while decoding these types of ``Mixin``s.
    /// Next to logging warnings, the function allows for either re-throwing the error,
    /// skipping the errornous entry, or providing a default value.
    public static func register<M: Sequence>(mixins mixinTypes: M,
                                             to userInfo: inout [CodingUserInfoKey: Any],
                                             onEncodingError: ((_ error: Error, _ mixin: Mixin) throws -> Void)?,
                                             onDecodingError: ((_ error: Error) throws -> Mixin?)?) where M.Element == Mixin.Type {
        var registeredMixins = userInfo[.relationshipMixinKey] as? [String: RelationshipMixinCodingInfo] ?? [:]
            
        for type in mixinTypes {
            var info = type.relationshipCodingInfo
            if let encodingErrorHandler = onEncodingError {
                info = info.with(encodingErrorHandler: encodingErrorHandler)
            }
            if let decodingErrorHandler = onDecodingError {
                info = info.with(decodingErrorHandler: decodingErrorHandler)
            }
            
            registeredMixins[type.mixinKey] = info
        }
        
        userInfo[.relationshipMixinKey] = registeredMixins
    }
}

public extension JSONEncoder {
    /// Register types conforming to ``Mixin`` so they can be included when encoding relationships.
    ///
    /// If ``SymbolGraph/Relationship`` does not know the concrete type of a ``Mixin``, it cannot encode
    /// that type and thus skipps such entries. Note that ``Mixin``s that occur on relationships
    /// in the default symbol graph format do not have to be registered!
    ///
    /// - Parameter onEncodingError: Defines the behavior when an error occurs while encoding these types of ``Mixin``s.
    /// You can log warnings and either re-throw or consume the error.
    /// - Parameter onDecodingError: Defines the behavior when an error occurs while decoding these types of ``Mixin``s.
    /// Next to logging warnings, the function allows for either re-throwing the error,
    /// skipping the errornous entry, or providing a default value.
    func register(relationshipMixins mixinTypes: Mixin.Type...,
                  onEncodingError: ((_ error: Error, _ mixin: Mixin) throws -> Void)? = nil,
                  onDecodingError: ((_ error: Error) throws -> Mixin?)? = nil) {
        SymbolGraph.Relationship.register(mixins: mixinTypes,
                                          to: &self.userInfo,
                                          onEncodingError: onEncodingError,
                                          onDecodingError: onDecodingError)
    }
}

public extension JSONDecoder {
    /// Register types conforming to ``Mixin`` so they can be included when decoding relationships.
    ///
    /// If ``SymbolGraph/Relationship`` does not know the concrete type of a ``Mixin``, it cannot decode
    /// that type and thus skipps such entries. Note that ``Mixin``s that occur on relationships
    /// in the default symbol graph format do not have to be registered!
    ///
    /// - Parameter onEncodingError: Defines the behavior when an error occurs while encoding these types of ``Mixin``s.
    /// You can log warnings and either re-throw or consume the error.
    /// - Parameter onDecodingError: Defines the behavior when an error occurs while decoding these types of ``Mixin``s.
    /// Next to logging warnings, the function allows for either re-throwing the error,
    /// skipping the errornous entry, or providing a default value.
    func register(relationshipMixins mixinTypes: Mixin.Type...,
                  onEncodingError: ((_ error: Error, _ mixin: Mixin) throws -> Void)? = nil,
                  onDecodingError: ((_ error: Error) throws -> Mixin?)? = nil) {
        SymbolGraph.Relationship.register(mixins: mixinTypes,
                                          to: &self.userInfo,
                                          onEncodingError: onEncodingError,
                                          onDecodingError: onDecodingError)
    }
}

extension Encoder {
    var registeredRelationshipMixins: [String: RelationshipMixinCodingInfo]? {
        self.userInfo[.relationshipMixinKey] as? [String: RelationshipMixinCodingInfo]
    }
}

extension Decoder {
    var registeredRelationshipMixins: [String: RelationshipMixinCodingInfo]? {
        self.userInfo[.relationshipMixinKey] as? [String: RelationshipMixinCodingInfo]
    }
}

extension CodingUserInfoKey {
    static let relationshipMixinKey = CodingUserInfoKey(rawValue: "org.swift.symbolkit.relationshipMixinKey")!
}

// MARK: Hashable/Equatable Conformance

extension SymbolGraph.Relationship: Hashable, Equatable {

    /// A custom hashing for the relationship.
    ///
    /// - Note: ``Mixin``s that do not conform to `Hashable` will be ignored entirely, including their count and
    /// ``Mixin/mixinKey``.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(source)
        hasher.combine(target)
        hasher.combine(kind.rawValue)
        hasher.combine(targetFallback)
        
        for (key, mixin) in mixins {
            if let hash = mixin.hash {
                hasher.combine(key)
                hash(&hasher)
            }
        }
    }

    /// A custom equality implmentation for a relationship.
    ///
    /// - Note: ``Mixin``s that do not conform to `Equatable` will be ignored entirely, including their count and
    /// ``Mixin/mixinKey``.
    public static func == (lhs: SymbolGraph.Relationship, rhs: SymbolGraph.Relationship) -> Bool {
        guard lhs.source == rhs.source
            && lhs.target == rhs.target
            && lhs.kind == rhs.kind
            && lhs.targetFallback == rhs.targetFallback
            // we only require the number of `Equatable` mixins to be equal
            && lhs.mixins.values.compactMap(\.equals).count == rhs.mixins.values.compactMap(\.equals).count else {
            return false
        }
        
        for (key, lhs) in lhs.mixins {
            if let lhsEquals = lhs.equals,
               !lhsEquals(rhs.mixins[key] as Any) {
                return false
            }
        }
        
        return true
    }
}
