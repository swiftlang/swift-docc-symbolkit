/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol.Swift {
    /**
     The generic signature of a declaration or type.
     */
    public struct Generics: Mixin {
        public static let mixinKey = "swiftGenerics"

        enum CodingKeys: String, CodingKey {
            case parameters
            case constraints
        }

        /**
         The generic parameters of a declaration.

         For example, in the following generic function signature,

         ```swift
         func foo<T>(_ thing: T) { ... }
         ```

         `T` is a *generic parameter*.
         */
        public var parameters: [GenericParameter]

        /**
         The generic constraints of a declaration.

         For example, in the following generic function signature,

         ```swift
         func foo<S>(_ s: S) where S: Sequence
         ```

         There is a *conformance constraint* involving `S`.
         */
        public var constraints: [GenericConstraint]
        
        public init(parameters: [SymbolGraph.Symbol.Swift.GenericParameter], constraints: [SymbolGraph.Symbol.Swift.GenericConstraint]) {
            self.parameters = parameters
            self.constraints = constraints
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            parameters = try container.decodeIfPresent([GenericParameter].self, forKey: .parameters) ?? []
            constraints = try container.decodeIfPresent([GenericConstraint].self, forKey: .constraints) ?? []
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            if !parameters.isEmpty {
                try container.encode(parameters, forKey: .parameters)
            }
            if !constraints.isEmpty {
                try container.encode(constraints, forKey: .constraints)
            }
        }
    }
}
