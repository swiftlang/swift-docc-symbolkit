/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021-2023 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol.FunctionSignature {
    /// An argument of a callable symbol.
    public struct FunctionParameter: Codable {
        enum CodingKeys: String, CodingKey {
            case externalName = "name"
            case internalName
            case declarationFragments
            case children
        }

        /// The name of the function parameter, as referred to in user code (must match the name used in the documentation comment).
        public var name: String {
            get { internalName }
            set {
                if _internalName == nil {
                    externalName = newValue
                } else {
                    _internalName = newValue
                }
            }
        }
        
        /// The external argument name of the function parameter.
        public var externalName: String
        
        /// The internal parameter name of the function parameter.
        public var internalName: String {
            get { _internalName ?? externalName }
            set { _internalName = newValue }
        }
        
        private var _internalName: String?
        
        /// The syntax used to create the parameter.
        public var declarationFragments: [SymbolGraph.Symbol.DeclarationFragments.Fragment]
        /// Sub-parameters of the parameter.
        public var children: [FunctionParameter]

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            externalName = try container.decodeIfPresent(String.self, forKey: .externalName) ?? ""
            _internalName = try container.decodeIfPresent(String.self, forKey: .internalName)
            declarationFragments = try container.decodeIfPresent([SymbolGraph.Symbol.DeclarationFragments.Fragment].self, forKey: .declarationFragments) ?? []
            children = try container.decodeIfPresent([FunctionParameter].self, forKey: .children) ?? []
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(externalName, forKey: .externalName)
            try container.encodeIfPresent(_internalName, forKey: .internalName)
            try container.encode(declarationFragments, forKey: .declarationFragments)
            try container.encode(children, forKey: .children)
        }
        
        public init(
            externalName: String,
            internalName: String?,
            declarationFragments: [SymbolGraph.Symbol.DeclarationFragments.Fragment],
            children: [SymbolGraph.Symbol.FunctionSignature.FunctionParameter]
        ) {
            self.externalName = externalName
            self._internalName = internalName == externalName ? nil : internalName
            self.declarationFragments = declarationFragments
            self.children = children
        }
    }
}
