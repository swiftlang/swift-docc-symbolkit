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
