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
        /// The major version.
        public let major: Int
        /// The minor version.
        public let minor: Int
        /// The patch version.
        public let patch: Int
        /// Dot-separated pre-release identifiers.
        public var prereleaseIdentifiers: [String] { prerelease.identifiers.map(\.description) }
        /// Dot-separated build metadata identifiers.
        public let buildMetadataIdentifiers: [String]
        
        /// The internal storage of pre-release identifiers.
        internal let prerelease: Prerelease
        
        /// Creates a semantic version with the provided components of a semantic version.
        /// - Parameters:
        ///   - major: The major version number.
        ///   - minor: The minor version number.
        ///   - patch: The patch version number.
        ///   - prereleaseIdentifiers: The pre-release identifiers.
        ///   - buildMetaDataIdentifiers: The build metadata identifiers.
        public init(
            // FIXME: Should `major`, `minor`, and `patch` be `UInt`?
            _ major: Int,
            _ minor: Int,
            _ patch: Int,
            prereleaseIdentifiers: [String] = [],
            buildMetadataIdentifiers: [String] = []
        ) throws {
            guard major >= 0 else { throw SemanticVersionError.invalidNumericIdentifier(major.description, position: .major, errorKind: .negativeValue)}
            guard minor >= 0 else { throw SemanticVersionError.invalidNumericIdentifier(minor.description, position: .minor, errorKind: .negativeValue)}
            guard patch >= 0 else { throw SemanticVersionError.invalidNumericIdentifier(patch.description, position: .patch, errorKind: .negativeValue)}
            self.major = major
            self.minor = minor
            self.patch = patch
            
            self.prerelease = try Prerelease(prereleaseIdentifiers)
            
            guard buildMetadataIdentifiers.allSatisfy( { !$0.isEmpty } ) else {
                throw SemanticVersionError.emptyIdentifier(position: .buildMetadata)
            }
            try buildMetadataIdentifiers.forEach {
                guard $0.allSatisfy( { $0.isASCII && ( $0.isLetter || $0.isNumber || $0 == "-" ) } ) else {
                    throw SemanticVersionError.invalidCharacterInIdentifier($0, position: .buildMetadata)
                }
            }
            self.buildMetadataIdentifiers = buildMetadataIdentifiers
        }

        /// Creates a semantic version with the provided components of a semantic version.
        /// - Parameters:
        ///   - major: The major version number.
        ///   - minor: The minor version number.
        ///   - patch: The patch version number.
        ///   - prerelease: The dot-separated pre-release identifiers; `nil` if the version is not a pre-release.
        ///   - buildMetadata: The dot-separated build metadata identifiers; `nil` if build metadata is absent.
        @available(*, deprecated, renamed: "init(_:_:_:prereleaseIdentifiers:buildMetadataIdentifiers:)")
        public init(major: Int, minor: Int, patch: Int, prerelease: String? = nil, buildMetadata: String? = nil) {
            try! self.init(
                major, minor, patch,
                prereleaseIdentifiers: prerelease?
                    .split(separator: ".", omittingEmptySubsequences: false)
                    .map { String($0) } ?? [],
                buildMetadataIdentifiers: buildMetadata?
                    .split(separator: ".", omittingEmptySubsequences: false)
                    .map { String($0) } ?? []
            )
        }
    }
}

// MARK: - Inspecting a Semantic Version

extension SymbolGraph.SemanticVersion {
    /// A Boolean value indicating whether the version is a pre-release version.
    public var isPrerelease: Bool { !prerelease.identifiers.isEmpty }
}

// MARK: -

extension SymbolGraph.SemanticVersion: Codable {
    /// Keys for encoding and decoding `SemanticVersion` properties.
    internal enum CodingKeys: String, CodingKey {
        /// The major version number.
        case major
        /// The minor version number.
        case minor
        /// The patch version number.
        case patch
        /// The dot-separated pre-release identifiers.
        case prerelease
        /// The dot-separated build metadata identifiers.
        case buildMetadata
    }
    
