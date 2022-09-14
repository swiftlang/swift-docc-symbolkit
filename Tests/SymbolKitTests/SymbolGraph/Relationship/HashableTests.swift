/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation
import XCTest
import SymbolKit

class HashableTests: XCTestCase {
    /// Test hasing works as expected if Mixins conform to Hashable
    func testHashingWithHashableMixins() throws {
        var a1 = SymbolGraph.Relationship(source: "a.source", target: "a.target", kind: .conformsTo, targetFallback: nil)
        a1.mixins[SymbolGraph.Relationship.SourceOrigin.mixinKey] = SymbolGraph.Relationship.SourceOrigin(identifier: "a.1.origin", displayName: "a.1.origin")
        
        var a2 = SymbolGraph.Relationship(source: "a.source", target: "a.target", kind: .conformsTo, targetFallback: nil)
        a2.mixins[SymbolGraph.Relationship.SourceOrigin.mixinKey] = SymbolGraph.Relationship.SourceOrigin(identifier: "a.2.origin", displayName: "a.2.origin")
        
        XCTAssertEqual(Set([a1, a2]).count, 2)
    }
    
    /// Check that Mixins that do not implement Hashable are ignored, so that
    /// they don't render the Hashable implementation of Relationship useless.
    func testHashingWithNonHashableMixins() throws {
        var a1 = SymbolGraph.Relationship(source: "a.source", target: "a.target", kind: .conformsTo, targetFallback: nil)
        a1.mixins[NotHashableMixin<String>.mixinKey] = NotHashableMixin(value: "a.1.value")
        
        var a2 = SymbolGraph.Relationship(source: "a.source", target: "a.target", kind: .conformsTo, targetFallback: nil)
        a2.mixins[NotHashableMixin<String>.mixinKey] = NotHashableMixin(value: "a.2.value")
        
        XCTAssertEqual(Set([a1, a2]).count, 1)
    }
    
    /// Check that Hashable Mixins without any Mixin for the respective `mixinKey` on the other
    /// relationship fail equality.
    func testHashingWithMissingEquatableMixin() throws {
        var a1 = SymbolGraph.Relationship(source: "a.source", target: "a.target", kind: .conformsTo, targetFallback: nil)
        a1.mixins["1"] = SymbolGraph.Relationship.SourceOrigin(identifier: "a.1.origin", displayName: "a.1.origin")
        
        var a2 = SymbolGraph.Relationship(source: "a.source", target: "a.target", kind: .conformsTo, targetFallback: nil)
        a2.mixins["2"] = SymbolGraph.Relationship.SourceOrigin(identifier: "a.2.origin", displayName: "a.2.origin")
        
        XCTAssertEqual(Set([a1, a2]).count, 2)
    }
    
    /// Check that Non-Hashable Mixins without any Mixin for the respective `mixinKey` on the other
    /// relationship do not fail equality.
    func testHashingWithMissingNonEquatableMixin() throws {
        var a1 = SymbolGraph.Relationship(source: "a.source", target: "a.target", kind: .conformsTo, targetFallback: nil)
        a1.mixins["1"] = NotHashableMixin(value: 1)
        
        let a2 = SymbolGraph.Relationship(source: "a.source", target: "a.target", kind: .conformsTo, targetFallback: nil)
        
        XCTAssertEqual(Set([a1, a2]).count, 1)
    }
    
    /// Check that Mixins of different type that both do not implement Hashable
    /// are considered equal.
    func testHashingWithDifferentTypeNonHashableMixins() throws {
        var a1 = SymbolGraph.Relationship(source: "a.source", target: "a.target", kind: .conformsTo, targetFallback: nil)
        a1.mixins[NotHashableMixin<String>.mixinKey] = NotHashableMixin(value: "a.1.value")
        
        var a2 = SymbolGraph.Relationship(source: "a.source", target: "a.target", kind: .conformsTo, targetFallback: nil)
        a2.mixins[NotHashableMixin<Int>.mixinKey] = NotHashableMixin(value: 2)
        
        XCTAssertEqual(Set([a1, a2]).count, 1)
    }
    
    /// Check that Mixins of different type where one does implement Hashable
    /// are considered unequal.
    func testHashingWithDifferentTypeOneHashableMixinOneNonHashable() throws {
        // in this first test, equality should return false based on the count of equatable mixins
        var a1 = SymbolGraph.Relationship(source: "a.source", target: "a.target", kind: .conformsTo, targetFallback: nil)
        a1.mixins["a"] = NotHashableMixin(value: "a.1.value")
        
        var a2 = SymbolGraph.Relationship(source: "a.source", target: "a.target", kind: .conformsTo, targetFallback: nil)
        a2.mixins["a"] = SymbolGraph.Relationship.SourceOrigin(identifier: "a.2.origin", displayName: "a.2.origin")
        
        XCTAssertEqual(Set([a1, a2]).count, 2)
        
        // This test is interesting because the equality implementation of relationship
        // only iterates over the `lhs` mixins. Thus, depending on what relationship comes out
        // as the `lhs`, the equality might fail at different times (though it will always fail).
        // In this example, if `a1` is `lhs`, the comparison for `"a"` will be skipped (since the
        // lhs is not `Equatable`), but the comparision for `"b"` will return false.
        // In contrast, if `a2` is `lhs`, the comparison for `"a"` will return false right away.
        a1 = SymbolGraph.Relationship(source: "a.source", target: "a.target", kind: .conformsTo, targetFallback: nil)
        a1.mixins["a"] = NotHashableMixin(value: "a.1.value")
        a1.mixins["b"] = SymbolGraph.Relationship.SourceOrigin(identifier: "a.1.origin", displayName: "a.1.origin")
        
        a2 = SymbolGraph.Relationship(source: "a.source", target: "a.target", kind: .conformsTo, targetFallback: nil)
        a2.mixins["a"] = SymbolGraph.Relationship.SourceOrigin(identifier: "a.2.origin", displayName: "a.2.origin")
        a2.mixins["b"] = NotHashableMixin(value: "a.2.value")
        
        XCTAssertEqual(Set([a1, a2]).count, 2)
        XCTAssertEqual(Set([a2, a1]).count, 2)
    }
}

private struct NotHashableMixin<T>: Mixin where T: Codable {
    static var mixinKey: String { "nothashable" }
    
    let value: T
}
