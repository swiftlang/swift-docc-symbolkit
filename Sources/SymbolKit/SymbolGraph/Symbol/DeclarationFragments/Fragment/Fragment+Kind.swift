/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol.DeclarationFragments.Fragment {
    /**
     The kind of declaration fragment.
     */
    public struct Kind: Equatable, Codable, RawRepresentable {
        public var rawValue: String
        public init?(rawValue: String) {
            self.rawValue = rawValue
        }

        /**
         A keyword in the programming language, such as `return` in C or `func` in Swift.
         */
        public static let keyword = Kind(rawValue: "keyword")!

        /**
         An attribute in the programming language.
         */
        public static let attribute = Kind(rawValue: "attribute")!

        /**
         An integer or floating point literal, such as `0`, `1.0f`, or `0xFF`.
         */
        public static let numberLiteral = Kind(rawValue: "number")!

        /**
         A string literal such as `"foo"`.
         */
        public static let stringLiteral = Kind(rawValue: "string")!

        /**
         An identifier such as a parameter name.
         */
        public static let identifier = Kind(rawValue: "identifier")!

        /**
         An identifier for a type.
         */
        public static let typeIdentifier = Kind(rawValue: "typeIdentifier")!

        /**
         A generic parameter, such as the `T` in C++ `template <typename T>`.
         */
        public static let genericParameter = Kind(rawValue: "genericParameter")!

        /**
         A function parameter when viewed externally as a client.

         For example, in Swift:

         ```swift
         func foo(ext int: Int) {}
         ```

         `ext` is an external parameter name, whereas `int` is an internal
         parameter name.
         */
        public static let externalParameter = Kind(rawValue: "externalParam")!

        /**
         A function parameter when viewed internally from the implementation.

         For example, in Swift:

         ```swift
         func foo(ext int: Int) {}
         ```

         `ext` is an external parameter name, whereas `int` is an internal
         parameter name.

         > Note: Although these are not a part of a function's interface,
         > such as in Swift, they have historically been easier to refer
         > to in prose.
         */
        public static let internalParameter = Kind(rawValue: "internalParam")!

        /**
         General purpose or unlabeled text.
         */
        public static let text = Kind(rawValue: "text")!
    }
}
