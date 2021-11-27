/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

extension SymbolGraph {
    /// A [semantic version](https://semver.org).
    public struct SemanticVersion {
        /// The major version according to the semantic versioning standard.
        public let major: Int
        /// The minor version according to the semantic versioning standard.
        public let minor: Int
        /// The patch version according to the semantic versioning standard.
        public let patch: Int
        /// The pre-release identifier according to the semantic versioning standard, such as `-beta.1`.
        public let prereleaseIdentifiers: [String]
        /// The build metadata of this version according to the semantic versioning standard, such as a commit hash.
        public let buildMetadataIdentifiers: [String]
        
        /// Initializes a semantic version struct with the provided components of a semantic version.
        /// - Parameters:
        ///   - major: The major version number.
        ///   - minor: The minor version number.
        ///   - patch: The patch version number.
        ///   - prereleaseIdentifiers: The pre-release identifiers.
        ///   - buildMetaDataIdentifiers: Build metadata that identifies a build.
        public init(
            _ major: Int,
            _ minor: Int,
            _ patch: Int,
            prereleaseIdentifiers: [String] = [],
            buildMetadataIdentifiers: [String] = []
        ) {
            precondition(major >= 0 && minor >= 0 && patch >= 0, "Negative versioning is invalid.")
            precondition(
                prereleaseIdentifiers.allSatisfy {
                    $0.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
                },
                #"Pre-release identifiers can contain only ASCII alpha-numerical characters and "-"."#
            )
            precondition(
                buildMetadataIdentifiers.allSatisfy {
                    $0.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
                },
                #"Build metadata identifiers can contain only ASCII alpha-numerical characters and "-"."#
            )
                
            self.major = major
            self.minor = minor
            self.patch = patch
            self.prereleaseIdentifiers = prereleaseIdentifiers
            self.buildMetadataIdentifiers = buildMetadataIdentifiers
        }
        
        /// Initializes a semantic version struct with the provided components of a semantic version.
        /// - Parameters:
        ///   - major: The major version number.
        ///   - minor: The minor version number.
        ///   - patch: The patch version number.
        ///   - prereleaseIdentifiers: The "."-separated pre-release identifiers.
        ///   - buildMetaDataIdentifiers: The "."-separated build metadata that identifies a build.
        @_disfavoredOverload
        public init(
            _ major: Int,
            _ minor: Int,
            _ patch: Int,
            prereleaseIdentifiers: String? = nil,
            buildMetadataIdentifiers: String? = nil
        ) {
            self.init(
                major, minor, patch,
                prereleaseIdentifiers: prereleaseIdentifiers?
                    .split(separator: ".", omittingEmptySubsequences: false)
                    .map { String($0) } ?? [],
                buildMetadataIdentifiers: buildMetadataIdentifiers?
                    .split(separator: ".", omittingEmptySubsequences: false)
                    .map { String($0) } ?? []
            )
        }

        @available(*, deprecated, renamed: "init(_:_:_:prereleaseIdentifiers:buildMetadataIdentifiers:)")
        public init(major: Int, minor: Int, patch: Int, prerelease: String? = nil, buildMetadata: String? = nil) {
            self.init(major, minor, patch, prereleaseIdentifiers: prerelease, buildMetadataIdentifiers: buildMetadata)
        }
    }
}

extension SymbolGraph.SemanticVersion: Codable {
    
    // FIXME: Should this be public?
    private enum CodingKeys: String, CodingKey {
        case major
        case minor
        case patch
        case prereleaseIdentifiers = "prerelease"
        case buildMetadataIdentifiers = "buildMetadata"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.major = try container.decode(Int.self, forKey: .major)
        self.minor = try container.decodeIfPresent(Int.self, forKey: .minor) ?? 0
        self.patch = try container.decodeIfPresent(Int.self, forKey: .patch) ?? 0
        self.prereleaseIdentifiers = try container.decodeIfPresent(String.self, forKey: .prereleaseIdentifiers)?
            .split(separator: ".", omittingEmptySubsequences: false)
            .map { String($0) } ?? []
        self.buildMetadataIdentifiers = try container.decodeIfPresent(String.self, forKey: .buildMetadataIdentifiers)?
            .split(separator: ".", omittingEmptySubsequences: false)
            .map { String($0) } ?? []
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(major, forKey: .major)
        try container.encode(minor, forKey: .minor)
        try container.encode(patch, forKey: .patch)
        if !prereleaseIdentifiers.isEmpty {
            try container.encode(prereleaseIdentifiers.joined(separator: "."), forKey: .prereleaseIdentifiers)
        }
        if !buildMetadataIdentifiers.isEmpty {
            try container.encode(buildMetadataIdentifiers.joined(separator: "."), forKey: .buildMetadataIdentifiers)
        }
    }
    
}

