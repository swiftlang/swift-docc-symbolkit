/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2023 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph {
    /// Enumeration that can hold either a single boolean, integer, floating point, or string value or a null value.
    /// 
    /// This enumeration is used when a field within the symbol graph can hold a different value type
    /// depending on the context. One such case would be the default value of a dictionary property, whose
    /// value depends on the data type of the property (eg, a string or integer).
    public enum AnyScalar: Codable, Equatable {
        case null
        case boolean(Bool)
        case integer(Int)
        case float(Double)
        case string(String)
        
        // This empty-marker case is here because non-frozen enums are only available when Library
        // Evolution is enabled, which is not available to Swift Packages without unsafe flags
        // (rdar://78773361). This can be removed once that is available and applied to SymbolKit
        // (rdar://89033233).
        @available(*, deprecated, message: "this enum is nonfrozen and may be expanded in the future; please add a `default` case instead of matching this one")
        case _nonfrozenEnum_useDefaultCase
        
        public func encode(to encoder : Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .null:
                try container.encodeNil()
            case .boolean(let b):
                try container.encode(b)
            case .integer(let i):
                try container.encode(i)
            case .float(let d):
                try container.encode(d)
            case .string(let s):
                try container.encode(s)
            case ._nonfrozenEnum_useDefaultCase:
                fatalError("_nonfrozenEnum_useDefaultCase is not a supported case in AnyScalar")
            }
        }
        
        public init(from decoder: Decoder) throws {
            let singleValue = try decoder.singleValueContainer()
            if singleValue.decodeNil() {
                self = .null
            } else if let value = try? singleValue.decode(Swift.Bool.self) {
                self = .boolean(value)
            } else if let value = try? singleValue.decode(Swift.Int.self) {
                self = .integer(value)
            } else if let value = try? singleValue.decode(Swift.Double.self) {
                self = .float(value)
            } else if let value = try? singleValue.decode(Swift.String.self) {
                self = .string(value)
            } else {
                throw DecodingError.typeMismatch(
                    AnyScalar.self,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unable to parse scalar value"
                    )
                )
            }
        }
    }
    
    /// Enumeration that can hold either an integer or floating point value.
    /// 
    /// This enumeration is used when a field within the symbol graph can hold a different value type
    /// depending on the context. One such case would be the minimum value of a dictionary property, whose
    /// value depends on the numerical type of the property (eg, an integer or floating point).
    public enum AnyNumber: Codable, Equatable {
        case integer(Int)
        case float(Double)
        
        // This empty-marker case is here because non-frozen enums are only available when Library
        // Evolution is enabled, which is not available to Swift Packages without unsafe flags
        // (rdar://78773361). This can be removed once that is available and applied to SymbolKit
        // (rdar://89033233).
        @available(*, deprecated, message: "this enum is nonfrozen and may be expanded in the future; please add a `default` case instead of matching this one")
        case _nonfrozenEnum_useDefaultCase
        
        public func encode(to encoder : Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .integer(let i):
                try container.encode(i)
            case .float(let d):
                try container.encode(d)
            case ._nonfrozenEnum_useDefaultCase:
                fatalError("_nonfrozenEnum_useDefaultCase is not a supported case in AnyNumber")
            }
            
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let value = try? container.decode(Swift.Int.self) {
                self = .integer(value)
            } else if let value = try? container.decode(Swift.Double.self) {
                self = .float(value)
            } else {
                throw DecodingError.typeMismatch(AnyScalar.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to parse number value"))
            }
        }
    }
}

extension String {
    public init(_ value: SymbolGraph.AnyScalar) {
        switch value {
        case .null:
            self = "null"
        case .boolean(let b):
            self = String(b)
        case .integer(let i):
            self = String(i)
        case .float(let d):
            self = String(d)
        case .string(let s):
            self = s
        case ._nonfrozenEnum_useDefaultCase:
            fatalError("_nonfrozenEnum_useDefaultCase is not a supported case in AnyScalar")
        }
    }
    
    public init(_ value: SymbolGraph.AnyNumber) {
        switch value {
        case .integer(let i):
            self = String(i)
        case .float(let d):
            self = String(d)
        case ._nonfrozenEnum_useDefaultCase:
            fatalError("_nonfrozenEnum_useDefaultCase is not a supported case in AnyNumber")
        }
    }
}
