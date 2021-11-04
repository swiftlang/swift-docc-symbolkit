/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

extension SymbolGraph {

    /**
     A symbol from a module.

     A `Symbol` corresponds to some named declaration in a module.
     For example, a class is a `Symbol` in the graph.

     A `Symbol` should never contain another `Symbol` as a field or part of a field.
     If a symbol is related to another symbol, it should be formalized
     as a `Relationship` in an `Edge` if possible (it usually is).

     Symbols may have information that is specific to its kind, but all symbols
     must contain at least the following information in the `Symbol` interface.

     In addition, various attributes of the symbol should be mixed in with
     symbol *mix-ins*, some of which are defined below.
     The consumer of a symbol graph should be able to dynamically handle or ignore
     additional attributes in a `Symbol`.
     */
    public struct Symbol: Codable {
        /// The unique identifier for the symbol.
        public var identifier: Identifier

        /// The kind of symbol.
        public var kind: Kind

        /**
         A short convenience path that uniquely identifies a symbol when there are no ambiguities using only URL-compatible characters. Do not include the module name here.

         For example, in a Swift module `MyModule`, there might exist a function `bar` in `struct Foo`.
         The `simpleComponents` for `bar` would be `["Foo", "bar"]`, corresponding to `Foo.bar`.

         > Note: When writing relative links, an author may choose to remove leading components, so disambiguating path components should only be appended to the end, not prepended to the beginning.
         */
        public var pathComponents: [String]

        /// If the static type of a symbol is known, the precise identifier of
        /// the symbol that declares the type.
        public var type: String?

        /// The context-specific names of a symbol.
        public var names: Names

        /// The in-source documentation comment attached to a symbol.
        public var docComment: LineList?
        
        /// If the symbol has a documentation comment, whether the documentation comment is from
        /// the same module as the symbol or not.
        ///
        /// An inherited documentation comment is from the same module when the symbol that the documentation is inherited from is in the same module as this symbol.
        public var isDocCommentFromSameModule: Bool? {
            guard let docComment = docComment, !docComment.lines.isEmpty else {
                return nil
            }
            
            // As a current implementation detail, documentation comments from within the current module has range information but
            // documentation comments that are inherited from other modules don't have any range information.
            //
            // It would be better for correctness and accuracy to determine this when extracting the symbol information (rdar://81190369)
            return docComment.lines.contains(where: { $0.range != nil })
        }

        /// The access level of the symbol.
        public var accessLevel: AccessControl

        /// Information about a symbol that is not necessarily common to all symbols.
        public var mixins: [String: Mixin] = [:]

        public init(identifier: Identifier, names: Names, pathComponents: [String], docComment: LineList?, accessLevel: AccessControl, kind: Kind, mixins: [String: Mixin]) {
            self.identifier = identifier
            self.names = names
            self.pathComponents = pathComponents
            self.docComment = docComment
            self.accessLevel = accessLevel
            self.kind = kind
            self.mixins = mixins
        }

        enum CodingKeys: String, Hashable, CaseIterable, CodingKey {
            // Base
            case identifier
            case kind
            case pathComponents
            case type
            case names
            case docComment
            case accessLevel

            // Mixins
            case availability
            case declarationFragments
            case isReadOnly
            case swiftExtension
            case swiftGenerics
            case location
            case functionSignature
            case spi

