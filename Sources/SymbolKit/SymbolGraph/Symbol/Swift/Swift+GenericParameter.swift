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
     A generic parameter of a declaration, such as the `T` in `foo<T>(...)`.
     */
    public struct GenericParameter: Codable {
        /// The name of the generic parameter.
        public var name: String

        /**
         The index of the generic parameter.

         For example, in the following function signature,

         ```swift
         func foo<T, U>(x: T, y: U)
         ```

         `T` has index 0 and `U` has index 1.
         */
        public var index: Int

        /**
         The depth of the generic parameter.

         For example, in the following generic structure,

         ```swift
         struct MyStruct<T> {
           func foo<U>(x: U, y: T) {
             // ...
           }
         }
         ```

         `T` has depth 0 and `U` has depth 1.
         */
        public var depth: Int
    }
}
