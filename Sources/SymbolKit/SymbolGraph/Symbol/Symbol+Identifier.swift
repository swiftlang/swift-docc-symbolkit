/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol {
    /// Information that uniquely identifies the symbol inside the module.
    public struct Identifier: Codable, Hashable {
        /**
         A string that uniquely identifies a symbol within a module in the event of ambiguities. A precise identifier need not be human readable.
         For example, languages that use [name mangling](https://en.wikipedia.org/wiki/Name_mangling) should use this field for a mangled name.
         */
        public var precise: String

        /// The name of the language for which this symbol provides an interface, such as `swift` or `c`.
        public var interfaceLanguage: String

        public init(precise: String, interfaceLanguage: String) {
            self.precise = precise
            self.interfaceLanguage = interfaceLanguage
        }
    }
}