            static var mixinKeys: Set<CodingKeys> {
                return [
                    .availability,
                    .declarationFragments,
                    .isReadOnly,
                    .swiftExtension,
                    .swiftGenerics,
                    .location,
                    .functionSignature,
                    .spi
                ]
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            identifier = try container.decode(Identifier.self, forKey: .identifier)
            kind = try container.decode(Kind.self, forKey: .kind)
            pathComponents = try container.decode([String].self, forKey: .pathComponents)
            type = try container.decodeIfPresent(String.self, forKey: .type)
            names = try container.decode(Names.self, forKey: .names)
            docComment = try container.decodeIfPresent(LineList.self, forKey: .docComment)
            accessLevel = try container.decode(AccessControl.self, forKey: .accessLevel)
            let leftoverMetadataKeys = Set(container.allKeys).intersection(CodingKeys.mixinKeys)
            for key in leftoverMetadataKeys {
                if let decoded = try decodeMetadataItemForKey(key, from: container) {
                    mixins[key.stringValue] = decoded
                } else {
                    // do an AnyMetadataInfo
                }
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            // Base

            try container.encode(identifier, forKey: .identifier)
            try container.encode(kind, forKey: .kind)
            try container.encode(pathComponents, forKey: .pathComponents)
            try container.encode(names, forKey: .names)
            try container.encodeIfPresent(docComment, forKey: .docComment)
            try container.encode(accessLevel, forKey: .accessLevel)

            // Mixins

            for (key, mixin) in mixins {
                let key = CodingKeys(rawValue: key)!
                switch key {
                case .availability:
                    try container.encode(mixin as! Availability, forKey: key)
                case .declarationFragments:
                    try container.encode(mixin as! DeclarationFragments, forKey: key)
                case .isReadOnly:
                    try container.encode(mixin as! Mutability, forKey: key)
                case .swiftExtension:
                    try container.encode(mixin as! Swift.Extension, forKey: key)
                case .swiftGenerics:
                    try container.encode(mixin as! Swift.Generics, forKey: key)
                case .functionSignature:
                    try container.encode(mixin as! FunctionSignature, forKey: key)
                case .spi:
                    try container.encode(mixin as! SPI, forKey: key)
                default:
                    fatalError("Unknown mixin key \(key.rawValue)!")
                }
            }
        }

        func decodeMetadataItemForKey(_ key: CodingKeys, from container: KeyedDecodingContainer<CodingKeys>) throws -> Mixin? {
            switch key.stringValue {
            case Availability.mixinKey:
                return try container.decode(Availability.self, forKey: key)
            case Location.mixinKey:
                return try container.decode(Location.self, forKey: key)
            case Mutability.mixinKey:
                return try container.decode(Mutability.self, forKey: key)
            case FunctionSignature.mixinKey:
                return try container.decode(FunctionSignature.self, forKey: key)
            case DeclarationFragments.mixinKey:
                return try container.decode(DeclarationFragments.self, forKey: key)
            case Swift.Extension.mixinKey:
                return try container.decode(Swift.Extension.self, forKey: key)
            case Swift.Generics.mixinKey:
                return try container.decode(Swift.Generics.self, forKey: key)
            case SPI.mixinKey:
                return try container.decode(SPI.self, forKey: key)
            default:
                return nil
            }
        }

        /**
         The absolute path from the module or framework to the symbol itself.
         */
        public var absolutePath: String {
            return pathComponents.joined(separator: "/")
        }
    }
}

extension SymbolGraph.Symbol {
    /// The language-agnostic access control of a symbol,
    /// such as "public", "private", "protected".
    public struct AccessControl: Codable, RawRepresentable, Hashable {
        public var rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension SymbolGraph.Symbol {
    /// Information that uniquely identifies the symbol inside the module.
    public struct Identifier: Codable, Hashable {
        /**
         A string that uniquely identifies a symbol within a module in the event of ambiguities. A precise identifier need not be human readable.
         For example, languages that use [name mangling](https://en.wikipedia.org/wiki/Name_mangling) should use this field for a mangled name.
         */
        public var precise: String

        /// The name of the language for which this symbol provides an interface, such as `swift` or `c`.
        public var interfaceLanguage: String

        public init(precise: String, interfaceLanguage: String) {
            self.precise = precise
            self.interfaceLanguage = interfaceLanguage
        }
    }
}

extension SymbolGraph.Symbol {
    /// A description of a symbol's kind, such as a structure or protocol.
    public struct Kind: Equatable, Codable {
        /// A unique identifier for this symbol's kind.
        public var identifier: KindIdentifier

        /// A display name for a kind of symbol.
        ///
        /// For example, a Swift class might use `"Class"`.
        /// This display name should not be abbreviated:
        /// for instance, use `"Structure"` instead of `"Struct"` if applicable.
        public var displayName: String

        /// Initializes a new ``SymbolGraph/Symbol/Kind-swift.struct`` with an already-parsed
        /// ``SymbolGraph/Symbol/KindIdentifier`` and display name.
        public init(parsedIdentifier: KindIdentifier, displayName: String) {
            self.identifier = parsedIdentifier
            self.displayName = displayName
        }

        /// Initializes a new ``SymbolGraph/Symbol/Kind-swift.struct`` by parsing a new
        /// ``SymbolGraph/Symbol/KindIdentifier`` from the given identifier string, and combining it
        /// with a display name.
        @available(*, deprecated, message: "Use init(rawIdentifier:displayName:) instead")
        public init(identifier: String, displayName: String) {
            self.init(rawIdentifier: identifier, displayName: displayName)
        }

