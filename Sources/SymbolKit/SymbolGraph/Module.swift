/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph {
    /// A ``Module-swift.struct``  describes the module from which the symbols were extracted..
    public struct Module: Codable {
        /// The name of the module.
        public var name: String

        /// Optional bystander module names.
        public var bystanders: [String]?

        /// The platform intended for deployment.
        public var platform: Platform

        /// The [semantic version](https://semver.org) of the module, if availble.
        public var version: SemanticVersion?

        public init(name: String, platform: Platform, version: SemanticVersion? = nil, bystanders: [String]? = nil) {
            self.name = name
            self.platform = platform
            self.version = version
            self.bystanders = bystanders
        }
    }
}
