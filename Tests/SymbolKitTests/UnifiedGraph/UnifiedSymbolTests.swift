/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
import Foundation
@testable import SymbolKit

class UnifiedSymbolTests: XCTestCase {

    let swiftSelector = UnifiedSymbolGraph.Selector(interfaceLanguage: "swift", platform: nil)
    let objcSelector = UnifiedSymbolGraph.Selector(interfaceLanguage: "objc", platform: nil)

    func testCombineSymbols() throws {
        let demoSwiftSymbol = """
        {
            "kind": {
                "identifier": "swift.class",
                "displayName": "Class"
            },
            "identifier": {
                "precise": "c:objc(cs)PlayingCard",
                "interfaceLanguage": "swift"
            },
            "pathComponents": [
                "PlayingCard"
            ],
            "names": {
                "title": "PlayingCard",
                "navigator": [
                    {
                        "kind": "identifier",
                        "spelling": "PlayingCard"
                    }
                ],
                "subHeading": [
                    {
                        "kind": "keyword",
                        "spelling": "class"
                    },
                    {
                        "kind": "text",
                        "spelling": " "
                    },
                    {
                        "kind": "identifier",
                        "spelling": "PlayingCard"
                    }
                ]
            },
            "declarationFragments": [
                {
                    "kind": "keyword",
                    "spelling": "class"
                },
                {
                    "kind": "text",
                    "spelling": " "
                },
                {
                    "kind": "identifier",
                    "spelling": "PlayingCard"
                }
            ],
            "accessLevel": "open"
        }
        """

        let demoObjcSymbol = """
        {
            "accessLevel": "public",
            "identifier": {
                "interfaceLanguage": "objc",
                "precise": "c:objc(cs)PlayingCard"
            },
            "kind": {
                "displayName": "Class",
                "identifier": "swift.class"
            },
            "location": {
                "position": {
                    "character": 11,
                    "line": 36
                },
                "uri": "PlayingCard.h"
            },
            "names": {
                "title": "PlayingCard"
            },
            "pathComponents": [
                "PlayingCard"
            ]
        }
        """

        let comboSymbol = try mergeTwoSymbols(demoObjcSymbol, demoSwiftSymbol)

        XCTAssertEqual(comboSymbol.uniqueIdentifier, "c:objc(cs)PlayingCard")

        XCTAssertEqual(comboSymbol.kind[swiftSelector]?.identifier, .class)
        XCTAssertEqual(comboSymbol.kind[objcSelector]?.identifier, .class)

        XCTAssertEqual(comboSymbol.pathComponents[swiftSelector], ["PlayingCard"])
        XCTAssertEqual(comboSymbol.pathComponents[objcSelector], ["PlayingCard"])

        XCTAssertNil(comboSymbol.type)

        XCTAssertEqual(comboSymbol.names[swiftSelector],
            SymbolGraph.Symbol.Names(
                title: "PlayingCard",
                navigator: [
                    SymbolGraph.Symbol.DeclarationFragments.Fragment(
                        kind: .identifier,
                        spelling: "PlayingCard",
                        preciseIdentifier: nil)
                ],
                subHeading: [
                    SymbolGraph.Symbol.DeclarationFragments.Fragment(
                        kind: .keyword,
                        spelling: "class",
                        preciseIdentifier: nil),
                    SymbolGraph.Symbol.DeclarationFragments.Fragment(
                        kind: .text,
                        spelling: " ",
                        preciseIdentifier: nil),
                    SymbolGraph.Symbol.DeclarationFragments.Fragment(
                        kind: .identifier,
                        spelling: "PlayingCard",
                        preciseIdentifier: nil)
                ],
                prose: nil))
        XCTAssertEqual(comboSymbol.names[objcSelector],
            SymbolGraph.Symbol.Names(
                title: "PlayingCard",
                navigator: nil,
                subHeading: nil,
                prose: nil))

        XCTAssert(comboSymbol.docComment.isEmpty)

        XCTAssertEqual(comboSymbol.accessLevel[swiftSelector],
                       SymbolGraph.Symbol.AccessControl(rawValue: "open"))
        XCTAssertEqual(comboSymbol.accessLevel[objcSelector],
                       SymbolGraph.Symbol.AccessControl(rawValue: "public"))

        do {
            XCTAssertEqual(comboSymbol.mixins[swiftSelector]?.count, 1)

            let declarationFragments = try XCTUnwrap(comboSymbol.mixins[swiftSelector]?["declarationFragments"] as? SymbolGraph.Symbol.DeclarationFragments)

            XCTAssertEqual(declarationFragments.declarationFragments,
                [
                    SymbolGraph.Symbol.DeclarationFragments.Fragment(
                        kind: .keyword,
                        spelling: "class",
                        preciseIdentifier: nil),
                    SymbolGraph.Symbol.DeclarationFragments.Fragment(
                        kind: .text,
                        spelling: " ",
                        preciseIdentifier: nil),
                    SymbolGraph.Symbol.DeclarationFragments.Fragment(
                        kind: .identifier,
                        spelling: "PlayingCard",
                        preciseIdentifier: nil)
                ]
            )
        }

        do {
            XCTAssertEqual(comboSymbol.mixins[objcSelector]?.count, 1)

            let location = try XCTUnwrap(comboSymbol.mixins[objcSelector]?["location"] as? SymbolGraph.Symbol.Location)

            XCTAssertEqual(location.uri, "PlayingCard.h")
            XCTAssertEqual(location.position,
                SymbolGraph.LineList.SourceRange.Position(
                    line: 36,
                    character: 11))
        }
    }

