/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol {
    /// The arguments of a callable symbol.
    public struct FunctionSignature: Mixin, Codable {
        enum CodingKeys: String, CodingKey {
            case parameters
            case returns
        }

        public static let mixinKey = "functionSignature"

        /**
         The parameters of the function.
         */
        public var parameters: [FunctionParameter]

        /**
         The fragments spelling out the return type of the function signature if applicable.
         */
        public var returns: [DeclarationFragments.Fragment]

        public init(parameters: [SymbolGraph.Symbol.FunctionSignature.FunctionParameter], returns: [SymbolGraph.Symbol.DeclarationFragments.Fragment]) {
            self.parameters = parameters
            self.returns = returns
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            parameters = try container.decodeIfPresent([FunctionParameter].self, forKey: .parameters) ?? []
            returns = try container.decodeIfPresent([DeclarationFragments.Fragment].self, forKey: .returns) ?? []
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(parameters, forKey: .parameters)
            try container.encode(returns, forKey: .returns)
        }
    }
}
