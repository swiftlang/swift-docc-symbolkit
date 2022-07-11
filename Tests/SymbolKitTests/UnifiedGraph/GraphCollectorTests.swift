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

class GraphCollectorTests: XCTestCase {
    /// Verify that extension graphs are merged with the correct main graph depending on
    /// the chosen strategy.
    func testExtensionGraphMergingStrategies() throws {
        let a = SymbolGraph(metadata: .init(formatVersion: .init(major: 1, minor: 0, patch: 0), generator: "unit-test"),
                            module: .init(name: "A", platform: .init()),
                            symbols: [
                                .init(identifier: .init(precise: "s:AA", interfaceLanguage: "swift"),
                                      names: .init(title: "A", navigator: nil, subHeading: nil, prose: nil),
                                      pathComponents: ["A"],
                                      docComment: nil,
                                      accessLevel: .init(rawValue: "public"),
                                      kind: .init(parsedIdentifier: .class, displayName: "Class"),
                                      mixins: [:])
                            ],
                            relationships: [])
        
        let b = SymbolGraph(metadata: .init(formatVersion: .init(major: 1, minor: 0, patch: 0), generator: "unit-test"),
                            module: .init(name: "B", platform: .init()),
                            symbols: [
                                .init(identifier: .init(precise: "s:BB", interfaceLanguage: "swift"),
                                      names: .init(title: "B", navigator: nil, subHeading: nil, prose: nil),
                                      pathComponents: ["B"],
                                      docComment: nil,
                                      accessLevel: .init(rawValue: "public"),
                                      kind: .init(parsedIdentifier: .class, displayName: "Class"),
                                      mixins: [:])
                            ],
                            relationships: [])
        
        let a_At_B = SymbolGraph(metadata: .init(formatVersion: .init(major: 1, minor: 0, patch: 0), generator: "unit-test"),
                            module: .init(name: "A", platform: .init()),
                            symbols: [
                                .init(identifier: .init(precise: "s:BBAatB", interfaceLanguage: "swift"),
                                      names: .init(title: "AatB", navigator: nil, subHeading: nil, prose: nil),
                                      pathComponents: ["B", "AatB"],
                                      docComment: nil,
                                      accessLevel: .init(rawValue: "public"),
                                      kind: .init(parsedIdentifier: .class, displayName: "Class"),
                                      mixins: [:])
                            ],
                            relationships: [])
        
        
        // test with default strategy (extension graphs get attached to extend**ed** graph
        var collector = GraphCollector()

        collector.mergeSymbolGraph(a, at: .init(fileURLWithPath: "A.symbols.json"))
        collector.mergeSymbolGraph(b, at: .init(fileURLWithPath: "B.symbols.json"))
        collector.mergeSymbolGraph(a_At_B, at: .init(fileURLWithPath: "A@B.symbols.json"))
        
        var (unifiedGraphs, _) = collector.finishLoading()
        
        XCTAssertEqual(unifiedGraphs.count, 2)
        
        for graph in unifiedGraphs.values {
            if graph.moduleName == "A" {
                XCTAssertEqual(graph.symbols.count, 1)
                XCTAssertTrue(graph.symbols.keys.contains("s:AA"))
            } else if graph.moduleName == "B" {
                XCTAssertEqual(graph.symbols.count, 2)
                XCTAssertTrue(graph.symbols.keys.contains("s:BB"))
                XCTAssertTrue(graph.symbols.keys.contains("s:BBAatB"))
            } else {
                XCTFail()
            }
        }
        
        // test with extendingGraph association strategy (extension graphs get attached to extend**ing** graph
        collector = GraphCollector(strategy: .init(extensionGraphAssociation: .extendingGraph))
        
        collector.mergeSymbolGraph(a, at: .init(fileURLWithPath: "A.symbols.json"))
        collector.mergeSymbolGraph(b, at: .init(fileURLWithPath: "B.symbols.json"))
        collector.mergeSymbolGraph(a_At_B, at: .init(fileURLWithPath: "A@B.symbols.json"))
        
        (unifiedGraphs, _) = collector.finishLoading()
        
        XCTAssertEqual(unifiedGraphs.count, 2)
        
        for graph in unifiedGraphs.values {
            if graph.moduleName == "A" {
                XCTAssertEqual(graph.symbols.count, 2)
                XCTAssertTrue(graph.symbols.keys.contains("s:AA"))
                XCTAssertTrue(graph.symbols.keys.contains("s:BBAatB"))
            } else if graph.moduleName == "B" {
                XCTAssertEqual(graph.symbols.count, 1)
                XCTAssertTrue(graph.symbols.keys.contains("s:BB"))
            } else {
                XCTFail()
            }
        }
    }
}