    /// Creates a semantic version by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.major = try container.decode(Int.self, forKey: .major)
        guard major >= 0 else { throw SymbolGraph.SemanticVersionError.invalidNumericIdentifier(major.description, position: .major, errorKind: .negativeValue)}
        self.minor = try container.decodeIfPresent(Int.self, forKey: .minor) ?? 0
        guard minor >= 0 else { throw SymbolGraph.SemanticVersionError.invalidNumericIdentifier(minor.description, position: .minor, errorKind: .negativeValue)}
        self.patch = try container.decodeIfPresent(Int.self, forKey: .patch) ?? 0
        guard patch >= 0 else { throw SymbolGraph.SemanticVersionError.invalidNumericIdentifier(patch.description, position: .patch, errorKind: .negativeValue)}
        
        self.prerelease = try Prerelease(try container.decodeIfPresent(String.self, forKey: .prerelease))
        
        self.buildMetadataIdentifiers = try container.decodeIfPresent(String.self, forKey: .buildMetadata)?
            .split(separator: ".", omittingEmptySubsequences: false)
            .map { String($0) } ?? []
        guard !buildMetadataIdentifiers.allSatisfy(\.isEmpty) else {
            throw SymbolGraph.SemanticVersionError.emptyIdentifier(position: .buildMetadata)
        }
        try buildMetadataIdentifiers.forEach { identifier in
            guard identifier.isSemanticVersionBuildMetadataIdentifier else {
                throw SymbolGraph.SemanticVersionError.invalidCharacterInIdentifier(String(identifier), position: .buildMetadata)
            }
        }
    }
    
    /// Encodes the semantic version into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(major, forKey: .major)
        try container.encode(minor, forKey: .minor)
        try container.encode(patch, forKey: .patch)
        if isPrerelease {
            try container.encode(prerelease.description, forKey: .prerelease)
        }
        if !buildMetadataIdentifiers.isEmpty {
            try container.encode(buildMetadataIdentifiers.joined(separator: "."), forKey: .buildMetadata)
        }
    }
    
}

extension SymbolGraph.SemanticVersion: Comparable {
    // Although `Comparable` inherits from `Equatable`, it does not provide a new default implementation of `==`, but instead uses `Equatable`'s default synthesised implementation. The compiler-synthesised `==`` is composed of [member-wise comparisons](https://github.com/apple/swift-evolution/blob/main/proposals/0185-synthesize-equatable-hashable.md#implementation-details), which leads to a false `false` when 2 semantic versions differ by only their build metadata identifiers, contradicting SemVer 2.0.0's [comparison rules](https://semver.org/#spec-item-10).
    /// <#Description#>
    /// - Parameters:
    ///   - lhs: <#lhs description#>
    ///   - rhs: <#rhs description#>
    /// - Returns: <#description#>
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        !(lhs < rhs) && !(lhs > rhs)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - lhs: <#lhs description#>
    ///   - rhs: <#rhs description#>
    /// - Returns: <#description#>
    public static func < (lhs: Self, rhs: Self) -> Bool {
        let lhsVersionCore = [lhs.major, lhs.minor, lhs.patch]
        let rhsVersionCore = [rhs.major, rhs.minor, rhs.patch]
        
        guard lhsVersionCore == rhsVersionCore else {
            return lhsVersionCore.lexicographicallyPrecedes(rhsVersionCore)
        }
        
        return lhs.prerelease < rhs.prerelease // not lexicographically compared
    }
}

extension SymbolGraph.SemanticVersion: CustomStringConvertible {
    /// A textual description of the `Semantic Version` instance.
    public var description: String {
        var versionString = "\(major).\(minor).\(patch)"
        if !prerelease.identifiers.isEmpty {
            versionString += "-\(prerelease)"
        }
        if !buildMetadataIdentifiers.isEmpty {
            versionString += "+" + buildMetadataIdentifiers.joined(separator: ".")
        }
        return versionString
    }
}

