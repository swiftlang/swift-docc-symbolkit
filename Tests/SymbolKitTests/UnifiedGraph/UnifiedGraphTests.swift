/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2022 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
import Foundation
@testable import SymbolKit

class UnifiedGraphTests: XCTestCase {
    /// Verify that ``UnifiedSymbolGraph`` sorts relationships correctly in the basic case.
    func testUnifyRelations() throws {
        let collector = GraphCollector()
        collector.mergeSymbolGraph(swiftSymbolGraph(), at: .init(fileURLWithPath: "swift/DemoKit.symbols.json"))
        collector.mergeSymbolGraph(objcSymbolGraph(), at: .init(fileURLWithPath: "objc/DemoKit.symbols.json"))

        let (unifiedGraphs, _) = collector.finishLoading()
        let demoGraph = try XCTUnwrap(unifiedGraphs["DemoKit"])

        if let swiftRelations = demoGraph.relationshipsByLanguage.first(where: { $0.key.interfaceLanguage == "swift" })?.value {
            compareRelationships(swiftRelations, swiftSymbolGraph().relationships)
        } else {
            XCTFail("Unified graph did not have swift relationships")
        }

        if let objcRelations = demoGraph.relationshipsByLanguage.first(where: { $0.key.interfaceLanguage == "objc" })?.value {
            compareRelationships(objcRelations, objcSymbolGraph().relationships)
        } else {
            XCTFail("Unified graph did not have objc relationships")
        }
    }
}

/// Compare the given lists of relationships and assert that they contain the same relationships.
private func compareRelationships(_ left: [SymbolGraph.Relationship], _ right: [SymbolGraph.Relationship]) {
    func compareRelations(_ l: SymbolGraph.Relationship, _ r: SymbolGraph.Relationship) -> Bool {
        if l.source < r.source {
            return true
        } else if l.source == r.source && l.target < r.target {
            return true
        } else if l.source == r.source && l.target == r.target && l.kind.rawValue < r.kind.rawValue {
            return true
        } else {
            return false
        }
    }

    func assertRelations(_ l: SymbolGraph.Relationship, _ r: SymbolGraph.Relationship) {
        XCTAssertEqual(l.source, r.source)
        XCTAssertEqual(l.target, r.target)
        XCTAssertEqual(l.kind, r.kind)
        XCTAssertEqual(l.targetFallback, r.targetFallback)
    }

    let leftSorted = left.sorted(by: compareRelations(_:_:))
    let rightSorted = right.sorted(by: compareRelations(_:_:))

    for (l, r) in zip(leftSorted, rightSorted) {
        assertRelations(l, r)
    }
}

private func swiftSymbolGraph() -> SymbolGraph {
    let symbols: [SymbolGraph.Symbol] = [
        .init(
            identifier: .init(precise: "c:objc(cs)PlayingCard", interfaceLanguage: "swift"),
            names: .init(title: "PlayingCard", navigator: nil, subHeading: nil, prose: nil),
            pathComponents: ["PlayingCard"],
            docComment: nil,
            accessLevel: .init(rawValue: "open"),
            kind: .init(parsedIdentifier: .class, displayName: "Class"),
            mixins: [:]
        ),
        .init(
            identifier: .init(precise: "c:objc(pl)ColorDetecting", interfaceLanguage: "swift"),
            names: .init(title: "ColorDetecting", navigator: nil, subHeading: nil, prose: nil),
            pathComponents: ["ColorDetecting"],
            docComment: nil,
            accessLevel: .init(rawValue: "public"),
            kind: .init(parsedIdentifier: .protocol, displayName: "Protocol"),
            mixins: [:]
        )
    ]

    let relations: [SymbolGraph.Relationship] = [
        .init(
            source: "c:objc(cs)PlayingCard",
            target: "c:objc(pl)ColorDetecting",
            kind: .conformsTo,
            targetFallback: nil
        ),
        .init(
            source: "c:objc(cs)PlayingCard",
            target: "c:objc(pl)NSObject",
            kind: .inheritsFrom,
            targetFallback: "ObjectiveC.NSObject"
        ),
        .init(
            source: "c:objc(cs)PlayingCard",
            target: "s:SH",
            kind: .conformsTo,
            targetFallback: "Swift.Hashable"
        )
    ]

    return makeSymbolGraph(symbols: symbols, relations: relations)
}

private func objcSymbolGraph() -> SymbolGraph {
    let symbols: [SymbolGraph.Symbol] = [
        .init(
            identifier: .init(precise: "c:objc(cs)PlayingCard", interfaceLanguage: "objc"),
            names: .init(title: "PlayingCard", navigator: nil, subHeading: nil, prose: nil),
            pathComponents: ["PlayingCard"],
            docComment: nil,
            accessLevel: .init(rawValue: "public"),
            kind: .init(parsedIdentifier: .class, displayName: "Class"),
            mixins: [:]
        ),
        .init(
            identifier: .init(precise: "c:objc(pl)ColorDetecting", interfaceLanguage: "objc"),
            names: .init(title: "ColorDetecting", navigator: nil, subHeading: nil, prose: nil),
            pathComponents: ["ColorDetecting"],
            docComment: nil,
            accessLevel: .init(rawValue: "public"),
            kind: .init(parsedIdentifier: .protocol, displayName: "Protocol"),
            mixins: [:]
        )
    ]

    let relations: [SymbolGraph.Relationship] = [
        .init(
            source: "c:objc(cs)PlayingCard",
            target: "c:objc(pl)ColorDetecting",
            kind: .conformsTo,
            targetFallback: nil
        ),
        .init(
            source: "c:objc(cs)PlayingCard",
            target: "c:objc(pl)NSObject",
            kind: .inheritsFrom,
            targetFallback: "NSObject"
        )
    ]

    return makeSymbolGraph(symbols: symbols, relations: relations)
}

private func makeSymbolGraph(symbols: [SymbolGraph.Symbol], relations: [SymbolGraph.Relationship]) -> SymbolGraph {
    let metadata = SymbolGraph.Metadata(
        formatVersion: .init(major: 1, minor: 0, patch: 0),
        generator: "unit-test"
    )
    let module = SymbolGraph.Module(
        name: "DemoKit",
        platform: .init(
            architecture: "x86_64",
            vendor: "apple",
            operatingSystem: .init(name: "macosx"),
            environment: nil
        )
    )
    return SymbolGraph(
        metadata: metadata,
        module: module,
        symbols: symbols,
        relationships: relations
    )
}
