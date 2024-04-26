/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2024 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
import Foundation
@testable import SymbolKit

class UnifiedGraphOverloadsTests: XCTestCase {
    func testUnifiedOverloadGroups() throws {
        let unifiedGraph = try unifySymbolGraphs(
            ("DemoKit-macos.symbols.json", makeOverloadsSymbolGraph(platform: "macosx", withOverloads: [1, 2]))
        )

        let overloadSymbols = [1, 2].map(\.asOverloadIdentifier)
        let expectedOverloadGroupIdentifier = 1.asOverloadIdentifier + SymbolGraph.Symbol.overloadGroupIdentifierSuffix

        let allRelations = unifiedGraph.unifiedRelationships

        // Make sure that overloadOf relationships were added
        let overloadRelations = allRelations.filter({ $0.kind == .overloadOf })
        XCTAssertEqual(overloadRelations.count, 2)
        XCTAssertEqual(Set(overloadRelations.map(\.target)).count, 1)
        XCTAssertEqual(Set(overloadRelations.map(\.source)), Set(overloadSymbols))

        // Pull out the overload group's identifier and make sure that it exists
        let overloadGroupIdentifier = try XCTUnwrap(overloadRelations.first?.target)
        XCTAssertEqual(overloadGroupIdentifier, expectedOverloadGroupIdentifier)
        XCTAssert(unifiedGraph.symbols.keys.contains(overloadGroupIdentifier))

        // Make sure that the individual overloads reference the overload group and their index properly
        for overloadIndex in overloadSymbols.indices {
            let overloadIdentifier = overloadSymbols[overloadIndex]
            let overloadSymbol = try XCTUnwrap(unifiedGraph.symbols[overloadIdentifier])
            let overloadData = try XCTUnwrap(overloadSymbol.unifiedOverloadData)
            XCTAssertEqual(overloadData.overloadGroupIdentifier, expectedOverloadGroupIdentifier)
            XCTAssertEqual(overloadData.overloadGroupIndex, overloadIndex)
        }
    }

    func testUnifiedOverloadGroupsAcrossPlatforms() throws {
        let unifiedGraph = try unifySymbolGraphs(
            ("DemoKit-macos.symbols.json", makeOverloadsSymbolGraph(platform: "macosx", withOverloads: [1, 2])),
            ("DemoKit-ios.symbols.json", makeOverloadsSymbolGraph(platform: "ios", withOverloads: [1, 2]))
        )

        let overloadSymbols = [1, 2].map(\.asOverloadIdentifier)
        let expectedOverloadGroupIdentifier = 1.asOverloadIdentifier + SymbolGraph.Symbol.overloadGroupIdentifierSuffix

        let allRelations = unifiedGraph.unifiedRelationships

        // Make sure that overloadOf relationships were added
        let overloadRelations = allRelations.filter({ $0.kind == .overloadOf })
        XCTAssertEqual(overloadRelations.count, 2)
        XCTAssertEqual(Set(overloadRelations.map(\.target)).count, 1)
        XCTAssertEqual(Set(overloadRelations.map(\.source)), Set(overloadSymbols))

        // Pull out the overload group's identifier and make sure that it exists
        let overloadGroupIdentifier = try XCTUnwrap(overloadRelations.first?.target)
        XCTAssertEqual(overloadGroupIdentifier, expectedOverloadGroupIdentifier)
        XCTAssert(unifiedGraph.symbols.keys.contains(overloadGroupIdentifier))

        // Make sure that the individual overloads reference the overload group and their index properly
        for overloadIndex in overloadSymbols.indices {
            let overloadIdentifier = overloadSymbols[overloadIndex]
            let overloadSymbol = try XCTUnwrap(unifiedGraph.symbols[overloadIdentifier])
            let overloadData = try XCTUnwrap(overloadSymbol.unifiedOverloadData)
            XCTAssertEqual(overloadData.overloadGroupIdentifier, expectedOverloadGroupIdentifier)
            XCTAssertEqual(overloadData.overloadGroupIndex, overloadIndex)
        }
    }