        /// Initializes a new ``SymbolGraph/Symbol/Kind-swift.struct`` by parsing a new
        /// ``SymbolGraph/Symbol/KindIdentifier`` from the given identifier string, and combining it
        /// with a display name.
        public init(rawIdentifier: String, displayName: String) {
            self.identifier = KindIdentifier(identifier: rawIdentifier)
            self.displayName = displayName
        }
    }
}

extension SymbolGraph.Symbol {
    /**
     A unique identifier of a symbol's kind, such as a structure or protocol.
     */
    public enum KindIdentifier: Equatable, Hashable, Codable, CaseIterable {
        case `associatedtype`
        case `class`
        case `deinit`
        case `enum`
        case `case`
        case `func`
        case `operator`
        case `init`
        case `method`
        case `property`
        case `protocol`
        case `struct`
        case `subscript`
        case `typeMethod`
        case `typeProperty`
        case `typeSubscript`
        case `typealias`
        case `var`

        case `module`
        
        case `unknown`
        
        
        /// A string that uniquely identifies the symbol kind.
        ///
        /// If the original kind string was not recognized, this will return `"unknown"`.
        public var identifier: String {
            get {
                switch self {
                case .associatedtype : return "associatedtype"
                case .class          : return "class"
                case .deinit         : return "deinit"
                case .enum           : return "enum"
                case .case           : return "enum.case"
                case .func           : return "func"
                case .operator       : return "func.op"
                case .`init`         : return "init"
                case .method         : return "method"
                case .property       : return "property"
                case .protocol       : return "protocol"
                case .struct         : return "struct"
                case .subscript      : return "subscript"
                case .typeMethod     : return "type.method"
                case .typeProperty   : return "type.property"
                case .typeSubscript  : return "type.subscript"
                case .typealias      : return "typealias"
                case .var            : return "var"
                case .module         : return "module"
                case .unknown        : return "unknown"
                }
            }
        }

        // FIXME: Save "unknown" symbol kinds in a synchronized set to prevent loss of data (rdar://84276085)

        /// Check the given identifier string against the list of known identifiers.
        ///
        /// - Parameter identifier: The identifier string to check.
        /// - Returns: The matching `KindIdentifier` case, or `nil` if there was no match.
        private static func lookupIdentifier(identifier: String) -> KindIdentifier? {
            switch identifier {
            case "associatedtype" : return .associatedtype
            case "class"          : return .class
            case "deinit"         : return .deinit
            case "enum"           : return .enum
            case "enum.case"      : return .case
            case "func"           : return .func
            case "func.op"        : return .operator
            case "init"           : return .`init`
            case "method"         : return .method
            case "property"       : return .property
            case "protocol"       : return .protocol
            case "struct"         : return .struct
            case "subscript"      : return .subscript
            case "type.method"    : return .typeMethod
            case "type.property"  : return .typeProperty
            case "type.subscript" : return .typeSubscript
            case "typealias"      : return .typealias
            case "var"            : return .var
            case "module"         : return .module
            default               : return nil
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
            var kind: KindIdentifier? = nil

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
                self = Self.lookupIdentifier(identifier: cleanIdentifier) ?? .unknown
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

extension SymbolGraph.Symbol {
    /**
     The names of a symbol, suitable for display in various contexts.
     */
    public struct Names: Codable, Equatable {
        /**
         A name suitable for use a title on a "page" of documentation.
         */
        public var title: String

        /**
         An abbreviated form of the symbol's declaration for displaying in navigators where there may be limited horizontal space.
         */
        public var navigator: [DeclarationFragments.Fragment]?

        /**
         An abbreviated form of the symbol's declaration for displaying in subheadings or lists.
         */
        public var subHeading: [DeclarationFragments.Fragment]?

        /**
         A name to use in documentation prose or inline link titles.

         > Note: If undefined, use the `title`.
         */
        public var prose: String?
        
        public init(title: String, navigator: [DeclarationFragments.Fragment]?, subHeading: [DeclarationFragments.Fragment]?, prose: String?) {
            self.title = title
            self.navigator = navigator
            self.subHeading = subHeading
            self.prose = prose
        }
    }
}

extension SymbolGraph.Symbol {
    /// Whether the symbol is marked as a System Programming Interface in source.
    public struct SPI: Mixin, Codable {
        public static let mixinKey = "spi"

        public var isSPI: Bool

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            isSPI = try container.decode(Bool.self)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(isSPI)
        }
        
        public init(isSPI: Bool) {
            self.isSPI = isSPI
        }
    }
}

extension SymbolGraph.Symbol {
    /**
     Availability is described by a *domain* and the versions in which
     certain events may have occurred, such as a symbol's appearance in a framework,
     its deprecation, obsolescence, or removal.
     A symbol may have zero or more availability items.

     For example,
     a class introduced in iOS 11 would have:

     - a availability domain of `"iOS"` and
     - an `introduced` version of `11.0.0`.

     As another example,
     a method `foo` that was renamed to `bar` in iOS 10.1 would have:

     - an availability domain of `"iOS"`,
     - a `deprecated` version `10.1.0`, and
     - a `renamed` string of `"bar"`.

     Some symbols may be *unconditionally* unavailable or deprecated.
     This means that the availability applies to any version, and
     possibly to all domains if the `availabilityDomain` key is undefined.
     */
    public struct Availability: Mixin, Codable {
        public static let mixinKey = "availability"

        public var availability: [AvailabilityItem]

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            availability = try container.decode([AvailabilityItem].self)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(availability)
        }
        
        public init(availability: [AvailabilityItem]) {
            self.availability = availability
        }
    }
}

extension SymbolGraph.Symbol.Availability {
    /**
     Availability of a symbol in a particular domain.
     */
    public struct AvailabilityItem: Codable {
        /**
         The domain in which this availability applies; if undefined, applies to all reasonable domains.
         */
        public var domain: Domain?

