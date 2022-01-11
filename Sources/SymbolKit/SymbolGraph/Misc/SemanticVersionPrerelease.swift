/*
 This source file is part of the Swift.org open source project
 
 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception
 
 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
 */

extension SymbolGraph.SemanticVersion {
	/// A storage for pre-release identifiers.
	internal struct Prerelease {
		/// The identifiers.
		internal let identifiers: [Identifier]
		/// A pre-release identifier.
		internal enum Identifier {
			/// A numeric pre-release identifier.
			/// - Parameter identifier: The identifier.
			case numeric(_ identifier: Int)
			/// An alphanumeric pre-release identifier.
			/// - Parameter identifier: The identifier.
			case alphanumeric(_ identifier: String)
		}
	}
}

// MARK: - Initializers

extension SymbolGraph.SemanticVersion.Prerelease {
	/// <#Description#>
	///
	/// - Note: Empty string translates to an empty pre-release identifier, which is invalid.
	/// - Parameter dotSeparatedIdentifiers: <#dotSeparatedIdentifiers description#>
	internal init(_ dotSeparatedIdentifiers: String?) throws {
		guard let dotSeparatedIdentifiers = dotSeparatedIdentifiers else {
			// FIXME: initialize 'identifiers' directly here after [SR-15670](https://bugs.swift.org/projects/SR/issues/SR-15670?filter=allopenissues) is resolved
			// currently 'identifiers' cannot be initialized directly because initializer delegation is flow-insensitive
			// self.identifiers = []
			self.init(identifiers: [])
			return
		}
		let identifiers = dotSeparatedIdentifiers.split(
			separator: ".",
			omittingEmptySubsequences: false // must preserve empty identifiers
		)
		try self.init(identifiers)
	}
	
	/// <#Description#>
	internal init<C: Collection, S: StringProtocol>(_ identifiers: C) throws where C.Element == S {
		self.identifiers = try identifiers.map {
			try Identifier($0)
		}
	}
}

extension SymbolGraph.SemanticVersion.Prerelease.Identifier {
	/// <#Description#>
	internal init<S: StringProtocol>(_ identifier: S) throws {
		guard !identifier.isEmpty else {
			throw SymbolGraph.SemanticVersionError.emptyIdentifier(position: .prerelease)
		}
		guard identifier.allSatisfy(\.isSemanticVersionIdentifierCharacter) else {
			throw SymbolGraph.SemanticVersionError.invalidCharacterInIdentifier(String(identifier), position: .prerelease)
		}
		if identifier.allSatisfy(\.isNumber) {
			// diagnose the identifier as a numeric identifier, if all characters are ASCII digits
			guard identifier.first != "0" || identifier == "0" else {
				throw SymbolGraph.SemanticVersionError.invalidNumericIdentifier(String(identifier), position: .prerelease, errorKind: .leadingZeros)
			}
			self = .numeric(Int(identifier)!)
		} else {
			self = .alphanumeric(String(identifier))
		}
	}
}

// MARK: - Comparable Conformances

// Compiler synthesised `Equatable`-conformance is correct here.
extension SymbolGraph.SemanticVersion.Prerelease: Comparable {
	/// <#Description#>
	/// - Parameters:
	///   - lhs: <#lhs description#>
	///   - rhs: <#rhs description#>
	/// - Returns: <#description#>
	internal static func <(lhs: Self, rhs: Self) -> Bool {
		guard !lhs.identifiers.isEmpty else { return false } // non-pre-release lhs >= potentially pre-release rhs
		guard !rhs.identifiers.isEmpty else { return true } // pre-release lhs < non-pre-release rhs
		return lhs.identifiers.lexicographicallyPrecedes(rhs.identifiers)
	}
}

// Compiler synthesised `Equatable`-conformance is correct here.
extension SymbolGraph.SemanticVersion.Prerelease.Identifier: Comparable {
	/// <#Description#>
	/// - Parameters:
	///   - lhs: <#lhs description#>
	///   - rhs: <#rhs description#>
	/// - Returns: <#description#>
	internal static func <(lhs: Self, rhs: Self) -> Bool {
		switch (lhs, rhs) {
		case let (.numeric(lhs), .numeric(rhs)):
			return lhs < rhs
		case let(.alphanumeric(lhs), .alphanumeric(rhs)):
			return lhs < rhs
		case (.numeric, .alphanumeric):
			return true
		case (.alphanumeric, .numeric):
			return false
		}
	}
}

// MARK: CustomStringConvertible Conformances

extension SymbolGraph.SemanticVersion.Prerelease: CustomStringConvertible {
	/// <#Description#>
	internal var description: String {
		identifiers.map(\.description).joined(separator: ".")
	}
}

extension SymbolGraph.SemanticVersion.Prerelease.Identifier: CustomStringConvertible {
	/// <#Description#>
	internal var description: String {
		switch self {
		case .numeric(let identifier):
			return identifier.description
		case .alphanumeric(let identifier):
			return identifier.description
		}
	}
}