    func testDocCommentMerging() throws {
        let demoSwiftSymbol = """
        {
            "kind": {
                "identifier": "swift.init",
                "displayName": "Initializer"
            },
            "identifier": {
                "precise": "c:objc(cs)PlayingCard(im)initWithRank:ofSuit:",
                "interfaceLanguage": "swift"
            },
            "pathComponents": [
                "PlayingCard",
                "init(rank:of:)"
            ],
            "names": {
                "title": "init(rank:of:)",
            },
            "accessLevel": "public"
        }
        """

        let demoObjcSymbol = """
        {
            "accessLevel": "public",
            "docComment": {
                "lines": [
                    {
                        "range": {
                            "end": {
                                "character": 51,
                                "line": 41
                            },
                            "start": {
                                "character": 4,
                                "line": 41
                            }
                        },
                        "text": "Initialize a card with the given rank and suit."
                    }
                ]
            },
            "identifier": {
                "interfaceLanguage": "objc",
                "precise": "c:objc(cs)PlayingCard(im)initWithRank:ofSuit:"
            },
            "kind": {
                "displayName": "Instance Method",
                "identifier": "swift.method"
            },
            "location": {
                "position": {
                    "character": 0,
                    "line": 42
                },
                "uri": "PlayingCard.h"
            },
            "names": {
                "title": "initWithRank:ofSuit:"
            },
            "pathComponents": [
                "PlayingCard",
                "initWithRank:ofSuit:"
            ]
        }
        """

        func verifySymbol(comboSymbol: UnifiedSymbolGraph.Symbol) {
            XCTAssertNil(comboSymbol.docComment[swiftSelector])

            guard let docs = comboSymbol.docComment[objcSelector] else {
                XCTFail("Expected single doc comment from test, got something else")
                return
            }

            XCTAssertEqual(docs.lines, [
                SymbolGraph.LineList.Line(
                    text: "Initialize a card with the given rank and suit.",
                    range: SymbolGraph.LineList.SourceRange(
                        start: SymbolGraph.LineList.SourceRange.Position(
                            line: 41,
                            character: 4),
                        end: SymbolGraph.LineList.SourceRange.Position(
                            line: 41,
                            character: 51)))
            ])
        }

        // Test loading the symbols in either order, so that we can load the comment in either case
        let combo1 = try mergeTwoSymbols(demoObjcSymbol, demoSwiftSymbol)
        verifySymbol(comboSymbol: combo1)

        let combo2 = try mergeTwoSymbols(demoSwiftSymbol, demoObjcSymbol)
        verifySymbol(comboSymbol: combo2)
    }

    func testDocCommentMergeIdentical() throws {
        let demoSwiftSymbol = """
        {
            "kind": {
                "identifier": "swift.init",
                "displayName": "Initializer"
            },
            "identifier": {
                "precise": "c:objc(cs)PlayingCard(im)initWithRank:ofSuit:",
                "interfaceLanguage": "swift"
            },
            "pathComponents": [
                "PlayingCard",
                "init(rank:of:)"
            ],
            "docComment": {
                "lines": [
                    {
                        "range": {
                            "end": {
                                "character": 51,
                                "line": 41
                            },
                            "start": {
                                "character": 4,
                                "line": 41
                            }
                        },
                        "text": "Initialize a card with the given rank and suit."
                    }
                ]
            },
            "names": {
                "title": "init(rank:of:)",
            },
            "accessLevel": "public"
        }
        """

        let demoObjcSymbol = """
        {
            "accessLevel": "public",
            "docComment": {
                "lines": [
                    {
                        "range": {
                            "end": {
                                "character": 51,
                                "line": 41
                            },
                            "start": {
                                "character": 4,
                                "line": 41
                            }
                        },
                        "text": "Initialize a card with the given rank and suit."
                    }
                ]
            },
            "identifier": {
                "interfaceLanguage": "objc",
                "precise": "c:objc(cs)PlayingCard(im)initWithRank:ofSuit:"
            },
            "kind": {
                "displayName": "Instance Method",
                "identifier": "swift.method"
            },
            "location": {
                "position": {
                    "character": 0,
                    "line": 42
                },
                "uri": "PlayingCard.h"
            },
            "names": {
                "title": "initWithRank:ofSuit:"
            },
            "pathComponents": [
                "PlayingCard",
                "initWithRank:ofSuit:"
            ]
        }
        """

        func verifySymbol(comboSymbol: UnifiedSymbolGraph.Symbol) {
            XCTAssertEqual(comboSymbol.docComment.count, 2)

            for docs in comboSymbol.docComment.values {
                XCTAssertEqual(docs.lines, [
                    SymbolGraph.LineList.Line(
                        text: "Initialize a card with the given rank and suit.",
                        range: SymbolGraph.LineList.SourceRange(
                            start: SymbolGraph.LineList.SourceRange.Position(
                                line: 41,
                                character: 4),
                            end: SymbolGraph.LineList.SourceRange.Position(
                                line: 41,
                                character: 51)))
                ])
            }
        }

        // Test loading the symbols in either order, so that we can load the comment in either case
        let combo1 = try mergeTwoSymbols(demoObjcSymbol, demoSwiftSymbol)
        verifySymbol(comboSymbol: combo1)

        let combo2 = try mergeTwoSymbols(demoSwiftSymbol, demoObjcSymbol)
        verifySymbol(comboSymbol: combo2)
    }