        /**
         The version in which a symbol appeared.
         */
        public var introducedVersion: SymbolGraph.SemanticVersion?

        /**
         The version in which a symbol was deprecated.

         > Note: If a symbol is *unconditionally deprecated*, this key should be undefined or `null` (see below).
         */
        public var deprecatedVersion: SymbolGraph.SemanticVersion?

        /**
         The version in which a symbol was obsoleted.

         > Note: If a symbol is *unconditionally obsoleted*, this key should be undefined or `null` (see below).
         */
        public var obsoletedVersion: SymbolGraph.SemanticVersion?

        /**
         A message further describing availability for documentation purposes.
         */
        public var message: String?

        /**
         If a symbol was renamed at this point, its new name is given here.

         > Note: This is not necessarily an identifier but an attribute string provided by a compiler.
         */
        public var renamed: String?

        /**
         If defined and `true`, is unconditionally deprecated regardless
         of version, and possibly regardless of domain.
         If undefined, assume `false`.
         */
        public var isUnconditionallyDeprecated: Bool

        /**
         If defined and `true`, is unconditionally unavailable regardless
         of version, and possibly regardless of domain.
         If undefined, assume `false`.
         */
        public var isUnconditionallyUnavailable: Bool

        /**
         A formal but lenient indication that this symbol will definitely be deprecated
         in future version of the availability domain, but the version hasn't
         been decided yet. This is also known as *soft deprecation*.

         Soft deprecation should not provide build errors, runtime errors, or
         warnings that can be upgraded to errors, but provides extra time for
         usage of a symbol to decrease before providing an explicit
         availability deadline.

         If a symbol is formally deprecated with an explicit version in the
         `deprecated` property above, the `willEventuallyBeDeprecated` key
         should not exist. In the event that it is still included
         despite this specification, `deprecated` should always take precedence
         over this property in clients.
         */
        public var willEventuallyBeDeprecated: Bool

        enum CodingKeys: String, CodingKey {
            case domain
            case introducedVersion = "introduced"
            case deprecatedVersion = "deprecated"
            case obsoletedVersion = "obsoleted"
            case message
            case renamed
            case isUnconditionallyDeprecated
            case isUnconditionallyUnavailable
            case willEventuallyBeDeprecated
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let domain = try container.decodeIfPresent(Domain.self, forKey: .domain)
            if domain?.rawValue == "*" {
                self.domain = nil
            } else {
                self.domain = domain
            }
            self.introducedVersion = try container.decodeIfPresent(SymbolGraph.SemanticVersion.self, forKey: .introducedVersion)
            self.deprecatedVersion = try container.decodeIfPresent(SymbolGraph.SemanticVersion.self, forKey: .deprecatedVersion)
            self.obsoletedVersion = try container.decodeIfPresent(SymbolGraph.SemanticVersion.self, forKey: .obsoletedVersion)
            self.message = try container.decodeIfPresent(String.self, forKey: .message)
            self.renamed = try container.decodeIfPresent(String.self, forKey: .renamed)
            self.isUnconditionallyDeprecated = try container.decodeIfPresent(Bool.self, forKey: .isUnconditionallyDeprecated) ?? false
            self.isUnconditionallyUnavailable = try container.decodeIfPresent(Bool.self, forKey: .isUnconditionallyUnavailable) ?? false
            self.willEventuallyBeDeprecated = try container.decodeIfPresent(Bool.self, forKey: .willEventuallyBeDeprecated) ?? false
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(domain, forKey: .domain)
            if let introducedVersion = introducedVersion {
                try container.encode(introducedVersion, forKey: .introducedVersion)
            }
            if let deprecatedVersion = deprecatedVersion {
                try container.encode(deprecatedVersion, forKey: .deprecatedVersion)
            }
            if let obsoletedVersion = obsoletedVersion {
                try container.encode(obsoletedVersion, forKey: .obsoletedVersion)
            }
            if let message = message {
                try container.encode(message, forKey: .message)
            }
            if let renamed = renamed {
                try container.encode(renamed, forKey: .renamed)
            }
            if isUnconditionallyDeprecated {
                try container.encode(isUnconditionallyDeprecated, forKey: .isUnconditionallyDeprecated)
            }
            if isUnconditionallyUnavailable {
                try container.encode(isUnconditionallyUnavailable, forKey: .isUnconditionallyUnavailable)
            }
            if willEventuallyBeDeprecated {
                try container.encode(willEventuallyBeDeprecated, forKey: .willEventuallyBeDeprecated)
            }
        }
        
