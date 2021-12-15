/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol {
    /**
     A mix-in that generically describes the fragments
     of a symbol's declaration in a particular language, allowing for idiomatic
     presentation.

     For example, one can use this to drive a "code snippet"
     with syntax highlighting for a function signature.

     For example, the following declaration in Swift:

     ```swift
     func foo<S: Sequence>(_ sequence: S) -> Int {
         // ...
     }
     ```

     Would be represented with the following list of tokens when displaying
     the declaration fragment:

     ```json
     [
         {
             "kind": "keyword",
             "spelling": "func"
         },
         {
             "kind": "identifier",
             "spelling": "foo"
         },
         {
             "kind": "punctuation",
             "spelling": "<"
         },
         {
             "kind": "identifier",
             "spelling": "S"
         },
         {
             "kind": "punctuation",
             "spelling": ":"
         },
         {
             "kind": "trivia",
             "spelling": " "
         },
         {
             "kind": "typeIdentifier",
             "spelling": "Sequence",
             "preciseIdentifier": "$sST"
         },
         {
             "kind": "punctuation",
             "spelling": ">"
         },
         {
             "kind": "punctuation",
             "spelling": "("
         },
         {
             "kind": "identifier",
             "spelling": "_"
         },
         {
             "kind": "trivia",
             "spelling": " "
         },
         {
             "kind": "identifier",
             "spelling": "seq"
         },
         {
             "kind": "punctuation",
             "spelling": ":"
         },
         {
             "kind": "typeIdentifier",
             "spelling": "Sequence",
             "preciseIdentifier": "$sST"
         },
         {
             "kind": "punctuation",
             "spelling": ":"
         },
         {
             "kind": "identifier",
             "spelling": "S"
         },
             {
             "kind": "punctuation",
             "spelling": ")"
         },
             {
             "kind": "trivia",
             "spelling": " "
         },
         {
             "kind": "punctuation",
             "spelling": "->"
         },
             {
             "kind": "trivia",
             "spelling": " "
         },
             {
             "kind": "typeIdentifier",
             "spelling": "Int",
             "preciseIdentifier": "$sSi"
         }
     ]
     ```
     */
    public struct DeclarationFragments: Mixin, Codable {
        public static let mixinKey = "declarationFragments"

        /**
         A list of fragments spelling out the declarations,
         allowing for a presentation that's idiomatic to the source language
         and cross-referencing identifiers to other symbols in the module.

         > Note: These may not necessarily, literally be lexer tokens but they may be.
         */
        public var declarationFragments: [Fragment]

        /**
          Initialize a declaration fragments mix-in with the given list of fragments.

          - Parameters:
             - declarationFragments: The list of fragments spelling out the declaration.
         */
        public init(declarationFragments: [Fragment]) {
            self.declarationFragments = declarationFragments
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            declarationFragments = try container.decode([Fragment].self)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(declarationFragments)
        }
    }
}