    func testOnePlatformDoesntOverload() throws {
        let unifiedGraph = try unifySymbolGraphs(
            ("DemoKit-macos.symbols.json", makeOverloadsSymbolGraph(platform: "macosx", withOverloads: [1])),
            ("DemoKit-ios.symbols.json", makeOverloadsSymbolGraph(platform: "ios", withOverloads: [1, 2]))
        )

        let overloadSymbols = [1, 2].map(\.asOverloadIdentifier)
        let expectedOverloadGroupIdentifier = 1.asOverloadIdentifier + SymbolGraph.Symbol.overloadGroupIdentifierSuffix

        let allRelations = unifiedGraph.unifiedRelationships

        // Make sure that overloadOf relationships were added
        let overloadRelations = allRelations.filter({ $0.kind == .overloadOf })
        XCTAssertEqual(overloadRelations.count, 2)
        XCTAssertEqual(Set(overloadRelations.map(\.target)).count, 1)
        XCTAssertEqual(Set(overloadRelations.map(\.source)), Set(overloadSymbols))

        // Pull out the overload group's identifier and make sure that it exists
        let overloadGroupIdentifier = try XCTUnwrap(overloadRelations.first?.target)
        XCTAssertEqual(overloadGroupIdentifier, expectedOverloadGroupIdentifier)
        XCTAssert(unifiedGraph.symbols.keys.contains(overloadGroupIdentifier))

        // Make sure that the individual overloads reference the overload group and their index properly
        for overloadIndex in overloadSymbols.indices {
            let overloadIdentifier = overloadSymbols[overloadIndex]
            let overloadSymbol = try XCTUnwrap(unifiedGraph.symbols[overloadIdentifier])
            let overloadData = try XCTUnwrap(overloadSymbol.unifiedOverloadData)
            XCTAssertEqual(overloadData.overloadGroupIdentifier, expectedOverloadGroupIdentifier)
            XCTAssertEqual(overloadData.overloadGroupIndex, overloadIndex)
        }
    }

    func testDisjointOverloadGroups() throws {
        let unifiedGraph = try unifySymbolGraphs(
            ("DemoKit-macos.symbols.json", makeOverloadsSymbolGraph(platform: "macosx", withOverloads: [1, 2])),
            ("DemoKit-ios.symbols.json", makeOverloadsSymbolGraph(platform: "ios", withOverloads: [1, 3]))
        )

        let overloadSymbols = [1, 2, 3].map(\.asOverloadIdentifier)
        let expectedOverloadGroupIdentifier = 1.asOverloadIdentifier + SymbolGraph.Symbol.overloadGroupIdentifierSuffix

        let allRelations = unifiedGraph.unifiedRelationships

        // Make sure that overloadOf relationships were added
        let overloadRelations = allRelations.filter({ $0.kind == .overloadOf })
        XCTAssertEqual(overloadRelations.count, 3)
        XCTAssertEqual(Set(overloadRelations.map(\.target)).count, 1)
        XCTAssertEqual(Set(overloadRelations.map(\.source)), Set(overloadSymbols))

        // Pull out the overload group's identifier and make sure that it exists
        let overloadGroupIdentifier = try XCTUnwrap(overloadRelations.first?.target)
        XCTAssertEqual(overloadGroupIdentifier, expectedOverloadGroupIdentifier)
        XCTAssert(unifiedGraph.symbols.keys.contains(overloadGroupIdentifier))

        // Make sure that the individual overloads reference the overload group and their index properly
        for overloadIndex in overloadSymbols.indices {
            let overloadIdentifier = overloadSymbols[overloadIndex]
            let overloadSymbol = try XCTUnwrap(unifiedGraph.symbols[overloadIdentifier])
            let overloadData = try XCTUnwrap(overloadSymbol.unifiedOverloadData)
            XCTAssertEqual(overloadData.overloadGroupIdentifier, expectedOverloadGroupIdentifier)
            XCTAssertEqual(overloadData.overloadGroupIndex, overloadIndex)
        }
    }

    func testRemoveExtraOverloadGroups() throws {
        let unifiedGraph = try unifySymbolGraphs(
            ("DemoKit-macos.symbols.json", makeOverloadsSymbolGraph(platform: "macosx", withOverloads: [1, 2])),
            ("DemoKit-ios.symbols.json", makeOverloadsSymbolGraph(platform: "ios", withOverloads: [2, 3]))
        )

        let overloadSymbols = [1, 2, 3].map(\.asOverloadIdentifier)
        let expectedOverloadGroupIdentifier = 1.asOverloadIdentifier + SymbolGraph.Symbol.overloadGroupIdentifierSuffix

        let allRelations = unifiedGraph.unifiedRelationships

        // Make sure that overloadOf relationships were added
        let overloadRelations = allRelations.filter({ $0.kind == .overloadOf })
        XCTAssertEqual(overloadRelations.count, 3)
        XCTAssertEqual(Set(overloadRelations.map(\.target)).count, 1)
        XCTAssertEqual(Set(overloadRelations.map(\.source)), Set(overloadSymbols))

        // Pull out the overload group's identifier and make sure that it exists
        let overloadGroupIdentifier = try XCTUnwrap(overloadRelations.first?.target)
        XCTAssertEqual(overloadGroupIdentifier, expectedOverloadGroupIdentifier)
        XCTAssert(unifiedGraph.symbols.keys.contains(overloadGroupIdentifier))

        // Make sure that the individual overloads reference the overload group and their index properly
        for overloadIndex in overloadSymbols.indices {
            let overloadIdentifier = overloadSymbols[overloadIndex]
            let overloadSymbol = try XCTUnwrap(unifiedGraph.symbols[overloadIdentifier])
            let overloadData = try XCTUnwrap(overloadSymbol.unifiedOverloadData)
            XCTAssertEqual(overloadData.overloadGroupIdentifier, expectedOverloadGroupIdentifier)
            XCTAssertEqual(overloadData.overloadGroupIndex, overloadIndex)
        }

        // Also make sure that the iOS overload group was dropped from the unified graph
        let iOSOverloadGroupIdentifier = 2.asOverloadIdentifier + SymbolGraph.Symbol.overloadGroupIdentifierSuffix
        XCTAssertFalse(unifiedGraph.symbols.keys.contains(iOSOverloadGroupIdentifier))
        XCTAssertFalse(allRelations.contains(where: {
            $0.target == iOSOverloadGroupIdentifier || $0.source == iOSOverloadGroupIdentifier
        }))
    }
}