    func testDocCommentMergeDifferent() throws {
        let demoSwiftSymbol = """
        {
            "kind": {
                "identifier": "swift.init",
                "displayName": "Initializer"
            },
            "identifier": {
                "precise": "c:objc(cs)PlayingCard(im)initWithRank:ofSuit:",
                "interfaceLanguage": "swift"
            },
            "pathComponents": [
                "PlayingCard",
                "init(rank:of:)"
            ],
            "docComment": {
                "lines": [
                    {
                        "range": {
                            "end": {
                                "character": 51,
                                "line": 41
                            },
                            "start": {
                                "character": 4,
                                "line": 41
                            }
                        },
                        "text": "Create a new card with the given rank and suit."
                    }
                ]
            },
            "names": {
                "title": "init(rank:of:)",
            },
            "accessLevel": "public"
        }
        """

        let demoObjcSymbol = """
        {
            "accessLevel": "public",
            "docComment": {
                "lines": [
                    {
                        "range": {
                            "end": {
                                "character": 51,
                                "line": 41
                            },
                            "start": {
                                "character": 4,
                                "line": 41
                            }
                        },
                        "text": "Initialize a card with the given rank and suit."
                    }
                ]
            },
            "identifier": {
                "interfaceLanguage": "objc",
                "precise": "c:objc(cs)PlayingCard(im)initWithRank:ofSuit:"
            },
            "kind": {
                "displayName": "Instance Method",
                "identifier": "swift.method"
            },
            "location": {
                "position": {
                    "character": 0,
                    "line": 42
                },
                "uri": "PlayingCard.h"
            },
            "names": {
                "title": "initWithRank:ofSuit:"
            },
            "pathComponents": [
                "PlayingCard",
                "initWithRank:ofSuit:"
            ]
        }
        """

        func verifySymbol(comboSymbol: UnifiedSymbolGraph.Symbol) {
            XCTAssertEqual(comboSymbol.docComment.count, 2)

            XCTAssertEqual(comboSymbol.docComment[objcSelector]?.lines, [
                SymbolGraph.LineList.Line(
                    text: "Initialize a card with the given rank and suit.",
                    range: SymbolGraph.LineList.SourceRange(
                        start: SymbolGraph.LineList.SourceRange.Position(
                            line: 41,
                            character: 4),
                        end: SymbolGraph.LineList.SourceRange.Position(
                            line: 41,
                            character: 51)))
            ])

            XCTAssertEqual(comboSymbol.docComment[swiftSelector]?.lines, [
                SymbolGraph.LineList.Line(
                    text: "Create a new card with the given rank and suit.",
                    range: SymbolGraph.LineList.SourceRange(
                        start: SymbolGraph.LineList.SourceRange.Position(
                            line: 41,
                            character: 4),
                        end: SymbolGraph.LineList.SourceRange.Position(
                            line: 41,
                            character: 51)))
            ])
        }

        // Test loading the symbols in either order, so that we can load the comment in either case
        let combo1 = try mergeTwoSymbols(demoObjcSymbol, demoSwiftSymbol)
        verifySymbol(comboSymbol: combo1)

        let combo2 = try mergeTwoSymbols(demoSwiftSymbol, demoObjcSymbol)
        verifySymbol(comboSymbol: combo2)
    }

    func mergeTwoSymbols(_ sym1: String, _ sym2: String) throws -> UnifiedSymbolGraph.Symbol {
        let decoder = JSONDecoder()

        let data1 = sym1.data(using: .utf8)!
        let decoded1 = try decoder.decode(SymbolGraph.Symbol.self, from: data1)

        let data2 = sym2.data(using: .utf8)!
        let decoded2 = try decoder.decode(SymbolGraph.Symbol.self, from: data2)

        let module = SymbolGraph.Module(name: "TestModule", platform: SymbolGraph.Platform(architecture: nil, vendor: nil, operatingSystem: nil, environment: nil), version: nil, bystanders: nil)

        let comboSymbol = UnifiedSymbolGraph.Symbol(fromSingleSymbol: decoded1, module: module, isMainGraph: true)
        comboSymbol.mergeSymbol(symbol: decoded2, module: module, isMainGraph: false)

        return comboSymbol
    }

}