extension SymbolGraph.SemanticVersion: Comparable {
    // Although `Comparable` inherits from `Equatable`, it does not provide a new default implementation of `==`, but instead uses `Equatable`'s default synthesised implementation. The compiler-synthesised `==`` is composed of [member-wise comparisons](https://github.com/apple/swift-evolution/blob/main/proposals/0185-synthesize-equatable-hashable.md#implementation-details), which leads to a false `false` when 2 semantic versions differ by only their build metadata identifiers, contradicting SemVer 2.0.0's [comparison rules](https://semver.org/#spec-item-10).
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        !(lhs < rhs) && !(lhs > rhs)
    }
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        let lhsComparators = [lhs.major, lhs.minor, lhs.patch]
        let rhsComparators = [rhs.major, rhs.minor, rhs.patch]
        
        guard lhsComparators == rhsComparators else {
            return lhsComparators.lexicographicallyPrecedes(rhsComparators)
        }
        
        guard lhs.prereleaseIdentifiers.count > 0 else {
            return false // non-pre-release lhs >= potentially pre-release rhs
        }
        
        guard rhs.prereleaseIdentifiers.count > 0 else {
            return true // pre-release lhs < non-pre-release rhs
        }
        
        for (lhsPrereleaseIdentifier, rhsPrereleaseIdentifier) in zip(lhs.prereleaseIdentifiers, rhs.prereleaseIdentifiers) {
            guard lhsPrereleaseIdentifier != rhsPrereleaseIdentifier else {
                continue
            }
            
            // Check if either of the 2 pre-release identifiers is numeric.
            let lhsNumericPrereleaseIdentifier = Int(lhsPrereleaseIdentifier)
            let rhsNumericPrereleaseIdentifier = Int(rhsPrereleaseIdentifier)
            
            if let lhsNumericPrereleaseIdentifier = lhsNumericPrereleaseIdentifier,
               let rhsNumericPrereleaseIdentifier = rhsNumericPrereleaseIdentifier {
                // Semantic Versioning 2.0.0 considers 2 pre-release identifiers equal, if they're numerically equal _or_ textually equal. In other words, if 2 identifiers are numeric, they are unequal _if and only if_ they're numerically unequal. Identifiers that have entered this conditional block must have not been textually equal, but it is still possible for them to be numerically equal. For example: "100" and "00100" are textually unequal but numerically equal. If the 2 identifiers in comparison are indeed equal, then unless they're the last pair of pre-release identifiers, they cannot be the deciding pair for the precedence between the 2 semantic versions.
                if lhsNumericPrereleaseIdentifier == rhsNumericPrereleaseIdentifier {
                    continue
                } else {
                    return lhsNumericPrereleaseIdentifier < rhsNumericPrereleaseIdentifier
                }
            } else if lhsNumericPrereleaseIdentifier != nil {
                return true // numeric pre-release < non-numeric pre-release
            } else if rhsNumericPrereleaseIdentifier != nil {
                return false // non-numeric pre-release > numeric pre-release
            } else {
                return lhsPrereleaseIdentifier < rhsPrereleaseIdentifier
            }
        }
        
        return lhs.prereleaseIdentifiers.count < rhs.prereleaseIdentifiers.count
    }
}

extension SymbolGraph.SemanticVersion: CustomStringConvertible {
    /// A textual description of the `Semantic Version` instance.
    public var description: String {
        var versionString = "\(major).\(minor).\(patch)"
        if !prereleaseIdentifiers.isEmpty {
            versionString += "-" + prereleaseIdentifiers.joined(separator: ".")
        }
        if !buildMetadataIdentifiers.isEmpty {
            versionString += "+" + buildMetadataIdentifiers.joined(separator: ".")
        }
        return versionString
    }
}
