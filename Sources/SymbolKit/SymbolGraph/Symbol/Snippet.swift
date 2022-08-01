/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

extension SymbolGraph.Symbol {
    public struct Snippet: Mixin, Codable {
        enum CodingKeys: String, CodingKey {
            // TODO: Remove after obsoleting Chunks.
            case chunks
            case language
            case slices
            case lines
        }

        public static let mixinKey = "snippet"
        
        /// The language of the snippet if known.
        public var language: String?
        
        /// The visible lines of code of the snippet to display.
        public var lines: [String]
        
        /// Named spans of lines in the snippet.
        public var slices: [String: Range<Int>]
        
        // TODO: Remove after obsoleting Chunks.
        private var _chunks = [Chunk]()
        
        public init(language: String?, lines: [String], slices: [String: Range<Int>]) {
            self.language = language
            self.lines = lines
            self.slices = slices
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let language = try container.decodeIfPresent(String.self, forKey: .language)
            let lines = try container.decode([String].self, forKey: .lines)
            let slices = try container.decodeIfPresent([String: Range<Int>].self, forKey: .slices) ?? [:]
            self.init(language: language, lines: lines, slices: slices)
            
            // TODO: Remove after obsoleting Chunks.
            self._chunks = try container.decodeIfPresent([Chunk].self, forKey: .chunks) ?? []
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(language, forKey: .language)
            try container.encode(lines, forKey: .lines)
            if !slices.isEmpty {
                try container.encode(slices, forKey: .slices)
            }
            if !_chunks.isEmpty {
                try container.encode(_chunks, forKey: .chunks)
            }
        }
    }
}

extension SymbolGraph.Symbol.Snippet {
    public struct Chunk: Codable {
        public var name: String?
        public var language: String?
        public var code: String
        @available(*, deprecated, message: "Chunks are no longer supported. Use `Slice` instead.")
        public init(name: String?, language: String?, code: String) {
            self.name = name
            self.language = language
            self.code = code
        }
    }
    
    @available(*, deprecated, message: "Chunks are no longer supported. Use `slices` instead.")
    public var chunks: [Chunk] {
        return _chunks
    }
    
    @available(*, deprecated, renamed: "init(slices:)")
    public init(chunks: [Chunk]) {
        self._chunks = chunks
        self.language = chunks.first?.language
        self.slices = [:]
        self.lines = []
    }
}
