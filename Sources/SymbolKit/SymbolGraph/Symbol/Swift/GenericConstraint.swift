/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol.Swift {
    /// A generic constraint between two types.
    public struct GenericConstraint: Codable, Hashable {
        public enum Kind: String, Codable {
            /**
             A conformance constraint, such as:

             ```swift
             extension Thing where Thing.T: Sequence {
                // ...
             }
             ```
             */
            case conformance

            /**
             A superclass constraint, such as:

             ```swift
             extension Thing where Thing.T: NSObject {
                // ...
             }
             ```
             */
            case superclass

            /**
             A same-type constraint, such as:

             ```swift
             extension Thing where Thing.T == Int {
                 // ...
             }
             ```
             */
            case sameType
        }

        enum CodingKeys: String, CodingKey {
            case kind
            case leftTypeName = "lhs"
            case rightTypeName = "rhs"
        }

        /**
         The kind of generic constraint.
         */
        public var kind: Kind

        /**
         The spelling of the left-hand side of the constraint.
         */
        public var leftTypeName: String

        /**
         The spelling of the right-hand side of the constraint.
         */
        public var rightTypeName: String

        public init(kind: Kind, leftTypeName: String, rightTypeName: String) {
            self.kind = kind
            self.leftTypeName = leftTypeName
            self.rightTypeName = rightTypeName
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            kind = try container.decode(Kind.self, forKey: .kind)
            leftTypeName = try container.decode(String.self, forKey: .leftTypeName)
            rightTypeName = try container.decode(String.self, forKey: .rightTypeName)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(kind, forKey: .kind)
            try container.encode(leftTypeName, forKey: .leftTypeName)
            try container.encode(rightTypeName, forKey: .rightTypeName)
        }
    }
}
