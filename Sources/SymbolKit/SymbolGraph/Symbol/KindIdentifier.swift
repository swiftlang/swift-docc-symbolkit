/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021-2024 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol {
    /**
     A unique identifier of a symbol's kind, such as a structure or protocol.
     */
    public struct KindIdentifier: Equatable, Hashable, Codable, CaseIterable {
        private var rawValue: String
        
        /// Create a new ``SymbolGraph/Symbol/KindIdentifier``.
        ///
        /// - Note: Only use this initializer for defining a new kind. For initializing instances manually,
        /// copy the initial initializer. For extracting identifiers form raw strings, use ``init(identifier:)``.
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
      
        public static let `associatedtype` = KindIdentifier(rawValue: "associatedtype")
        
        public static let `class` = KindIdentifier(rawValue: "class")
        
        public static let `deinit` = KindIdentifier(rawValue: "deinit")
        
        public static let `enum` = KindIdentifier(rawValue: "enum")
        
        public static let `case` = KindIdentifier(rawValue: "enum.case")
        
        public static let `func` = KindIdentifier(rawValue: "func")
        
        public static let `operator` = KindIdentifier(rawValue: "func.op")
        
        public static let `init` = KindIdentifier(rawValue: "init")
        
        public static let ivar = KindIdentifier(rawValue: "ivar")
        
        public static let macro = KindIdentifier(rawValue: "macro")
        
        public static let method = KindIdentifier(rawValue: "method")

        public static let namespace = KindIdentifier(rawValue: "namespace")

        public static let property = KindIdentifier(rawValue: "property")
        
        public static let `protocol` = KindIdentifier(rawValue: "protocol")
        
        public static let snippet = KindIdentifier(rawValue: "snippet")
        
        public static let snippetGroup = KindIdentifier(rawValue: "snippetGroup")
        
        public static let `struct` = KindIdentifier(rawValue: "struct")
        
        public static let `subscript` = KindIdentifier(rawValue: "subscript")
        
        public static let typeMethod = KindIdentifier(rawValue: "type.method")
        
        public static let typeProperty = KindIdentifier(rawValue: "type.property")
        
        public static let typeSubscript = KindIdentifier(rawValue: "type.subscript")
        
        public static let `typealias` = KindIdentifier(rawValue: "typealias")

        public static let union = KindIdentifier(rawValue: "union")

        public static let `var` = KindIdentifier(rawValue: "var")
        
        public static let module = KindIdentifier(rawValue: "module")
        
        public static let `extension` = KindIdentifier(rawValue: "extension")
        
        public static let dictionary = KindIdentifier(rawValue: "dictionary")

        public static let dictionaryKey = KindIdentifier(rawValue: "dictionaryKey")

        public static let httpRequest = KindIdentifier(rawValue: "httpRequest")

        public static let httpParameter = KindIdentifier(rawValue: "httpParameter")

        public static let httpResponse = KindIdentifier(rawValue: "httpResponse")

        public static let httpBody = KindIdentifier(rawValue: "httpBody")

        /// A string that uniquely identifies the symbol kind.
        ///
        /// If the original kind string was not recognized, this will return `"unknown"`.
        public var identifier: String {
            rawValue
        }
        
        public static var allCases: Dictionary<String, Self>.Values {
            _allCases.values
        }
        
        private static var _allCases: [String: Self] = [
            Self.associatedtype.rawValue: .associatedtype,
            Self.class.rawValue: .class,
            Self.deinit.rawValue: .deinit,
            Self.enum.rawValue: .enum,
            Self.case.rawValue: .case,
            Self.func.rawValue: .func,
            Self.operator.rawValue: .operator,
            Self.`init`.rawValue: .`init`,
            Self.ivar.rawValue: .ivar,
            Self.macro.rawValue: .macro,
            Self.method.rawValue: .method,
            Self.namespace.rawValue: .namespace,
            Self.property.rawValue: .property,
            Self.protocol.rawValue: .protocol,
            Self.snippet.rawValue: .snippet,
            Self.snippetGroup.rawValue: .snippetGroup,
            Self.struct.rawValue: .struct,
            Self.subscript.rawValue: .subscript,
            Self.typeMethod.rawValue: .typeMethod,
            Self.typeProperty.rawValue: .typeProperty,
            Self.typeSubscript.rawValue: .typeSubscript,
            Self.typealias.rawValue: .typealias,
            Self.union.rawValue: .union,
            Self.var.rawValue: .var,
            Self.module.rawValue: .module,
            Self.extension.rawValue: .extension,
            Self.dictionary.rawValue: .dictionary,
            Self.dictionaryKey.rawValue: .dictionaryKey,
            Self.httpRequest.rawValue: .httpRequest,
            Self.httpParameter.rawValue: .httpParameter,
            Self.httpResponse.rawValue: .httpResponse,
            Self.httpBody.rawValue: .httpBody,
        ]
        
        /// Register custom ``SymbolGraph/Symbol/KindIdentifier``s so they can be parsed correctly and
        /// appear in ``allCases``.
        ///
        /// If a type is not registered, language prefixes cannot be removed correctly.
        ///
        /// - Note: When working in an uncontrolled environment where other parts of your executable might be disturbed by your
        /// modifications to the symbol graph structure or might be registering identifiers concurrently, register identifiers on your
        /// coder instead using ``register(_:to:)`` and maintain your own list of ``allCases``.
        public static func register(_ identifiers: Self...) {
            for identifier in identifiers {
                _allCases[identifier.rawValue] = identifier
            }
        }

        /// Check the given identifier string against the list of known identifiers.
        ///
        /// - Parameter identifier: The identifier string to check.
        /// - Parameter extensionCases: A set of custom identifiers to be considered in this lookup.
        /// - Returns: The matching `KindIdentifier` case, or `nil` if there was no match.
        private static func lookupIdentifier(identifier: String, using extensionCases: [String: Self]? = nil) -> KindIdentifier? {
            _allCases[identifier] ?? extensionCases?[identifier]
        }

        /// Compares the given identifier against the known default symbol kinds, and returns whether it matches one.
        ///
        /// The identifier will also be checked without its first component, so that (for example) `"swift.func"`
        /// will be treated the same as just `"func"`, and match `.func`.
        ///
        /// - Parameter identifier: The identifier string to compare.
        /// - Returns: `true` if the given identifier matches a known symbol kind; otherwise `false`.
        ///
        /// - Note: This initializer does only recognize custom identifiers if they were registered previously using
        /// ``register(_:)``.
        public static func isKnownIdentifier(_ identifier: String) -> Bool {
            var kind: KindIdentifier?

            if let cachedDetail = Self.lookupIdentifier(identifier: identifier) {
                kind = cachedDetail
            } else {
                let cleanIdentifier = KindIdentifier.cleanIdentifier(identifier)
                kind = Self.lookupIdentifier(identifier: cleanIdentifier)
            }

            return kind != nil
        }

        /// Parses the given identifier to return a matching symbol kind.
        ///
        /// The identifier will also be checked without its first component, so that (for example) `"swift.func"`
        /// will be treated the same as just `"func"`, and match `.func`.
        ///
        /// - Parameter identifier: The identifier string to parse.
        ///
        /// - Note: This initializer does only recognize custom identifiers if they were registered previously using
        /// ``register(_:)``.
        public init(identifier: String) {
            self.init(identifier: identifier, using: nil)
        }
        
        private init(identifier: String, using extensionCases: [String: Self]?) {
            // Check if the identifier matches a symbol kind directly.
            if let firstParse = Self.lookupIdentifier(identifier: identifier, using: extensionCases) {
                self = firstParse
            } else {
                // For symbol graphs which include a language identifier with their symbol kinds
                // (e.g. "swift.func" instead of just "func"), strip off the language prefix and
                // try again.
                let cleanIdentifier = KindIdentifier.cleanIdentifier(identifier)
                if let secondParse = Self.lookupIdentifier(identifier: cleanIdentifier, using: extensionCases) {
                    self = secondParse
                } else {
                    // If that doesn't help either, use the original identifier as a raw value.
                    self = Self.init(rawValue: identifier)
                }
            }
        }

        public init(from decoder: Decoder) throws {
            let identifier = try decoder.singleValueContainer().decode(String.self)
            self = KindIdentifier(identifier: identifier, using: decoder.registeredSymbolKindIdentifiers)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(identifier)
        }

        /// Strips the first component of the given identifier string, so that (for example) `"swift.func"` will return `"func"`.
        ///
        /// Symbol graphs may store symbol kinds as either bare identifiers (e.g. `"class"`, `"enum"`, etc), or as identifiers
        /// prefixed with the language identifier (e.g. `"swift.func"`, `"objc.method"`, etc). This method allows us to
        /// treat the language-prefixed symbol kinds as equivalent to the "bare" symbol kinds.
        ///
        /// - Parameter identifier: An identifier string to clean.
        /// - Returns: A new identifier string without its first component, or the original identifier if there was only one component.
        private static func cleanIdentifier(_ identifier: String) -> String {
            // FIXME: Take an "expected" language identifier instead of universally dropping the first component? (rdar://84276085)
            if let periodIndex = identifier.firstIndex(of: ".") {
                return String(identifier[identifier.index(after: periodIndex)...])
            }
            return identifier
        }

        /// Whether the kind supports grouping as overloads.
        public var isOverloadableKind: Bool {
            switch self {
            case .method,
                 .typeMethod,
                 .`func`,
                 .`init`,
                 .macro,
                 .subscript,
                 .typeSubscript,
                 .`operator`:
                return true
            default:
                return false
            }
        }
    }
}

