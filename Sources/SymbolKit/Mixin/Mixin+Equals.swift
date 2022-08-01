/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

// `Mixin` does not conform to `Equatable` right now primarily because
// this would complicate its usage in many situtations because of "Self
// or associated type" requirements errors. Thus, in order to compare
// `Mixin`s for equality, we need to somehow get access to the `Mixin`'s
// `Equatable` conformance and the `==(lhs:rhs:)` function specifically.
//
// Note that all of this would be siginificantly easier in Swift 5.7, so
// it might be worth updating the implementation once SymbolKit adopts
// Swift 5.7 as its minimum language requirement.


// When working with `Mixin` values in a generic (non-specific) context,
// we only know their value conforms to the existential type `Mixin`. This
// extension to `Mixin` and the `equals` property defined in it is essentiall for
// the whole process to work:
// The `equals` property does not expose the `Self` type in its interface and
// therefore is accessible from the existential type `Mixin`. Inside `equals`,
// however, we have access to the concrete type `Self`, allowing us to initialize
// the `EquatableDetector` with a concrete generic type, which can know it conforms
// to `Equatable`. If we were to simply pass a value of type `Any` into the initializer
// of `EquatableDetector`, the latter would not recognize `value` as `Equatable`, even
// if the original concrete type were to conform to `Equatable`.
extension Mixin {
    /// A type-erased version of this ``Mixin``s `==(lhs:rhs:)` function, available
    /// only if this ``Mixin`` conforms to `Equatable`.
    var equals: ((Any) -> Bool)? {
        (EquatableDetector(value: self) as? AnyEquatable)?.equals
    }
}

// The `AnyEquatable` protocol defines our requirement for an equality function
// in a type-erased way. It has no Self or associated type requirements and thus
// can be casted to via a simple `as?`. In Swift 5.7 we could simply cast to
// `any Equatable`, but this was not possible before.
private protocol AnyEquatable {
    var equals: (Any) -> Bool { get }
}

// The `EquatableDetector` brings both pieces together by conditionally conforming
// itself to `AnyEquatable` where its generic `value` is `Equatable`.
private struct EquatableDetector<T> {
    let value: T
}

extension EquatableDetector: AnyEquatable where T: Equatable {
    var equals: (Any) -> Bool {
        { other in
            guard let other = other as? T else {
                // we are comparing `value` against `other`, but
                // `other` is of a different type, so they can't be
                // equal
                return false
            }
            
            // we finally know that `value`, as well as `other`
            // are of the same type `T`, which conforms to `Equatable`
            return value == other
        }
    }
}