private extension Int {
    var asOverloadIdentifier: String {
        "s:SomeClass:someMethod-\(self)"
    }
}

private extension UnifiedSymbolGraph {
    var unifiedRelationships: [SymbolGraph.Relationship] {
        struct RelationKey: Hashable {
            let source: String
            let target: String
            let kind: SymbolGraph.Relationship.Kind

            init(fromRelation relationship: SymbolGraph.Relationship) {
                self.source = relationship.source
                self.target = relationship.target
                self.kind = relationship.kind
            }

            static func makePair(fromRelation relationship: SymbolGraph.Relationship) -> (RelationKey, SymbolGraph.Relationship) {
                return (RelationKey(fromRelation: relationship), relationship)
            }
        }

        let allRelations = Dictionary(relationshipsByLanguage.values.joined().map({ RelationKey.makePair(fromRelation: $0) }), uniquingKeysWith: { r1, r2 in r1 })

        return Array(allRelations.values)
    }
}

private func makeOverloadsSymbolGraph(platform: String, withOverloads methodIndices: [Int]) -> SymbolGraph {
    let symbols: [SymbolGraph.Symbol] = [
        .init(
            identifier: .init(precise: "s:SomeClass", interfaceLanguage: "swift"),
            names: .init(title: "SomeClass", navigator: nil, subHeading: nil, prose: nil),
            pathComponents: ["SomeClass"],
            docComment: nil,
            accessLevel: .init(rawValue: "public"),
            kind: .init(parsedIdentifier: .class, displayName: "Class"),
            mixins: [:]),
    ] + methodIndices.map({ index in
        .init(
            identifier: .init(precise: index.asOverloadIdentifier, interfaceLanguage: "swift"),
            names: .init(title: "someMethod()", navigator: nil, subHeading: nil, prose: nil),
            pathComponents: ["SomeClass", "someMethod"],
            docComment: nil,
            accessLevel: .init(rawValue: "public"),
            kind: .init(parsedIdentifier: .method, displayName: "Instance Method"),
            mixins: [:])
    })
    let relations: [SymbolGraph.Relationship] = methodIndices.map({ index in
            .init(source: index.asOverloadIdentifier,
              target: "s:SomeClass",
              kind: .memberOf,
              targetFallback: nil)
    })

    return makeSymbolGraph(platform: platform, symbols: symbols, relations: relations)
}

private func makeSymbolGraph(platform: String, symbols: [SymbolGraph.Symbol], relations: [SymbolGraph.Relationship]) -> SymbolGraph {
    let metadata = SymbolGraph.Metadata(
        formatVersion: .init(major: 1, minor: 0, patch: 0),
        generator: "unit-test"
    )
    let module = SymbolGraph.Module(
        name: "DemoKit",
        platform: .init(
            architecture: "x86_64",
            vendor: "apple",
            operatingSystem: .init(name: platform),
            environment: nil
        )
    )
    var graph = SymbolGraph(
        metadata: metadata,
        module: module,
        symbols: symbols,
        relationships: relations
    )
    graph.createOverloadGroupSymbols()
    return graph
}

private func unifySymbolGraphs(
    moduleName: String = "DemoKit",
    _ graphs: (fileName: String, symbolGraph: SymbolGraph)...,
    file: StaticString = #file,
    line: UInt = #line
) throws -> UnifiedSymbolGraph {
    let collector = GraphCollector()
    for (fileName, symbolGraph) in graphs {
        collector.mergeSymbolGraph(symbolGraph, at: .init(fileURLWithPath: fileName))
    }
    return try XCTUnwrap(collector.finishLoading().unifiedGraphs[moduleName], file: file, line: line)
}