extension SymbolGraph.Symbol.KindIdentifier {
    /// Register custom ``SymbolGraph/Symbol/KindIdentifier``s so they can be parsed correctly while
    /// decoding symbols in an uncontrolled environment.
    ///
    /// If a type is not registered, language prefixes cannot be removed correctly.
    ///
    /// - Note: Registering custom identifiers on your decoder is only necessary when working in an uncontrolled environment where
    /// other parts of your executable might be disturbed by your modifications to the symbol graph structure. If that is not the case, use
    /// ``SymbolGraph/Symbol/KindIdentifier/register(_:)``.
    ///
    /// - Parameter userInfo: A property which allows editing the `userInfo` member of the
    /// `Decoder` protocol.
    public static func register<I: Sequence>(_ identifiers: I,
                                             to userInfo: inout [CodingUserInfoKey: Any]) where I.Element == Self {
        var registeredIdentifiers = userInfo[.symbolKindIdentifierKey] as? [String: SymbolGraph.Symbol.KindIdentifier] ?? [:]
            
        for identifier in identifiers {
            registeredIdentifiers[identifier.identifier] = identifier
        }
        
        userInfo[.symbolKindIdentifierKey] = registeredIdentifiers
    }
}

public extension JSONDecoder {
    /// Register custom ``SymbolGraph/Symbol/KindIdentifier``s so they can be parsed correctly while
    /// decoding symbols in an uncontrolled environment.
    ///
    /// If a type is not registered, language prefixes cannot be removed correctly.
    ///
    /// - Note: Registering custom identifiers on your decoder is only necessary when working in an uncontrolled environment where
    /// other parts of your executable might be disturbed by your modifications to the symbol graph structure. If that is not the case, use
    /// ``SymbolGraph/Symbol/KindIdentifier/register(_:)``.
    func register(symbolKinds identifiers: SymbolGraph.Symbol.KindIdentifier...) {
        SymbolGraph.Symbol.KindIdentifier.register(identifiers, to: &self.userInfo)
    }
}

extension Decoder {
    var registeredSymbolKindIdentifiers: [String: SymbolGraph.Symbol.KindIdentifier]? {
        self.userInfo[.symbolKindIdentifierKey] as? [String: SymbolGraph.Symbol.KindIdentifier]
    }
}

extension CodingUserInfoKey {
    static let symbolKindIdentifierKey = CodingUserInfoKey(rawValue: "org.swift.symbolkit.symbolKindIdentifierKey")!
}
