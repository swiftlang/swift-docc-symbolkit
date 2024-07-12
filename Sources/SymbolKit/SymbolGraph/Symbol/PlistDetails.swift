/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2024 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol {
    
    /// The details about a property list key.
    public var plistDetails: PlistDetails? {
        (mixins[PlistDetails.mixinKey] as? PlistDetails)
    }
    
    /// A mixin that contains details about a property list key.
    public struct PlistDetails: Mixin, Codable {
        
        public static let mixinKey = "plistDetails"
        
        /// The name of the key.
        public var rawKey: String
        /// A human-friendly name of the key.
        public var customTitle: String?
        /// The plain text name of a symbol's base type. For example, `Int` for an array of integers.
        public var baseType: String?
        /// Indicates if the base type is an array.
        public var arrayMode: Bool?

        public init(rawKey: String, customTitle: String? = nil, baseType: String? = nil, arrayMode: Bool? = false) {
            self.arrayMode = arrayMode
            self.baseType = baseType
            self.customTitle = customTitle
            self.rawKey = rawKey
        }
    }
}
