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
                    .sourceOrigin,
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
