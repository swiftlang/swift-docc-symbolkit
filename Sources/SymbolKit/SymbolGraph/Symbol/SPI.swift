/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol {
    /// Whether the symbol is marked as a System Programming Interface in source.
    public struct SPI: Mixin, Codable {
        public static let mixinKey = "spi"

        public var isSPI: Bool

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            isSPI = try container.decode(Bool.self)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(isSPI)
        }

        public init(isSPI: Bool) {
            self.isSPI = isSPI
        }
    }
}
