/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol.DeclarationFragments {
    /**
     A general-purpose fragment of syntax spelling out a declaration.

     For example, a C function might break up `int main(int argc, char **argv)`
     or a Swift structure might break up into `struct MyStruct<S: Sequence>`.
     */
    public struct Fragment: Equatable, Codable {
        /**
         The kind of fragment, such as a token keyword, identifier,
         or span of text.
         */
        public var kind: Kind

        /**
         How the token was spelled in the source code.
         */
        public var spelling: String

        /**
         A precise identifier if the fragment corresponds to another symbol.
         This may be useful for linking to other symbols when displaying
         function parameter types.
         */
        public var preciseIdentifier: String?

        /**
          Initialize a fragment with the given `kind`, `spelling`, and `preciseIdentifier`.

          - Parameters:
             - kind: The kind of fragment.
             - spelling: How the token was spelled in the source code.
             - preciseIdentifier: A precise identifier if the fragment corresponds to another symbol.
         */
        public init(kind: Kind, spelling: String, preciseIdentifier: String?) {
            self.kind = kind
            self.spelling = spelling
            self.preciseIdentifier = preciseIdentifier
        }
    }
}