        public init(domain: SymbolGraph.Symbol.Availability.Domain?,
                    introducedVersion: SymbolGraph.SemanticVersion?,
                    deprecatedVersion: SymbolGraph.SemanticVersion?,
                    obsoletedVersion: SymbolGraph.SemanticVersion?,
                    message: String?,
                    renamed: String?,
                    isUnconditionallyDeprecated: Bool,
                    isUnconditionallyUnavailable: Bool,
                    willEventuallyBeDeprecated: Bool) {
            self.domain = domain
            self.introducedVersion = introducedVersion
            self.deprecatedVersion = deprecatedVersion
            self.obsoletedVersion = obsoletedVersion
            self.message = message
            self.renamed = renamed
            self.isUnconditionallyDeprecated = isUnconditionallyDeprecated
            self.isUnconditionallyUnavailable = isUnconditionallyUnavailable
            self.willEventuallyBeDeprecated = willEventuallyBeDeprecated
        }
    }
}

extension SymbolGraph.Symbol.Availability {
    /**
     A versioned context where a symbol resides.

     For example, a domain can be an operating system, programming language,
     or perhaps a web platform.

     A single framework, library, or module could theoretically be
     an `AvailabilityDomain`, as it is a containing context and almost always
     has a version.
     However, availability is usually tied to some larger platform like an SDK for
     an operating system like *iOS*.

     There may be exceptions when there isn't a reasonable larger context.
     For example, a web framework's larger context is simply *the Web*.
     Therefore, a web framework could be its own domain so that deprecations and
     API changes can be tracked across versions of that framework.
     */
    public struct Domain: Codable, RawRepresentable {
        public var rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        /**
         The Swift Programming Language.

         This domain main indicate that a symbol is unavailable
         in Swift, or availability applies to particular versions
         of Swift.
         */
        public static let swift = "Swift"

        /**
         The Swift Package Manager Package Description Format.
         */
        public static let swiftPM = "SwiftPM"

        /**
         Apple's macOS operating system.
         */
        public static let macOS = "macOS"

        /**
         An application extension for the macOS operating system.
         */
        public static let macOSAppExtension = "macOSAppExtension"

        /**
         The iOS operating system.
         */
        public static let iOS = "iOS"

        /**
         An application extension for the iOS operating system.
         */
        public static let iOSAppExtension = "iOSAppExtension"

        /**
         The watchOS operating system.
         */
        public static let watchOS = "watchOS"

        /**
         An application extension for the watchOS operating system.
         */
        public static let watchOSAppExtension = "watchOSAppExtension"

        /**
         The tvOS operating system.
         */
        public static let tvOS = "tvOS"

        /**
         An application extension for the tvOS operating system.
         */
        public static let tvOSAppExtension = "tvOSAppExtension"

        /**
         The Mac Catalyst platform.
         */
        public static let macCatalyst = "macCatalyst"

        /**
         An application extension for the Mac Catalyst platform.
         */
        public static let macCatalystAppExtension = "macCatalystAppExtension"

