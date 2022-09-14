/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

// `Mixin` does not conform to `Hashable` right now primarily because
// this would complicate its usage in many situtations because of "Self
// or associated type" requirements errors. `Hashable` inherits those
// frome `Equatable`, even though its primary functionality, the `hash(into:)`
// function has no Self or associated type requirements. Thus, in order to
// access a `Mixin`'s `hash(into:)` function, we need to somehow get access to
// the `Mixin`'s `Hashable` conformance.
//
// Note that all of this would be siginificantly easier in Swift 5.7, so
// it might be worth updating the implementation once SymbolKit adopts
// Swift 5.7 as its minimum language requirement.


// When working with `Mixin` values in a generic (non-specific) context,
// we only know their value conforms to the existential type `Mixin`. This
// extension to `Mixin` and the `hash` property defined in it is essentiall for
// the whole process to work:
// The `hash` property does not expose the `Self` type in its interface and
// therefore is accessible from the existential type `Mixin`. Inside `hash`,
// however, we have access to the concrete type `Self`, allowing us to initialize
// the `HashableDetector` with a concrete generic type, which can know it conforms
// to `Hashable`. If we were to simply pass a value of type `Any` into the initializer
// of `HashableDetector`, the latter would not recognize `value` as `Hashable`, even
// if the original concrete type were to conform to `Hashable`.
extension Mixin {
    /// This ``Mixin``s `hash(into:)` function, available
    /// only if this ``Mixin`` conforms to `Hashable`.
    var hash: ((inout Hasher) -> Void)? {
        (HashableDetector(value: self) as? AnyHashable)?.hash
    }
}

// The `AnyEquatable` protocol simply defines our requirement for a hash
// function. It has no Self or associated type requirements and thus can
// be casted to via a simple `as?`. In Swift 5.7 we could simply cast to
// `any Hashable`, but this was not possible before.
private protocol AnyHashable {
    var hash: (inout Hasher) -> Void { get }
}

// The `HashableDetector` brings both pieces together by conditionally conforming
// itself to `AnyHashable` where its generic `value` is `Hashable`.
private struct HashableDetector<T> {
    let value: T
}

extension HashableDetector: AnyHashable where T: Hashable {
    var hash: (inout Hasher) -> Void {
        value.hash(into:)
    }
}
