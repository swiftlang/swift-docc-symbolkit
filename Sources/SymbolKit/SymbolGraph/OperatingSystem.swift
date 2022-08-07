/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

extension SymbolGraph {
    /**
     The operating system intended for a ``Module-swift.struct``'s deployment.
     */
    public struct OperatingSystem: Codable, Equatable {
        /**
         The name of the operating system, such as `macOS` or `Linux`.
         */
        public var name: String

        /**
         The intended minimum version of the operating system. If no specific version
         is required, this may be undefined.
         */
        public var minimumVersion: SemanticVersion?

        public init(name: String, minimumVersion: SemanticVersion? = nil) {
            self.name = name
            self.minimumVersion = minimumVersion
        }
    }
}
