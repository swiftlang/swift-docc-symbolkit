/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2022-2024 Apple Inc. and the Swift project authors
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

    func testOrphanRelationships() throws {
        var swiftSyms = swiftSymbolGraph()
        swiftSyms.relationships.append(.init(
            source: "unknownIdentifier",
            target: "unknownProtocol",
            kind: .conformsTo,
            targetFallback: nil))

        let collector = GraphCollector()
        collector.mergeSymbolGraph(swiftSyms, at: .init(fileURLWithPath: "swift/DemoKit.symbols.json"))
        collector.mergeSymbolGraph(objcSymbolGraph(), at: .init(fileURLWithPath: "objc/DemoKit.symbols.json"))

        let (unifiedGraphs, _) = collector.finishLoading()
        let demoGraph = try XCTUnwrap(unifiedGraphs["DemoKit"])

        XCTAssertEqual(demoGraph.orphanRelationships.count, 1)
        XCTAssertEqual(demoGraph.orphanRelationships, [
            .init(
                source: "unknownIdentifier",
                target: "unknownProtocol",
                kind: .conformsTo,
                targetFallback: nil)
        ])
    }

    func testCollectOrphanRelationships() throws {
        var swiftSyms = swiftSymbolGraph()
        swiftSyms.relationships.append(.init(
            source: "unknownIdentifier",
            target: "unknownProtocol",
            kind: .conformsTo,
            targetFallback: nil))

        var objcSyms = objcSymbolGraph()
        objcSyms.symbols["unknownProtocol"] = .init(
            identifier: .init(precise: "unknownProtocol", interfaceLanguage: "objc"),
            names: .init(title: "unknownProtocol", navigator: nil, subHeading: nil, prose: nil),
            pathComponents: ["unknownProtocol"],
            docComment: nil,
            accessLevel: .init(rawValue: "public"),
            kind: .init(parsedIdentifier: .protocol, displayName: "Protocol"),
            mixins: [:])

        let collector = GraphCollector()
        collector.mergeSymbolGraph(swiftSyms, at: .init(fileURLWithPath: "swift/DemoKit.symbols.json"))
        collector.mergeSymbolGraph(objcSyms, at: .init(fileURLWithPath: "objc/DemoKit.symbols.json"))

        let (unifiedGraphs, _) = collector.finishLoading()
        let demoGraph = try XCTUnwrap(unifiedGraphs["DemoKit"])

        XCTAssert(demoGraph.orphanRelationships.isEmpty)

        // Since the only matching symbol in this relationship was `unknownProtocol` in the objc
        // graph, the relation is only sorted among the objc relationships, even though it appeared
        // in a "Swift" symbol graph. This is because even though in practice all the symbols in a
        // single graph have the same source language, the symbol graph itself does not define a
        // source language as a whole. In practice this is unlikely to be a problem, but it could be
        // a surprising behavior for new symbol graph implementors.
        let objcRelations = try XCTUnwrap(demoGraph.relationshipsByLanguage.first(where: { $0.key.interfaceLanguage == "objc" })?.value)
        XCTAssert(objcRelations.contains(where: { $0.target == "unknownProtocol" }))
    }

    func testCollectExtensionGraph() throws {
        let baseSyms = swiftSymbolGraph()

        var extensionSyms = makeSymbolGraph(
            symbols: [
                .init(
                    identifier: .init(precise: "s:SomeStruct", interfaceLanguage: "swift"),
                    names: .init(title: "SomeStruct", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["PlayingCard", "SomeStruct"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .struct, displayName: "Structure"),
                    mixins: [:]
                )
            ],
            relations: [
                .init(
                    source: "s:SomeStruct",
                    target: "c:objc(cs)PlayingCard",
                    kind: .memberOf,
                    targetFallback: "DemoKit.PlayingCard")
            ]
        )
        extensionSyms.module.name = "OtherKit"

        let collector = GraphCollector()
        collector.mergeSymbolGraph(baseSyms, at: .init(fileURLWithPath: "DemoKit.symbols.json"))
        collector.mergeSymbolGraph(extensionSyms, at: .init(fileURLWithPath: "OtherKit@DemoKit.symbols.json"))

        let (unifiedGraphs, _) = collector.finishLoading()

        XCTAssertFalse(unifiedGraphs.keys.contains("OtherKit"))
        let demoGraph = try XCTUnwrap(unifiedGraphs["DemoKit"])
        let extensionSym = try XCTUnwrap(demoGraph.symbols["s:SomeStruct"])
        let extensionSymModule = try XCTUnwrap(extensionSym.modules[.init(forSymbolGraph: extensionSyms)!])
        XCTAssertEqual(extensionSymModule.name, "OtherKit")
    }

    func testCreateOverloadGroupSymbols() throws {
        // - SomeClass
        //   - someMethod() [x2]
        let symbolGraph = makeSymbolGraph(
            symbols: [
                .init(
                    identifier: .init(precise: "s:SomeClass", interfaceLanguage: "swift"),
                    names: .init(title: "SomeClass", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["SomeClass"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .class, displayName: "Class"),
                    mixins: [:]),
                .init(
                    identifier: .init(precise: "s:SomeClass:someMethod-1", interfaceLanguage: "swift"),
                    names: .init(title: "someMethod()", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["SomeClass", "someMethod"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .method, displayName: "Instance Method"),
                    mixins: [:]),
                .init(
                    identifier: .init(precise: "s:SomeClass:someMethod-2", interfaceLanguage: "swift"),
                    names: .init(title: "someMethod()", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["SomeClass", "someMethod"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .method, displayName: "Instance Method"),
                    mixins: [:]),
            ],
            relations: [
                .init(source: "s:SomeClass:someMethod-1",
                      target: "s:SomeClass",
                      kind: .memberOf,
                      targetFallback: nil),
                .init(source: "s:SomeClass:someMethod-2",
                      target: "s:SomeClass",
                      kind: .memberOf,
                      targetFallback: nil),
            ]
        )

        do {
            let collector = GraphCollector()
            collector.mergeSymbolGraph(symbolGraph, at: .init(fileURLWithPath: "DemoKit.symbols.json"))
            let (unifiedGraphs, _) = collector.finishLoading(createOverloadGroups: true)

            let demoGraph = try XCTUnwrap(unifiedGraphs["DemoKit"])
            // There was only one symbol graph, so there should only be one selector
            let relationships = try XCTUnwrap(demoGraph.relationshipsByLanguage.values.first)

            // Make sure that overloadOf relationships were added
            let overloadRelations = relationships.filter({ $0.kind == .overloadOf })
            XCTAssertEqual(overloadRelations.count, 2)
            XCTAssertEqual(Set(overloadRelations.map(\.target)).count, 1)
            XCTAssertEqual(Set(overloadRelations.map(\.source)), ["s:SomeClass:someMethod-1", "s:SomeClass:someMethod-2"])

            // Pull out the overload group's identifier and make sure that it exists
            let overloadGroupIdentifier = try XCTUnwrap(overloadRelations.first?.target)
            XCTAssert(overloadGroupIdentifier.hasSuffix("::OverloadGroup"))
            XCTAssert(demoGraph.symbols.keys.contains(overloadGroupIdentifier))

            // Make sure that the existing memberOf relationship was cloned onto the overload group
            let overloadGroupRelations = relationships.filter({ $0.source == overloadGroupIdentifier })
            XCTAssertEqual(overloadGroupRelations.count, 1)
            XCTAssertEqual(overloadGroupRelations.first?.kind, .memberOf)
            XCTAssertEqual(overloadGroupRelations.first?.target, "s:SomeClass")
        }

        // Also check that overload groups are not created when the language is restricted
        do {
            let collector = GraphCollector()
            collector.mergeSymbolGraph(symbolGraph, at: .init(fileURLWithPath: "DemoKit.symbols.json"))
            let (unifiedGraphs, _) = collector.finishLoading(createOverloadGroups: true, restrictOverloadGroupLanguages: ["cpp"])

            let demoGraph = try XCTUnwrap(unifiedGraphs["DemoKit"])
            // There was only one symbol graph, so there should only be one selector
            let relationships = try XCTUnwrap(demoGraph.relationshipsByLanguage.values.first)

            XCTAssertFalse(relationships.contains(where: { $0.kind == .overloadOf }))
            XCTAssertFalse(demoGraph.symbols.keys.contains(where: { $0.hasSuffix("::OverloadGroup") }))
        }
    }

    func testCreateDifferentOverloadGroupSymbolsPerKind() throws {
        // - SomeClass
        //   - someMethod() [instance method, x2]
        //   - someMethod() [class method, x2]
        let symbolGraph = makeSymbolGraph(
            symbols: [
                .init(
                    identifier: .init(precise: "s:SomeClass", interfaceLanguage: "swift"),
                    names: .init(title: "SomeClass", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["SomeClass"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .class, displayName: "Class"),
                    mixins: [:]),
                .init(
                    identifier: .init(precise: "s:SomeClass:someMethod-1", interfaceLanguage: "swift"),
                    names: .init(title: "someMethod()", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["SomeClass", "someMethod"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .method, displayName: "Instance Method"),
                    mixins: [:]),
                .init(
                    identifier: .init(precise: "s:SomeClass:someMethod-2", interfaceLanguage: "swift"),
                    names: .init(title: "someMethod()", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["SomeClass", "someMethod"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .method, displayName: "Instance Method"),
                    mixins: [:]),
                .init(
                    identifier: .init(precise: "s:SomeClass:someMethod-3", interfaceLanguage: "swift"),
                    names: .init(title: "someMethod()", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["SomeClass", "someMethod"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .typeMethod, displayName: "Class Method"),
                    mixins: [:]),
                .init(
                    identifier: .init(precise: "s:SomeClass:someMethod-4", interfaceLanguage: "swift"),
                    names: .init(title: "someMethod()", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["SomeClass", "someMethod"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .typeMethod, displayName: "Class Method"),
                    mixins: [:]),
            ],
            relations: [
                .init(source: "s:SomeClass:someMethod-1",
                      target: "s:SomeClass",
                      kind: .memberOf,
                      targetFallback: nil),
                .init(source: "s:SomeClass:someMethod-2",
                      target: "s:SomeClass",
                      kind: .memberOf,
                      targetFallback: nil),
                .init(source: "s:SomeClass:someMethod-3",
                      target: "s:SomeClass",
                      kind: .memberOf,
                      targetFallback: nil),
                .init(source: "s:SomeClass:someMethod-4",
                      target: "s:SomeClass",
                      kind: .memberOf,
                      targetFallback: nil),
            ]
        )

        let collector = GraphCollector()
        collector.mergeSymbolGraph(symbolGraph, at: .init(fileURLWithPath: "DemoKit.symbols.json"))
        let (unifiedGraphs, _) = collector.finishLoading(createOverloadGroups: true)

        let demoGraph = try XCTUnwrap(unifiedGraphs["DemoKit"])
        // There was only one symbol graph, so there should only be one selector
        let relationships = try XCTUnwrap(demoGraph.relationshipsByLanguage.values.first)

        // Make sure that the overloaded symbols all received an overloadOf relation
        let overloadRelations = relationships.filter({ $0.kind == .overloadOf })
        XCTAssertEqual(overloadRelations.count, 4)

        // Pull out the overload group symbols. There should be two of them - one for the instance
        // method, one for the class method
        let overloadGroups = Set(overloadRelations.map(\.target))
        XCTAssertEqual(overloadGroups.count, 2)
        let overloadGroupSymbols = try overloadGroups.map({ try XCTUnwrap(demoGraph.symbols[$0]) })
        XCTAssertEqual(Set(overloadGroupSymbols.map(\.kind.first?.value.identifier)), [.method, .typeMethod])
    }

    func testCreateDifferentOverloadGroupsPerPath() throws {
        // - SomeClass
        //   - someMethod() [x2]
        // - OtherClass
        //   - someMethod() [x2]
        let symbolGraph = makeSymbolGraph(
            symbols: [
                .init(
                    identifier: .init(precise: "s:SomeClass", interfaceLanguage: "swift"),
                    names: .init(title: "SomeClass", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["SomeClass"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .class, displayName: "Class"),
                    mixins: [:]),
                .init(
                    identifier: .init(precise: "s:SomeClass:someMethod-1", interfaceLanguage: "swift"),
                    names: .init(title: "someMethod()", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["SomeClass", "someMethod"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .method, displayName: "Instance Method"),
                    mixins: [:]),
                .init(
                    identifier: .init(precise: "s:SomeClass:someMethod-2", interfaceLanguage: "swift"),
                    names: .init(title: "someMethod()", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["SomeClass", "someMethod"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .method, displayName: "Instance Method"),
                    mixins: [:]),
                .init(
                    identifier: .init(precise: "s:OtherClass", interfaceLanguage: "swift"),
                    names: .init(title: "OtherClass", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["OtherClass"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .class, displayName: "Class"),
                    mixins: [:]),
                .init(
                    identifier: .init(precise: "s:OtherClass:someMethod-1", interfaceLanguage: "swift"),
                    names: .init(title: "someMethod()", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["OtherClass", "someMethod"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .method, displayName: "Instance Method"),
                    mixins: [:]),
                .init(
                    identifier: .init(precise: "s:OtherClass:someMethod-2", interfaceLanguage: "swift"),
                    names: .init(title: "someMethod()", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["OtherClass", "someMethod"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .method, displayName: "Instance Method"),
                    mixins: [:]),
            ],
            relations: [
                .init(source: "s:SomeClass:someMethod-1",
                      target: "s:SomeClass",
                      kind: .memberOf,
                      targetFallback: nil),
                .init(source: "s:SomeClass:someMethod-2",
                      target: "s:SomeClass",
                      kind: .memberOf,
                      targetFallback: nil),
                .init(source: "s:OtherClass:someMethod-1",
                      target: "s:OtherClass",
                      kind: .memberOf,
                      targetFallback: nil),
                .init(source: "s:OtherClass:someMethod-2",
                      target: "s:OtherClass",
                      kind: .memberOf,
                      targetFallback: nil),
            ]
        )

        let collector = GraphCollector()
        collector.mergeSymbolGraph(symbolGraph, at: .init(fileURLWithPath: "DemoKit.symbols.json"))
        let (unifiedGraphs, _) = collector.finishLoading(createOverloadGroups: true)

        let demoGraph = try XCTUnwrap(unifiedGraphs["DemoKit"])
        // There was only one symbol graph, so there should only be one selector
        let relationships = try XCTUnwrap(demoGraph.relationshipsByLanguage.values.first)

        // Make sure that all the overloaded symbols received an overloadOf relation
        let overloadRelations = relationships.filter({ $0.kind == .overloadOf })
        XCTAssertEqual(overloadRelations.count, 4)

        // Pull out the overload group symbols. There should be two of them - one for
        // SomeClass/someMethod(), one for OtherClass/someMethod()
        let overloadGroups = Set(overloadRelations.map(\.target))
        XCTAssertEqual(overloadGroups.count, 2)
        let overloadGroupSymbols = try overloadGroups.map({ try XCTUnwrap(demoGraph.symbols[$0]) })
        XCTAssertEqual(Set(overloadGroupSymbols.map({ $0.pathComponents.first?.value.first })), ["SomeClass", "OtherClass"])
    }

    func testCreateOverloadWithSimplifiedDeclaration() throws {
        // func myFunc(param: Int) -> Int
        // func myFunc(param: String) -> String
        let symbolGraph = makeSymbolGraph(
            symbols: [
                try makeSymbol(fromJson: """
                {
                    "kind": { "identifier": "swift.func", "displayName": "Function" },
                    "identifier": {
                        "precise": "s:9SwiftDemo6myFunc5paramS2S_tF",
                        "interfaceLanguage": "swift"
                    },
                    "pathComponents": [ "myFunc(param:)" ],
                    "names": {
                        "title": "myFunc(param:)",
                        "subHeading": [
                            { "kind": "keyword", "spelling": "func" },
                            { "kind": "text", "spelling": " " },
                            { "kind": "identifier", "spelling": "myFunc" },
                            { "kind": "text", "spelling": "(" },
                            { "kind": "externalParam", "spelling": "param" },
                            { "kind": "text", "spelling": ": " },
                            { "kind": "typeIdentifier", "spelling": "String", "preciseIdentifier": "s:SS" },
                            { "kind": "text", "spelling": ") -> " },
                            { "kind": "typeIdentifier", "spelling": "String", "preciseIdentifier": "s:SS" }
                        ]
                    },
                    "functionSignature": {
                        "parameters": [
                            { "name": "param" }
                        ],
                        "returns": [
                            { "kind": "typeIdentifier", "spelling": "String", "preciseIdentifier": "s:SS" }
                        ]
                    },
                    "declarationFragments": [
                        { "kind": "keyword", "spelling": "func" },
                        { "kind": "text", "spelling": " " },
                        { "kind": "identifier", "spelling": "myFunc" },
                        { "kind": "text", "spelling": "(" },
                        { "kind": "externalParam", "spelling": "param" },
                        { "kind": "text", "spelling": ": " },
                        { "kind": "typeIdentifier", "spelling": "String", "preciseIdentifier": "s:SS" },
                        { "kind": "text", "spelling": ") -> " },
                        { "kind": "typeIdentifier", "spelling": "String", "preciseIdentifier": "s:SS" }
                    ],
                    "accessLevel": "public"
                }
                """),
                try makeSymbol(fromJson: """
                {
                    "kind": { "identifier": "swift.func", "displayName": "Function" },
                    "identifier": {
                        "precise": "s:9SwiftDemo6myFunc5paramS2i_tF",
                        "interfaceLanguage": "swift"
                    },
                    "pathComponents": [ "myFunc(param:)" ],
                    "names": {
                        "title": "myFunc(param:)",
                        "subHeading": [
                            { "kind": "keyword", "spelling": "func" },
                            { "kind": "text", "spelling": " " },
                            { "kind": "identifier", "spelling": "myFunc" },
                            { "kind": "text", "spelling": "(" },
                            { "kind": "externalParam", "spelling": "param" },
                            { "kind": "text", "spelling": ": " },
                            { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                            { "kind": "text", "spelling": ") -> " },
                            { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" }
                        ]
                    },
                    "functionSignature": {
                        "parameters": [
                            { "name": "param" }
                        ],
                        "returns": [
                            { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" }
                        ]
                    },
                    "declarationFragments": [
                        { "kind": "keyword", "spelling": "func" },
                        { "kind": "text", "spelling": " " },
                        { "kind": "identifier", "spelling": "myFunc" },
                        { "kind": "text", "spelling": "(" },
                        { "kind": "externalParam", "spelling": "param" },
                        { "kind": "text", "spelling": ": " },
                        { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                        { "kind": "text", "spelling": ") -> " },
                        { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" }
                    ],
                    "accessLevel": "public"
                }
                """)
            ],
            relations: [])

        let collector = GraphCollector()
        collector.mergeSymbolGraph(symbolGraph, at: .init(fileURLWithPath: "DemoKit.symbols.json"))
        let (unifiedGraphs, _) = collector.finishLoading(createOverloadGroups: true)

        let demoGraph = try XCTUnwrap(unifiedGraphs["DemoKit"])

        let overloadSymbolIdentifier = try XCTUnwrap(demoGraph.symbols.keys.first(where: { $0.hasSuffix("::OverloadGroup") }))
        let overloadSymbol = try XCTUnwrap(demoGraph.symbols[overloadSymbolIdentifier])
        let overloadSelector = try XCTUnwrap(overloadSymbol.mainGraphSelectors.first)
        XCTAssertNotNil(overloadSymbol.names[overloadSelector]?.subHeading)
        XCTAssertNotNil(overloadSymbol.names[overloadSelector]?.navigator)
        XCTAssertEqual(overloadSymbol.names[overloadSelector]?.subHeading, overloadSymbol.names[overloadSelector]?.navigator)

        // func myFunc(param:)
        XCTAssertEqual(overloadSymbol.names[overloadSelector]?.subHeading, [
            .init(kind: .keyword, spelling: "func", preciseIdentifier: nil),
            .init(kind: .text, spelling: " ", preciseIdentifier: nil),
            .init(kind: .identifier, spelling: "myFunc", preciseIdentifier: nil),
            .init(kind: .text, spelling: "(", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "param", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":)", preciseIdentifier: nil),
        ])
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

    let leftSorted = left.sorted(by: compareRelations(_:_:))
    let rightSorted = right.sorted(by: compareRelations(_:_:))

    for (l, r) in zip(leftSorted, rightSorted) {
        XCTAssertEqual(l, r)
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

private func makeSymbol(fromJson json: String) throws -> SymbolGraph.Symbol {
    let decoder = JSONDecoder()
    return try decoder.decode(SymbolGraph.Symbol.self, from: json.data(using: .utf8)!)
}
