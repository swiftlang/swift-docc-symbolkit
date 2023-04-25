/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2023 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Relationship {
    /// A mixin for `references` relationships that indicates the source location of the reference.
    public struct ReferenceLocation: Mixin, Codable, Equatable {
        public static var mixinKey = "referenceLocation"

        /// The source locations where the reference occurs.
        public var range: SymbolGraph.LineList.SourceRange

        /// The URI of the source file where the reference occurs.
        public var uri: String

        /// The file URL of the source file where the reference occurs.
        @available(macOS 10.11, *)
        public var url: URL? {
            // The URI string provided in the symbol graph file may be an invalid URL (rdar://69242070)
            //
            // Using `URL.init(dataRepresentation:relativeTo:)` here handles URI strings with unescaped
            // characters without trying to escape or otherwise process the URI string in SymbolKit.
            return URL(dataRepresentation: Data(uri.utf8), relativeTo: nil)
        }

        public init(range: SymbolGraph.LineList.SourceRange, uri: String) {
            self.range = range
            self.uri = uri
        }
    }
}
