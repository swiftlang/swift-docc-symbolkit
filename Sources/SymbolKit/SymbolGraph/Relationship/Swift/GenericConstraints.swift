/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

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
            constraints = try container.decode([SymbolGraph.Symbol.Swift.GenericConstraint].self)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(constraints)
        }
    }
}