        /**
         A Linux-based operating system, but not a specific distribution.
         */
        public static let linux = "Linux"
    }
}

extension SymbolGraph.Symbol {
    /**
     A mix-in that generically describes the fragments
     of a symbol's declaration in a particular language, allowing for idiomatic
     presentation.

     For example, one can use this to drive a "code snippet"
     with syntax highlighting for a function signature.

     For example, the following declaration in Swift:

     ```swift
     func foo<S: Sequence>(_ sequence: S) -> Int {
         // ...
     }
     ```

     Would be represented with the following list of tokens when displaying
     the declaration fragment:

     ```json
     [
         {
             "kind": "keyword",
             "spelling": "func"
         },
         {
             "kind": "identifier",
             "spelling": "foo"
         },
         {
             "kind": "punctuation",
             "spelling": "<"
         },
         {
             "kind": "identifier",
             "spelling": "S"
         },
         {
             "kind": "punctuation",
             "spelling": ":"
         },
         {
             "kind": "trivia",
             "spelling": " "
         },
         {
             "kind": "typeIdentifier",
             "spelling": "Sequence",
             "preciseIdentifier": "$sST"
         },
         {
             "kind": "punctuation",
             "spelling": ">"
         },
         {
             "kind": "punctuation",
             "spelling": "("
         },
         {
             "kind": "identifier",
             "spelling": "_"
         },
         {
             "kind": "trivia",
             "spelling": " "
         },
         {
             "kind": "identifier",
             "spelling": "seq"
         },
         {
             "kind": "punctuation",
             "spelling": ":"
         },
         {
             "kind": "typeIdentifier",
             "spelling": "Sequence",
             "preciseIdentifier": "$sST"
         },
         {
             "kind": "punctuation",
             "spelling": ":"
         },
         {
             "kind": "identifier",
             "spelling": "S"
         },
             {
             "kind": "punctuation",
             "spelling": ")"
         },
             {
             "kind": "trivia",
             "spelling": " "
         },
         {
             "kind": "punctuation",
             "spelling": "->"
         },
             {
             "kind": "trivia",
             "spelling": " "
         },
             {
             "kind": "typeIdentifier",
             "spelling": "Int",
             "preciseIdentifier": "$sSi"
         }
     ]
     ```
     */
    public struct DeclarationFragments: Mixin, Codable {
        public static let mixinKey = "declarationFragments"

        /**
         A list of fragments spelling out the declarations,
         allowing for a presentation that's idiomatic to the source language
         and cross-referencing identifiers to other symbols in the module.

         > Note: These may not necessarily, literally be lexer tokens but they may be.
         */
        public var declarationFragments: [Fragment]
        
        /**
          Initialize a declaration fragments mix-in with the given list of fragments.
          
          - Parameters:
             - declarationFragments: The list of fragments spelling out the declaration.
         */
        public init(declarationFragments: [Fragment]) {
            self.declarationFragments = declarationFragments
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            declarationFragments = try container.decode([Fragment].self)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(declarationFragments)
        }
    }
}

extension SymbolGraph.Symbol.DeclarationFragments {
    /**
     A general-purpose fragment of syntax spelling out a declaration.

     For example, a C function might break up `int main(int argc, char **argv)`
     or a Swift structure might break up into `struct MyStruct<S: Sequence>`.
     */
    public struct Fragment: Equatable, Codable {
        /**
         The kind of fragment, such as a token keyword, identifier,
         or span of text.
         */
        public var kind: Kind

        /**
         How the token was spelled in the source code.
         */
        public var spelling: String

        /**
         A precise identifier if the fragment corresponds to another symbol.
         This may be useful for linking to other symbols when displaying
         function parameter types.
         */
        public var preciseIdentifier: String?
        
        /**
          Initialize a fragment with the given `kind`, `spelling`, and `preciseIdentifier`.
          
          - Parameters:
             - kind: The kind of fragment.
             - spelling: How the token was spelled in the source code.
             - preciseIdentifier: A precise identifier if the fragment corresponds to another symbol.
         */
        public init(kind: Kind, spelling: String, preciseIdentifier: String?) {
            self.kind = kind
            self.spelling = spelling
            self.preciseIdentifier = preciseIdentifier
        }
    }
}

extension SymbolGraph.Symbol.DeclarationFragments.Fragment {
    /**
     The kind of declaration fragment.
     */
    public struct Kind: Equatable, Codable, RawRepresentable {
        public var rawValue: String
        public init?(rawValue: String) {
            self.rawValue = rawValue
        }

        /**
         A keyword in the programming language, such as `return` in C or `func` in Swift.
         */
        public static let keyword = Kind(rawValue: "keyword")!

        /**
         An attribute in the programming language.
         */
        public static let attribute = Kind(rawValue: "attribute")!

        /**
         An integer or floating point literal, such as `0`, `1.0f`, or `0xFF`.
         */
        public static let numberLiteral = Kind(rawValue: "number")!

