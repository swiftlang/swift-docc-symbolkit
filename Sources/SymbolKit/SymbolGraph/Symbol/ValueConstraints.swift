/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2022 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol {
    // Set of constraints that describe the value held by a variable.
    // 
    // These constraints include the allowed minimum or maximum value,
    // the minimum or maximum lengths of a string value,
    // the exact allowed values, and the default value assumed when one isn't
    // explicitly specified.
    
    /// The minimum value, which can be specified as an integer or floating point.
    public struct Minimum: SingleValueMixin {
        public static let mixinKey = "minimum"
        public typealias ValueType = SymbolGraph.AnyNumber
        public var value: ValueType
        public init(_ value: ValueType) {
            self.value = value
        }
    }
    
    public var minimum : SymbolGraph.AnyNumber? {
        (mixins[Minimum.mixinKey] as? Minimum)?.value
    }
    
    /// The maximum value, which can be specified as an integer or floating point.
    public struct Maximum: SingleValueMixin {
        public static let mixinKey = "maximum"
        public typealias ValueType = SymbolGraph.AnyNumber
        public var value: ValueType
        public init(_ value: ValueType) {
            self.value = value
        }
    }
    
    public var maximum : SymbolGraph.AnyNumber? {
        (mixins[Maximum.mixinKey] as? Maximum)?.value
    }
    
    /// The lower bound of allowed values, excluding the value itself, which can be specified as an integer or floating point.
    public struct MinimumExclusive: SingleValueMixin {
        public static let mixinKey = "minimumExclusive"
        public typealias ValueType = SymbolGraph.AnyNumber
        public var value: ValueType
        public init(_ value: ValueType) {
            self.value = value
        }
    }
    
    public var minimumExclusive : SymbolGraph.AnyNumber? {
        (mixins[MinimumExclusive.mixinKey] as? MinimumExclusive)?.value
    }
    
    /// The upper bound of allowed values, excluding the value itself, which can be specified as an integer or floating point.
    public struct MaximumExclusive: SingleValueMixin {
        public static let mixinKey = "maximumExclusive"
        public typealias ValueType = SymbolGraph.AnyNumber
        public var value: ValueType
        public init(_ value: ValueType) {
            self.value = value
        }
    }
    
    public var maximumExclusive : SymbolGraph.AnyNumber? {
        (mixins[MaximumExclusive.mixinKey] as? MaximumExclusive)?.value
    }
    
    /// The minimum length of a string.
    public struct MinimumLength: SingleValueMixin {
        public static let mixinKey = "minimumLength"
        public typealias ValueType = Int
        public var value: ValueType
        public init(_ value: ValueType) {
            self.value = value
        }
    }
    
    public var minimumLength : Int? {
        (mixins[MinimumLength.mixinKey] as? MinimumLength)?.value
    }
    
    /// The maximum length of a string.
    public struct MaximumLength: SingleValueMixin {
        public static let mixinKey = "maximumLength"
        public typealias ValueType = Int
        public var value: ValueType
        public init(_ value: ValueType) {
            self.value = value
        }
    }
    
    public var maximumLength : Int? {
        (mixins[MaximumLength.mixinKey] as? MaximumLength)?.value
    }
    
    /// The finite set of values allowed, which can be specified as strings, numbers, booleans, or a null, depending on context.
    public struct AllowedValues: SingleValueMixin {
        public static let mixinKey = "allowedValues"
        public typealias ValueType = [SymbolGraph.AnyScalar]
        public var value: ValueType
        public init(_ value: ValueType) {
            self.value = value
        }
    }
    
    public var allowedValues : [SymbolGraph.AnyScalar]? {
        (mixins[AllowedValues.mixinKey] as? AllowedValues)?.value
    }
    
    /// The default value, which can be specified as a string, number, boolean, or a null, depending on context.
    public struct DefaultValue: SingleValueMixin {
        public static let mixinKey = "default"
        public typealias ValueType = SymbolGraph.AnyScalar
        public var value: ValueType
        public init(_ value: ValueType) {
            self.value = value
        }
    }
    
    public var defaultValue : SymbolGraph.AnyScalar? {
        (mixins[DefaultValue.mixinKey] as? DefaultValue)?.value
    }
}
