/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Relationship {
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
