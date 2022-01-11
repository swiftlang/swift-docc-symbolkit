/*
 This source file is part of the Swift.org open source project
 
 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception
 
 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
 */

extension SymbolGraph {
	/// An error that occurs during the creation of a semantic version.
	public enum SemanticVersionError: Error, CustomStringConvertible {
		/// The identifier at the given position is empty.
		/// - Parameter position: The empty identifier's position in the semantic version.
		case emptyIdentifier(position: IdentifierPosition)
		/// The identifier at the given position contains invalid character(s).
		/// - Parameters:
		///   - identifier: The identifier that contains invalid character(s).
		///   - position: The given identifier's position in the semantic version.
		case invalidCharacterInIdentifier(_ identifier: String, position: IdentifierPosition)
		/// The numeric identifier at the given position is invalid for the given reason.
		/// - Parameters:
		///   - identifier: The invalid numeric identifier.
		///   - position: The given numeric identifier's position in the semantic version.
		///   - errorKind: The reason why the given numeric identifier is invalid.
		case invalidNumericIdentifier(_ identifier: String, position: NumericIdentifierPosition, errorKind: NumericIdentifierErrorKind)
		/// The version core contains an invalid number of Identifiers.
		/// - Parameter identifiers: The version core identifiers in the version string.
		case invalidVersionCoreIdentifierCount(identifiers: [String])
		
		/// A position of an identifier in a semantic version.
		public enum IdentifierPosition: String, CustomStringConvertible {
			/// The major version number position in a semantic version.
			case major
			/// The minor version number position in a semantic version.
			case minor
			/// The patch version number position in a semantic version.
			case patch
			/// The pre-release position in a semantic version.
			case prerelease
			/// The build-metadata position in a semantic version.
			case buildMetadata
			
			/// <#Description#>
			public var description: String {
				self.rawValue
			}
		}
		
		/// A position of a numeric identifier in a semantic version.
		public enum NumericIdentifierPosition: String, CustomStringConvertible {
			/// The major version number position.
			case major
			/// The minor version number position.
			case minor
			/// The patch version number position.
			case patch
			/// The pre-release position.
			case prerelease
			
			/// <#Description#>
			public var description: String {
				self.rawValue
			}
		}
		
		/// A reason why a numeric identifier is invalid.
		public enum NumericIdentifierErrorKind {
			/// The numeric identifier contains leading "0" characters.
			case leadingZeros
			/// The numeric identifier represents a negative value.
			case negativeValue
			/// The numeric identifier contains non-numeric characters.
			case nonNumericCharacter
		}
		
		// this description follows [the "grammar and phrasing" section of Swift's diagnostics guidelines](https://github.com/apple/swift/blob/d1bb98b11ede375a1cee739f964b7d23b6657aaf/docs/Diagnostics.md#grammar-and-phrasing)
		/// <#Description#>
		public var description: String {
			switch self {
			case let .emptyIdentifier(position):
				return "semantic version \(position) identifier cannot be empty"
			case let .invalidCharacterInIdentifier(identifier, position):
				return "semantic version \(position) identifier '\(identifier)' cannot conatin characters other than ASCII alphanumerics and hyphen-minus ([0-9A-Za-z-])"
			case let .invalidNumericIdentifier(identifier, position, errorKind):
				let fault: String
				switch errorKind {
				case .leadingZeros:
					fault = "contain leading '0'"
				case .negativeValue:
					fault = "represent negative value"
				case .nonNumericCharacter:
					fault = "conatin non-numeric characters"
				}
				return "semantic version numeric \(position) identifier '\(identifier)' cannot \(fault)"
			case let .invalidVersionCoreIdentifierCount(identifiers):
				return """
					semantic version must conatins exactly 3 version core identifiers; \
					\(identifiers.count) given\(identifiers.isEmpty ? "" : " : ")\
					\(identifiers.map { "'\($0)'" } .joined(separator: ", "))
					"""
			}
		}
	}
}
