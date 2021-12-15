/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph {
    public struct Metadata: Codable {
        /// The version of the serialization format.
        public var formatVersion: SemanticVersion

        /// A string describing the tool or system that generated the data for this symbol graph.
        ///
        /// This should include a name and version if possible to track down potential
        /// serialization bugs.
        public var generator: String

        public init(formatVersion: SemanticVersion, generator: String) {
            self.formatVersion = formatVersion
            self.generator = generator
        }
    }
}
