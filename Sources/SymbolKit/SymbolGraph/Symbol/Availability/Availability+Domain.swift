/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

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