        /**
         A string literal such as `"foo"`.
         */
        public static let stringLiteral = Kind(rawValue: "string")!

        /**
         An identifier such as a parameter name.
         */
        public static let identifier = Kind(rawValue: "identifier")!

        /**
         An identifier for a type.
         */
        public static let typeIdentifier = Kind(rawValue: "typeIdentifier")!

        /**
         A generic parameter, such as the `T` in C++ `template <typename T>`.
         */
        public static let genericParameter = Kind(rawValue: "genericParameter")!

        /**
         A function parameter when viewed externally as a client.

         For example, in Swift:

         ```swift
         func foo(ext int: Int) {}
         ```

         `ext` is an external parameter name, whereas `int` is an internal
         parameter name.
         */
        public static let externalParameter = Kind(rawValue: "externalParam")!

        /**
         A function parameter when viewed internally from the implementation.

         For example, in Swift:

         ```swift
         func foo(ext int: Int) {}
         ```

         `ext` is an external parameter name, whereas `int` is an internal
         parameter name.

         > Note: Although these are not a part of a function's interface,
         > such as in Swift, they have historically been easier to refer
         > to in prose.
         */
        public static let internalParameter = Kind(rawValue: "internalParam")!

        /**
         General purpose or unlabeled text.
         */
        public static let text = Kind(rawValue: "text")!
    }
}

extension SymbolGraph.Symbol {
    /// The arguments of a callable symbol.
    public struct FunctionSignature: Mixin, Codable {

        enum CodingKeys: String, CodingKey {
            case parameters
            case returns
        }

        public static let mixinKey = "functionSignature"

        /**
         The parameters of the function.
         */
        public var parameters: [FunctionParameter]

        /**
         The fragments spelling out the return type of the function signature if applicable.
         */
        public var returns: [DeclarationFragments.Fragment]

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.parameters = try container.decodeIfPresent([FunctionParameter].self, forKey: .parameters) ?? []
            self.returns = try container.decodeIfPresent([DeclarationFragments.Fragment].self, forKey: .returns) ?? []
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(parameters, forKey: .parameters)
            try container.encode(returns, forKey: .returns)
        }
    }
}

extension SymbolGraph.Symbol.FunctionSignature {
    /// An argument of a callable symbol.
    public struct FunctionParameter: Codable {
        enum CodingKeys: String, CodingKey {
            case name
            case declarationFragments
            case children
        }


        /// The name of the symbol, as referred to in user code (must match the name used in the documentation comment).
        public var name: String // should we differentiate between internal and external names?
        /// The syntax used to create the parameter.
        public var declarationFragments: [SymbolGraph.Symbol.DeclarationFragments.Fragment]
        /// Sub-parameters of the parameter.
        public var children: [FunctionParameter]
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.declarationFragments = try container.decodeIfPresent([SymbolGraph.Symbol.DeclarationFragments.Fragment].self, forKey: .declarationFragments) ?? []
            self.children = try container.decodeIfPresent([FunctionParameter].self, forKey: .children) ?? []
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(declarationFragments, forKey: .declarationFragments)
            try container.encode(children, forKey: .children)
        }
    }
}

extension SymbolGraph.Symbol {
    /**
     A mix-in that specifies whether a symbol is immutable in its host language.

     For example, a constant member `let x = 1` in a Swift structure
     would have `isReadOnly` set to `true`.
     */
    public struct Mutability: Mixin, Equatable, Codable {
        public static let mixinKey = "isReadOnly"

        /**
         Whether a symbol is *immutable* or "read-only".
         */
        public var isReadOnly: Bool

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            isReadOnly = try container.decode(Bool.self)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(isReadOnly)
        }
    }
}

extension SymbolGraph.Symbol {
    /**
     The place where a symbol was originaly declared in a source file.

     This information may not always be available for many reasons, such
     as compiler infrastructure limitations, or filesystem security concerns.
     */
    public struct Location: Mixin {
        public static let mixinKey = "location"

        /**
         The URI of the file in which the symbol was originally declared,
         suitable for display in a user interface.
         */
        public var uri: String

        /**
         The range of the declaration in the file, not including its documentation comment.
         */
        public var position: SymbolGraph.LineList.SourceRange.Position
    }
}

extension SymbolGraph.Symbol {
    /// A namespace for Swift-specific data.
    public enum Swift {
        /// A generic constraint between two types.
        public struct GenericConstraint: Codable, Hashable {
            public enum Kind: String, Codable {
                /**
                 A conformance constraint, such as:

                 ```swift
                 extension Thing where Thing.T: Sequence {
                    // ...
                 }
                 ```
                 */
                case conformance

