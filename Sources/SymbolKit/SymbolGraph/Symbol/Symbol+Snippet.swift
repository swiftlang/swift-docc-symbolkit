/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

extension SymbolGraph.Symbol {
    public struct Snippet: Mixin, Codable {
        public struct Chunk: Codable {
            public var name: String?
            public var language: String?
            public var code: String
            public init(name: String?, language: String?, code: String) {
                self.name = name
                self.language = language
                self.code = code
            }
        }

        public static let mixinKey = "snippet"

        public var chunks: [Chunk]

        enum CodingKeys: String, CodingKey {
            case chunks
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let chunks = try container.decode([Chunk].self, forKey: .chunks)
            self.init(chunks: chunks)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(chunks, forKey: .chunks)
        }

        public init(chunks: [Chunk]) {
            self.chunks = chunks
        }
    }
}
