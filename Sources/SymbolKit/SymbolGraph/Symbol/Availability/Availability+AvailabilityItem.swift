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
            introducedVersion = try container.decodeIfPresent(SymbolGraph.SemanticVersion.self, forKey: .introducedVersion)
            deprecatedVersion = try container.decodeIfPresent(SymbolGraph.SemanticVersion.self, forKey: .deprecatedVersion)
            obsoletedVersion = try container.decodeIfPresent(SymbolGraph.SemanticVersion.self, forKey: .obsoletedVersion)
            message = try container.decodeIfPresent(String.self, forKey: .message)
            renamed = try container.decodeIfPresent(String.self, forKey: .renamed)
            isUnconditionallyDeprecated = try container.decodeIfPresent(Bool.self, forKey: .isUnconditionallyDeprecated) ?? false
            isUnconditionallyUnavailable = try container.decodeIfPresent(Bool.self, forKey: .isUnconditionallyUnavailable) ?? false
            willEventuallyBeDeprecated = try container.decodeIfPresent(Bool.self, forKey: .willEventuallyBeDeprecated) ?? false
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
