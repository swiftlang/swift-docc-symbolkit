/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol {
    /**
     A unique identifier of a symbol's kind, such as a structure or protocol.
     */
    public struct KindIdentifier: Equatable, Hashable, Codable {
        public let identifier: String

        private init(rawIdentifier: String) {
            self.identifier = rawIdentifier
        }

        public static let `associatedtype`  = KindIdentifier(rawIdentifier: "associatedtype")
        public static let `class`           = KindIdentifier(rawIdentifier: "class")
        public static let `deinit`          = KindIdentifier(rawIdentifier: "deinit")
        public static let `enum`            = KindIdentifier(rawIdentifier: "enum")
        public static let `case`            = KindIdentifier(rawIdentifier: "enum.case")
        public static let `func`            = KindIdentifier(rawIdentifier: "func")
        public static let `operator`        = KindIdentifier(rawIdentifier: "func.op")
        public static let `init`            = KindIdentifier(rawIdentifier: "init")
        public static let `method`          = KindIdentifier(rawIdentifier: "method")
        public static let `property`        = KindIdentifier(rawIdentifier: "property")
        public static let `protocol`        = KindIdentifier(rawIdentifier: "protocol")
        public static let snippet           = KindIdentifier(rawIdentifier: "snippet")
        public static let snippetGroup      = KindIdentifier(rawIdentifier: "snippetGroup")
        public static let `struct`          = KindIdentifier(rawIdentifier: "struct")
        public static let `subscript`       = KindIdentifier(rawIdentifier: "subscript")
        public static let typeMethod        = KindIdentifier(rawIdentifier: "type.method")
        public static let typeProperty      = KindIdentifier(rawIdentifier: "type.property")
        public static let typeSubscript     = KindIdentifier(rawIdentifier: "type.subscript")
        public static let `typealias`       = KindIdentifier(rawIdentifier: "typealias")
        public static let `var`             = KindIdentifier(rawIdentifier: "var")
        public static let module            = KindIdentifier(rawIdentifier: "module")

        public static let allCases: [KindIdentifier] = [
          .`associatedtype`,
          .`class`,
          .`deinit`,
          .`enum`,
          .`case`,
          .`func`,
          .`operator`,
          .`init`,
          .`method`,
          .`property`,
          .`protocol`,
          .snippet,
          .snippetGroup,
          .`struct`,
          .`subscript`,
          .`typeMethod`,
          .`typeProperty`,
          .`typeSubscript`,
          .`typealias`,
          .`var`,
          .`module`
      ]

        /// Check the given identifier string against the list of known identifiers.
        ///
        /// - Parameter identifier: The identifier string to check.
        /// - Returns: The matching `KindIdentifier` case, or `nil` if there was no match.
        private static func lookupIdentifier(identifier: String) -> KindIdentifier? {
            switch identifier {
            case "associatedtype": return .associatedtype
            case "class": return .class
            case "deinit": return .deinit
            case "enum": return .enum
            case "enum.case": return .case
            case "func": return .func
            case "func.op": return .operator
            case "init": return .`init`
            case "method": return .method
            case "property": return .property
            case "protocol": return .protocol
            case "snippet": return .snippet
            case "snippetGroup": return .snippetGroup
            case "struct": return .struct
            case "subscript": return .subscript
            case "type.method": return .typeMethod
            case "type.property": return .typeProperty
            case "type.subscript": return .typeSubscript
            case "typealias": return .typealias
            case "var": return .var
            case "module": return .module
            default: return nil
            }
        }

        /// Compares the given identifier against the known default symbol kinds, and returns whether it matches one.
        ///
        /// The identifier will also be checked without its first component, so that (for example) `"swift.func"`
        /// will be treated the same as just `"func"`, and match `.func`.
        ///
        /// - Parameter identifier: The identifier string to compare.
        /// - Returns: `true` if the given identifier matches a known symbol kind; otherwise `false`.
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
        public init(identifier: String) {
            // Check if the identifier matches a symbol kind directly.
            if let firstParse = Self.lookupIdentifier(identifier: identifier) {
                self = firstParse
            } else {
                // For symbol graphs which include a language identifier with their symbol kinds
                // (e.g. "swift.func" instead of just "func"), strip off the language prefix and
                // try again.
                let cleanIdentifier = KindIdentifier.cleanIdentifier(identifier)
                if let secondParse = Self.lookupIdentifier(identifier: cleanIdentifier) {
                    self = secondParse
                } else {
                    // If we still don't have a match, store the whole original string.
                    self = .init(rawIdentifier: identifier)
                }
            }
        }

        public init(from decoder: Decoder) throws {
            let identifier = try decoder.singleValueContainer().decode(String.self)
            self = KindIdentifier(identifier: identifier)
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
    }
}
