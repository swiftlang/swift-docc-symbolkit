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
            case name
            case externalName
            case internalName
            case declarationFragments
            case children
        }

        /// The name of the function parameter. This matches how the parameter is referred to a documentation comment.
        ///
        /// ## Example
        ///
        /// This C function has one parameter where ``name`` is "someValue".
        ///
        /// ```c
        /// void doSomething(int someValue);
        /// //                   ╰─ name
        /// ```
        public var name: String
        
        /// The external argument name of the function parameter, if different from the parameter name.
        ///
        /// ## Example
        ///
        /// In Swift which supports separate argument labels and parameter names, this function has one parameter where ``externalName`` is "with" and ``name`` is "someValue".
        ///
        /// ```swift
        /// func doSomething(with someValue: Int) {}
        /// //               │    ╰─ name
        /// //               ╰─ externalName
        /// ```
        ///
        /// A similar function in C, which doesn't separate argument labels from parameter names, has one parameter where ``externalName`` is `nil` and ``name`` is "someValue".
        ///
        /// ```c
        /// void doSomething(int someValue);
        /// //                   ╰─ name
        /// ```
        public var externalName: String?
        
        /// The syntax used to create the parameter.
        public var declarationFragments: [SymbolGraph.Symbol.DeclarationFragments.Fragment]
        /// Sub-parameters of the parameter.
        public var children: [FunctionParameter]

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
            if let internalName = try container.decodeIfPresent(String.self, forKey: .internalName) {
                // Symbol graph generators that emit "name" and "internalName" are remapped to `externalName` and `name`
                // so that `name` matches how the parameter is referred to in a documentation comment.
                self.name = internalName
                self.externalName = name
            } else {
                self.name = name
                self.externalName = try container.decodeIfPresent(String.self, forKey: .externalName)
            }
            declarationFragments = try container.decodeIfPresent([SymbolGraph.Symbol.DeclarationFragments.Fragment].self, forKey: .declarationFragments) ?? []
            children = try container.decodeIfPresent([FunctionParameter].self, forKey: .children) ?? []
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encodeIfPresent(externalName, forKey: .externalName)
            try container.encode(declarationFragments, forKey: .declarationFragments)
            try container.encode(children, forKey: .children)
        }
        
        public init(
            name: String,
            externalName: String?,
            declarationFragments: [SymbolGraph.Symbol.DeclarationFragments.Fragment],
            children: [SymbolGraph.Symbol.FunctionSignature.FunctionParameter]
        ) {
            self.name = name
            self.externalName = externalName == name ? nil : externalName
            self.declarationFragments = declarationFragments
            self.children = children
        }
    }
}
