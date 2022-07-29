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
    public struct Module: Codable, Equatable {
        /// The name of the module.
        public var name: String

        /// Optional bystander module names.
        public var bystanders: [String]?

        /// The platform intended for deployment.
        public var platform: Platform

        /// The [semantic version](https://semver.org) of the module, if availble.
        public var version: SemanticVersion?

        /// `true` if the module represents a virtual module, not created from source,
        /// but one created implicitly to hold relationships.
        public var isVirtual: Bool = false

        public init(name: String, platform: Platform, version: SemanticVersion? = nil, bystanders: [String]? = nil, isVirtual: Bool = false) {
            self.name = name
            self.platform = platform
            self.version = version
            self.bystanders = bystanders
            self.isVirtual = isVirtual
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.bystanders = try container.decodeIfPresent([String].self, forKey: .bystanders)
            self.platform = try container.decode(Platform.self, forKey: .platform)
            self.version = try container.decodeIfPresent(SemanticVersion.self, forKey: .version)
            self.isVirtual = try container.decodeIfPresent(Bool.self, forKey: .isVirtual) ?? false
        }
    }
}