                /**
                 A superclass constraint, such as:

                 ```swift
                 extension Thing where Thing.T: NSObject {
                    // ...
                 }
                 ```
                 */
                case superclass

                /**
                 A same-type constraint, such as:

                 ```swift
                 extension Thing where Thing.T == Int {
                     // ...
                 }
                 ```
                 */
                case sameType
            }

            enum CodingKeys: String, CodingKey {
                case kind
                case leftTypeName = "lhs"
                case rightTypeName = "rhs"
            }

            /**
             The kind of generic constraint.
             */
            public var kind: Kind

            /**
             The spelling of the left-hand side of the constraint.
             */
            public var leftTypeName: String

            /**
             The spelling of the right-hand side of the constraint.
             */
            public var rightTypeName: String

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.kind = try container.decode(Kind.self, forKey: .kind)
                self.leftTypeName = try container.decode(String.self, forKey: .leftTypeName)
                self.rightTypeName = try container.decode(String.self, forKey: .rightTypeName)
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(kind, forKey: .kind)
                try container.encode(leftTypeName, forKey: .leftTypeName)
                try container.encode(rightTypeName, forKey: .rightTypeName)
            }
        }

        /**
         A generic parameter of a declaration, such as the `T` in `foo<T>(...)`.
         */
        public struct GenericParameter: Codable {
            /// The name of the generic parameter.
            public var name: String

            /**
             The index of the generic parameter.

             For example, in the following function signature,

             ```swift
             func foo<T, U>(x: T, y: U)
             ```

             `T` has index 0 and `U` has index 1.
             */
            public var index: Int

            /**
             The depth of the generic parameter.

             For example, in the following generic structure,

             ```swift
             struct MyStruct<T> {
               func foo<U>(x: U, y: T) {
                 // ...
               }
             }
             ```

             `T` has depth 0 and `U` has depth 1.
             */
            public var depth: Int
        }

        /**
         If the Symbol is from Swift, this mixin describes the extension context in which it was defined.
         */
        public struct Extension: Mixin {
            public static let mixinKey = "swiftExtension"

            /**
             The module whose type was extended.

             > Note: This module maybe different than where the symbol was actually defined. For example, one can create a public extension on the Swift Standard Library's `String` type in a different module, so `extendedModule` would be `Swift`.
             */
            public var extendedModule: String

            /**
             The generic constraints on the extension, if any.
             */
            public var constraints: [Swift.GenericConstraint]

            enum CodingKeys: String, CodingKey {
                case extendedModule
                case constraints
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.extendedModule = try container.decode(String.self, forKey: .extendedModule)
                self.constraints = try container.decodeIfPresent([GenericConstraint].self, forKey: .constraints) ?? []
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(extendedModule, forKey: .extendedModule)
                if !constraints.isEmpty {
                   try container.encode(constraints, forKey: .constraints)
                }
            }
        }

        /**
         The generic signature of a declaration or type.
         */
        public struct Generics: Mixin {
            public static let mixinKey = "swiftGenerics"

            enum CodingKeys: String, CodingKey {
                case parameters
                case constraints
            }

            /**
             The generic parameters of a declaration.

             For example, in the following generic function signature,

             ```swift
             func foo<T>(_ thing: T) { ... }
             ```

             `T` is a *generic parameter*.
             */
            public var parameters: [GenericParameter]

            /**
             The generic constraints of a declaration.

             For example, in the following generic function signature,

             ```swift
             func foo<S>(_ s: S) where S: Sequence
             ```

             There is a *conformance constraint* involving `S`.
             */
            public var constraints: [GenericConstraint]

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.parameters = try container.decodeIfPresent([GenericParameter].self, forKey: .parameters) ?? []
                self.constraints = try container.decodeIfPresent([GenericConstraint].self, forKey: .constraints) ?? []
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                if !parameters.isEmpty {
                    try container.encode(parameters, forKey: .parameters)
                }
                if !constraints.isEmpty {
                   try container.encode(constraints, forKey: .constraints)
                }
            }
        }
    }
}

/**
 A protocol that allows extracted symbols to have extra data
 aside from the base ``SymbolGraph/Symbol``.
 */
public protocol Mixin: Codable {
    /**
     The key under which a mixin's data is filed.

     > Important: With respect to deserialization, this framework assumes `mixinKey`s between instances of `SymbolMixin` are unique.
     */
    static var mixinKey: String { get }
}
