/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol.FunctionSignature {
    /// An argument of a callable symbol.
    public struct FunctionParameter: Codable {
        enum CodingKeys: String, CodingKey {
            case name
            case declarationFragments
            case children
        }

        /// The name of the symbol, as referred to in user code (must match the name used in the documentation comment).
        public var name: String // should we differentiate between internal and external names?
        /// The syntax used to create the parameter.
        public var declarationFragments: [SymbolGraph.Symbol.DeclarationFragments.Fragment]
        /// Sub-parameters of the parameter.
        public var children: [FunctionParameter]

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            declarationFragments = try container.decodeIfPresent([SymbolGraph.Symbol.DeclarationFragments.Fragment].self, forKey: .declarationFragments) ?? []
            children = try container.decodeIfPresent([FunctionParameter].self, forKey: .children) ?? []
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(declarationFragments, forKey: .declarationFragments)
            try container.encode(children, forKey: .children)
        }
    }
}
