/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2024 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
@testable import SymbolKit

class SymbolGraphOverloadsTests: XCTestCase {
    func testCreateOverloadGroupSymbols() throws {
        // - SomeClass
        //   - someMethod() [x2]
        let demoGraph = makeSymbolGraph(
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

        let overloadSymbols = [
            "s:SomeClass:someMethod-1",
            "s:SomeClass:someMethod-2",
        ]
        let expectedOverloadGroupIdentifier = "s:SomeClass:someMethod-1::OverloadGroup"

        // Make sure that overloadOf relationships were added
        let overloadRelations = demoGraph.relationships.filter({ $0.kind == .overloadOf })
        XCTAssertEqual(overloadRelations.count, 2)
        XCTAssertEqual(Set(overloadRelations.map(\.target)).count, 1)
        XCTAssertEqual(Set(overloadRelations.map(\.source)), Set(overloadSymbols))

        // Pull out the overload group's identifier and make sure that it exists
        let overloadGroupIdentifier = try XCTUnwrap(overloadRelations.first?.target)
        XCTAssertEqual(overloadGroupIdentifier, expectedOverloadGroupIdentifier)
        XCTAssert(demoGraph.symbols.keys.contains(overloadGroupIdentifier))

        // Make sure that the existing memberOf relationship was cloned onto the overload group
        let overloadGroupRelations = demoGraph.relationships.filter({ $0.source == overloadGroupIdentifier })
        XCTAssertEqual(overloadGroupRelations.count, 1)
        XCTAssertEqual(overloadGroupRelations.first?.kind, .memberOf)
        XCTAssertEqual(overloadGroupRelations.first?.target, "s:SomeClass")

        // Make sure that the individual overloads reference the overload group and their index properly
        for overloadIndex in overloadSymbols.indices {
            let overloadIdentifier = overloadSymbols[overloadIndex]
            let overloadSymbol = try XCTUnwrap(demoGraph.symbols[overloadIdentifier])
            let overloadData = try XCTUnwrap(overloadSymbol.overloadData)
            XCTAssertEqual(overloadData.overloadGroupIdentifier, expectedOverloadGroupIdentifier)
            XCTAssertEqual(overloadData.overloadGroupIndex, overloadIndex)
        }
    }

    func testCreateDifferentOverloadGroupSymbolsPerKind() throws {
        // - SomeClass
        //   - someMethod() [instance method, x2]
        //   - someMethod() [class method, x2]
        let demoGraph = makeSymbolGraph(
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

        // Make sure that the overloaded symbols all received an overloadOf relation
        let overloadRelations = demoGraph.relationships.filter({ $0.kind == .overloadOf })
        XCTAssertEqual(overloadRelations.count, 4)

        // Pull out the overload group symbols. There should be two of them - one for the instance
        // method, one for the class method
        let overloadGroups = Set(overloadRelations.map(\.target))
        XCTAssertEqual(overloadGroups.count, 2)
        let overloadGroupSymbols = try overloadGroups.map({ try XCTUnwrap(demoGraph.symbols[$0]) })
        XCTAssertEqual(Set(overloadGroupSymbols.map(\.kind.identifier)), [.method, .typeMethod])
    }

    func testCreateDifferentOverloadGroupsPerPath() throws {
        // - SomeClass
        //   - someMethod() [x2]
        // - OtherClass
        //   - someMethod() [x2]
        let demoGraph = makeSymbolGraph(
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

        // Make sure that all the overloaded symbols received an overloadOf relation
        let overloadRelations = demoGraph.relationships.filter({ $0.kind == .overloadOf })
        XCTAssertEqual(overloadRelations.count, 4)

        // Pull out the overload group symbols. There should be two of them - one for
        // SomeClass/someMethod(), one for OtherClass/someMethod()
        let overloadGroups = Set(overloadRelations.map(\.target))
        XCTAssertEqual(overloadGroups.count, 2)
        let overloadGroupSymbols = try overloadGroups.map({ try XCTUnwrap(demoGraph.symbols[$0]) })
        XCTAssertEqual(Set(overloadGroupSymbols.map({ $0.pathComponents.first })), ["SomeClass", "OtherClass"])
    }

    func testCreateOverloadWithSimplifiedDeclaration() throws {
        // func myFunc(param: Int) -> Int
        // func myFunc(param: String) -> String
        let demoGraph = makeSymbolGraph(
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

        // Int should sort before String, even though lowercase letters sort after uppercase ones in
        // a case-sensitive sort
        let overloadSymbols = [
            "s:9SwiftDemo6myFunc5paramS2i_tF",
            "s:9SwiftDemo6myFunc5paramS2S_tF",
        ]
        let expectedOverloadGroup = "s:9SwiftDemo6myFunc5paramS2i_tF::OverloadGroup"

        XCTAssert(demoGraph.symbols.keys.contains(expectedOverloadGroup))
        let overloadGroupSymbol = try XCTUnwrap(demoGraph.symbols[expectedOverloadGroup])
        XCTAssertNotNil(overloadGroupSymbol.names.subHeading)
        XCTAssertNotNil(overloadGroupSymbol.names.navigator)
        XCTAssertEqual(overloadGroupSymbol.names.subHeading, overloadGroupSymbol.names.navigator)

        // func myFunc(param:)
        XCTAssertEqual(overloadGroupSymbol.names.subHeading, [
            .init(kind: .keyword, spelling: "func", preciseIdentifier: nil),
            .init(kind: .text, spelling: " ", preciseIdentifier: nil),
            .init(kind: .identifier, spelling: "myFunc", preciseIdentifier: nil),
            .init(kind: .text, spelling: "(", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "param", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":)", preciseIdentifier: nil),
        ])

        // Since these symbols had declaration fragments, ensure that their overload data reflects
        // the appropriate sorting
        for overloadIndex in overloadSymbols.indices {
            let overloadIdentifier = overloadSymbols[overloadIndex]
            let overloadSymbol = try XCTUnwrap(demoGraph.symbols[overloadIdentifier])
            let overloadData = try XCTUnwrap(overloadSymbol.overloadData)
            XCTAssertEqual(overloadData.overloadGroupIdentifier, expectedOverloadGroup)
            XCTAssertEqual(overloadData.overloadGroupIndex, overloadIndex)
        }
    }

    /// Ensure that default implementation symbols are not collected into an overload group.
    func testDefaultImplementationDoesNotCreateAnOverloadGroup() throws {
        // protocol MyProtocol
        // - requirement someFunc()
        // - default implementation someFunc()
        let demoGraph = makeSymbolGraph(
            symbols: [
                .init(
                    identifier: .init(precise: "s:MyProtocol", interfaceLanguage: "swift"),
                    names: .init(title: "MyProtocol", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["MyProtocol"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .protocol, displayName: "Protocol"),
                    mixins: [:]),
                .init(
                    identifier: .init(precise: "s:MyProtocol:someFunc-1", interfaceLanguage: "swift"),
                    names: .init(title: "someFunc()", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["MyProtocol", "someFunc()"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .method, displayName: "Instance Method"),
                    mixins: [:]),
                .init(
                    identifier: .init(precise: "s:MyProtocol:someFunc-2", interfaceLanguage: "swift"),
                    names: .init(title: "someFunc()", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["MyProtocol", "someFunc()"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .method, displayName: "Instance Method"),
                    mixins: [:]),
            ],
            relations: [
                .init(
                    source: "s:MyProtocol:someFunc-1",
                    target: "s:MyProtocol",
                    kind: .requirementOf,
                    targetFallback: nil),
                .init(
                    source: "s:MyProtocol:someFunc-2",
                    target: "s:MyProtocol:someFunc-1",
                    kind: .defaultImplementationOf,
                    targetFallback: nil),
            ]
        )

        // Even though the two someFunc symbols collide on kind and path, one is a default
        // implementation of the other, so they should not be combined together
        XCTAssertFalse(demoGraph.relationships.contains(where: { $0.kind == .overloadOf }))
    }

    func testOverloadsWithSameDeclarationAreSortedCorrectly() throws {
        // func myFunc()
        // func myFunc()
        // (In a real-world scenario, these might differ by the swiftGenerics mixin, but here we can
        // write a contrived situation like this)
        let demoGraph = makeSymbolGraph(
            symbols: [
                .init(
                    identifier: .init(precise: "s:myFunc-2", interfaceLanguage: "swift"),
                    names: .init(title: "myFunc()", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["myFunc()"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .func, displayName: "Function"),
                    mixins: [
                        SymbolGraph.Symbol.DeclarationFragments.mixinKey:
                            SymbolGraph.Symbol.DeclarationFragments(declarationFragments: [
                                .init(kind: .text, spelling: "myFunc()", preciseIdentifier: nil)
                            ])
                    ]),
                .init(
                    identifier: .init(precise: "s:myFunc-1", interfaceLanguage: "swift"),
                    names: .init(title: "myFunc()", navigator: nil, subHeading: nil, prose: nil),
                    pathComponents: ["myFunc()"],
                    docComment: nil,
                    accessLevel: .init(rawValue: "public"),
                    kind: .init(parsedIdentifier: .func, displayName: "Function"),
                    mixins: [
                        SymbolGraph.Symbol.DeclarationFragments.mixinKey:
                            SymbolGraph.Symbol.DeclarationFragments(declarationFragments: [
                                .init(kind: .text, spelling: "myFunc()", preciseIdentifier: nil)
                            ])
                    ]),
            ],
            relations: []
        )

        let overloadSymbols = [
            "s:myFunc-1",
            "s:myFunc-2",
        ]
        let expectedOverloadGroupIdentifier = "s:myFunc-1::OverloadGroup"

        // Make sure that overloadOf relationships were added
        let overloadRelations = demoGraph.relationships.filter({ $0.kind == .overloadOf })
        XCTAssertEqual(overloadRelations.count, 2)
        XCTAssertEqual(Set(overloadRelations.map(\.target)).count, 1)
        XCTAssertEqual(Set(overloadRelations.map(\.source)), Set(overloadSymbols))

        // Pull out the overload group's identifier and make sure that it exists
        let overloadGroupIdentifier = try XCTUnwrap(overloadRelations.first?.target)
        XCTAssertEqual(overloadGroupIdentifier, expectedOverloadGroupIdentifier)
        XCTAssert(demoGraph.symbols.keys.contains(overloadGroupIdentifier))

        // Make sure that the individual overloads reference the overload group and their index properly
        for overloadIndex in overloadSymbols.indices {
            let overloadIdentifier = overloadSymbols[overloadIndex]
            let overloadSymbol = try XCTUnwrap(demoGraph.symbols[overloadIdentifier])
            let overloadData = try XCTUnwrap(overloadSymbol.overloadData)
            XCTAssertEqual(overloadData.overloadGroupIdentifier, expectedOverloadGroupIdentifier)
            XCTAssertEqual(overloadData.overloadGroupIndex, overloadIndex)
        }
    }
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
    var graph = SymbolGraph(
        metadata: metadata,
        module: module,
        symbols: symbols,
        relationships: relations
    )
    graph.createOverloadGroupSymbols()
    return graph
}

private func makeSymbol(fromJson json: String) throws -> SymbolGraph.Symbol {
    let decoder = JSONDecoder()
    return try decoder.decode(SymbolGraph.Symbol.self, from: json.data(using: .utf8)!)
}
