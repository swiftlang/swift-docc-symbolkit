/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

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