extension SymbolGraph.SemanticVersion: LosslessStringConvertible {
    /// Initializes a version struct with the provided version string.
    /// - Parameter version: A version string to use for creating a new version struct.
    public init?(_ versionString: String) {
        let metadataDelimiterIndex = versionString.firstIndex(of: "+")
        // SemVer 2.0.0 requires that pre-release identifiers come before build metadata identifiers
        let prereleaseDelimiterIndex = versionString[..<(metadataDelimiterIndex ?? versionString.endIndex)].firstIndex(of: "-")
        
        let versionCore = versionString[..<(prereleaseDelimiterIndex ?? metadataDelimiterIndex ?? versionString.endIndex)]
        let versionCoreIdentifiers = versionCore.split(separator: ".", omittingEmptySubsequences: false)
        
        guard
            versionCoreIdentifiers.count == 3,
            let major = validNumericIdentifier(versionCoreIdentifiers[0]),
            let minor = validNumericIdentifier(versionCoreIdentifiers[1]),
            let patch = validNumericIdentifier(versionCoreIdentifiers[2])
        else { return nil }
        
        self.major = major
        self.minor = minor
        self.patch = patch
        
        if let prereleaseDelimiterIndex = prereleaseDelimiterIndex {
            let prereleaseStartIndex = versionString.index(after: prereleaseDelimiterIndex)
            let prereleaseIdentifiers = versionString[prereleaseStartIndex..<(metadataDelimiterIndex ?? versionString.endIndex)].split(separator: ".", omittingEmptySubsequences: false)
            guard let prerelease = try? Prerelease(prereleaseIdentifiers) else {
                return nil
            }
            self.prerelease = prerelease
        } else {
            self.prerelease = Prerelease(identifiers: []) // This is the member-wise initializer taking `[Identifier]` not `[S: StringProtocol]`.
        }
        
        if let metadataDelimiterIndex = metadataDelimiterIndex {
            let metadataStartIndex = versionString.index(after: metadataDelimiterIndex)
            let buildMetadataIdentifiers = versionString[metadataStartIndex...].split(separator: ".", omittingEmptySubsequences: false)
            guard buildMetadataIdentifiers.allSatisfy(\.isSemanticVersionBuildMetadataIdentifier) else {
                return nil
            }
            self.buildMetadataIdentifiers = buildMetadataIdentifiers.map { String($0) }
        } else {
            self.buildMetadataIdentifiers = []
        }
        
        /// Creates an integer-represented numeric identifier from the given identifier.
        ///
        /// Semantic Versioning 2.0.0 requires valid numeric identifiers to be "0" or ASCII digit sequence without leading "0"s.
        ///
        /// - Parameter identifier: The given identifier.
        /// - Returns: The integer representation of the identifier, if the identifier is a valid Semantic Versioning 2.0.0 numeric identifier, and if it is representable by `Int`; `nil` otherwise.
        func validNumericIdentifier(_ identifier: Substring) -> Int? {
            // Converting each identifier from a substring to a signed integer doubles as asserting that the identifier is non-empty and that it has no non-ASCII-numeric characters other than an optional leading "+" or "-".
            // `Int` is used here instead of `UInt`, because `Int` is a currency type, and because even with `UInt`, the literal '-0' and its leading-zeros variants can still slip through.
            guard let numericIdentifier = Int(identifier) else {
                return nil
            }
            // Although `Int.init<S: StringProtocol>(_:)` accepts a leading "+" in the argument, we don't need to be check for it here. "+" is the delimiter between pre-release and build metadata, and build metadata does not care for the validity of numeric identifiers.
            guard identifier == "0" || (identifier.first != "-" && identifier.first != "0") else {
                return nil
            }
            return numericIdentifier
        }
    }
}

extension Character {
    /// <#Description#>
    internal var isSemanticVersionIdentifierCharacter: Bool {
        isASCII && ( isLetter || isNumber || self == "-" )
    }
    
    /// <#Description#>
    internal var isSemanticVersionNumericIdentifierCharacter: Bool {
        isASCII && isNumber
    }
}

extension StringProtocol {
    /// <#Description#>
    internal var isSemanticVersionNumericIdentifier: Bool {
        self == "0" || (first != "0" && allSatisfy(\.isSemanticVersionNumericIdentifierCharacter) && !isEmpty)
    }
    
    /// <#Description#>
    internal var isSemanticVersionAlphanumericIdentifier: Bool {
        allSatisfy(\.isSemanticVersionIdentifierCharacter) && !allSatisfy(\.isSemanticVersionNumericIdentifierCharacter) && !isEmpty
    }
    
    /// <#Description#>
    internal var isSemanticVersionBuildMetadataIdentifier: Bool {
        allSatisfy(\.isSemanticVersionIdentifierCharacter) && !isEmpty
    }
}
