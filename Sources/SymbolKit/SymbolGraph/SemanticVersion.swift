/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

extension SymbolGraph {
    /// A [semantic version](https://semver.org).
    public struct SemanticVersion: Codable, Equatable, CustomStringConvertible {
        /**
         * The major version number.
         *
         * For example, the `1` in `1.2.3`
         */
        public var major: Int
        /**
         * The minor version number.
         *
         * For example, the `2` in `1.2.3`
         */
        public var minor: Int
        /**
         * The patch version number.
         *
         * For example, the `3` in `1.2.3`
         */
        public var patch: Int

        /// The optional prerelease version component, which may contain non-numeric characters.
        ///
        /// For example, the `4` in `1.2.3-4`.
        public var prerelease: String?

        /// Optional build metadata.
        public var buildMetadata: String?

        public init(major: Int, minor: Int, patch: Int, prerelease: String? = nil, buildMetadata: String? = nil) {
            self.major = major
            self.minor = minor
            self.patch = patch
            self.prerelease = prerelease
            self.buildMetadata = buildMetadata
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            major = try container.decode(Int.self, forKey: .major)
            minor = try container.decodeIfPresent(Int.self, forKey: .minor) ?? 0
            patch = try container.decodeIfPresent(Int.self, forKey: .patch) ?? 0
            prerelease = try container.decodeIfPresent(String.self, forKey: .prerelease)
            buildMetadata = try container.decodeIfPresent(String.self, forKey: .buildMetadata)
        }

        public var description: String {
            var result = "\(major).\(minor).\(patch)"
            if let prerelease = prerelease {
                result += "-\(prerelease)"
            }
            if let buildMetadata = buildMetadata {
                result += "+\(buildMetadata)"
            }
            return result
        }
    }
}
