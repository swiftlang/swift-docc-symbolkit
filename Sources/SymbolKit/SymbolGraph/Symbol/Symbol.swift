/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
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

        /// If true, the symbol was created implicitly and not from source.
        public var isVirtual: Bool

        /// If the symbol has a documentation comment, whether the documentation comment is from
        /// the same module as the symbol or not.
        ///
        /// An inherited documentation comment is from the same module when the symbol that the documentation is inherited from is in the same module as this symbol.
        @available(*, deprecated, message: "Use 'isDocCommentFromSameModule(symbolModuleName:)' instead.")
        public var isDocCommentFromSameModule: Bool? {
            _isDocCommentFromSameModule
        }
        // To avoid deprecation warnings in SymbolKit test until the deprecated property is removed.
        internal var _isDocCommentFromSameModule: Bool? {
            guard let docComment = docComment, !docComment.lines.isEmpty else {
                return nil
            }

            // As a current implementation detail, documentation comments from within the current module has range information but
            // documentation comments that are inherited from other modules don't have any range information.
            //
            // This isn't always correct and is only used as a fallback logic for symbol information before the source module was
            // included in the symbol graph file.
            return docComment.lines.contains(where: { $0.range != nil })
        }
        
        /// If the symbol has a documentation comment, checks whether the documentation comment is from the same module as the symbol.
        ///
        /// A documentation comment is from the same module as the symbol when the source of the documentation comment is the symbol itself or another symbol in the same module.
        ///
        /// - Parameter symbolModuleName: The name of the module where the symbol is defined.
        /// - Returns: `true`if the source of the documentation comment is from the same module as this symbol.
        public func isDocCommentFromSameModule(symbolModuleName: String) -> Bool? {
            guard let docComment = docComment, !docComment.lines.isEmpty else {
                return nil
            }
            
            if let moduleName = docComment.moduleName {
                // If the new source module information is available, rely on that.
                return moduleName == symbolModuleName
            } else {
                // Otherwise, fallback to the previous implementation.
                return _isDocCommentFromSameModule
            }
        }

        /// The access level of the symbol.
        public var accessLevel: AccessControl

        /// Information about a symbol that is not necessarily common to all symbols.
        public var mixins: [String: Mixin] = [:]

        public init(identifier: Identifier, names: Names, pathComponents: [String], docComment: LineList?, accessLevel: AccessControl, kind: Kind, mixins: [String: Mixin], isVirtual: Bool = false) {
            self.identifier = identifier
            self.names = names
            self.pathComponents = pathComponents
            self.docComment = docComment
            self.accessLevel = accessLevel
            self.kind = kind
            self.isVirtual = isVirtual
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
            case isVirtual

            // Mixins
            case availability
            case declarationFragments
            case isReadOnly
            case swiftExtension
            case swiftGenerics
            case location
            case functionSignature
            case spi
            case snippet

            static var mixinKeys: Set<CodingKeys> {
                return [
                    .availability,
                    .declarationFragments,
                    .isReadOnly,
                    .swiftExtension,
                    .swiftGenerics,
                    .location,
                    .functionSignature,
                    .spi,
                    .snippet,
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
            isVirtual = try container.decodeIfPresent(Bool.self, forKey: .isVirtual) ?? false
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
            if isVirtual {
                try container.encode(isVirtual, forKey: .isVirtual)
            }

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
                case .snippet:
                    try container.encode(mixin as! Snippet, forKey: key)
                case .location:
                    try container.encode(mixin as! Location, forKey: key)
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
                return try? container.decode(Location.self, forKey: key)
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
            case Snippet.mixinKey:
                return try container.decode(Snippet.self, forKey: key)
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
