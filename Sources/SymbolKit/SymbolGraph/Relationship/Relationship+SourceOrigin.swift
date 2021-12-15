/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Relationship {
    /// A mixin defining a source symbol's origin.
    public struct SourceOrigin: Mixin, Codable, Hashable {
        public static var mixinKey = "sourceOrigin"

        /// Precise Identifier
        public var identifier: String

        /// Display Name
        public var displayName: String

        public init(identifier: String, displayName: String) {
            self.identifier = identifier
            self.displayName = displayName
        }

        enum CodingKeys: String, CodingKey {
            case identifier, displayName
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            identifier = try container.decode(String.self, forKey: .identifier)
            displayName = try container.decode(String.self, forKey: .displayName)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(identifier, forKey: .identifier)
            try container.encode(displayName, forKey: .displayName)
        }
    }
}
