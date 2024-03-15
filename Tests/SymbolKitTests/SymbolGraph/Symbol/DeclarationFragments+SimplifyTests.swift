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

class DeclarationFragmentsSimplifyTests: XCTestCase {
    /// Ensure that the overload declaration can simplify a basic Swift function with two parameters.
    func testSimplifyDeclaration() throws {
        // func myFunc(paramOne one: Int, paramTwo two: Int) -> Int
        let inputJson = """
        {
            "kind": { "identifier": "swift.func", "displayName": "Function" },
            "identifier": {
                "precise": "s:9SwiftDemo6myFunc8paramOne0E3TwoS2i_SitF",
                "interfaceLanguage": "swift"
            },
            "pathComponents": [ "myFunc(paramOne:paramTwo:)" ],
            "names": {
                "title": "myFunc(paramOne:paramTwo:)",
                "subHeading": [
                    { "kind": "keyword", "spelling": "func" },
                    { "kind": "text", "spelling": " " },
                    { "kind": "identifier", "spelling": "myFunc" },
                    { "kind": "text", "spelling": "(" },
                    { "kind": "externalParam", "spelling": "paramOne" },
                    { "kind": "text", "spelling": ": " },
                    { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                    { "kind": "text", "spelling": ", " },
                    { "kind": "externalParam", "spelling": "paramTwo" },
                    { "kind": "text", "spelling": ": " },
                    { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                    { "kind": "text", "spelling": ") -> " },
                    { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" }
                ]
            },
            "functionSignature": {
                "parameters": [
                    { "name": "paramOne", "internalName": "one" },
                    { "name": "paramTwo", "internalName": "two" }
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
                { "kind": "externalParam", "spelling": "paramOne" },
                { "kind": "text", "spelling": " " },
                { "kind": "internalParam", "spelling": "one" },
                { "kind": "text", "spelling": ": " },
                { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                { "kind": "text", "spelling": ", " },
                { "kind": "externalParam", "spelling": "paramTwo" },
                { "kind": "text", "spelling": " " },
                { "kind": "internalParam", "spelling": "two" },
                { "kind": "text", "spelling": ": " },
                { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                { "kind": "text", "spelling": ") -> " },
                { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" }
            ],
            "accessLevel": "public"
        }
        """

        let symbol = try makeSymbol(fromJson: inputJson)

        let overloadDeclaration = symbol.overloadSubheadingFragments()
        // func myFunc(paramOne:paramTwo:)
        XCTAssertEqual(overloadDeclaration, [
            .init(kind: .keyword, spelling: "func", preciseIdentifier: nil),
            .init(kind: .text, spelling: " ", preciseIdentifier: nil),
            .init(kind: .identifier, spelling: "myFunc", preciseIdentifier: nil),
            .init(kind: .text, spelling: "(", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "paramOne", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "paramTwo", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":)", preciseIdentifier: nil),
        ])
    }

    /// Ensure that the overload declaration can simplify a Swift function taking a closure parameter.
    func testSimplifyClosureParameter() throws {
        // func asdf(param: (_ one: Int, _ two: Int) -> Int, paramTwo: String)
        let inputJson = """
        {
            "kind": { "identifier": "swift.func", "displayName": "Function" },
            "identifier": {
                "precise": "s:9SwiftDemo4asdf5param0D3TwoyS2i_SitXE_SStF",
                "interfaceLanguage": "swift"
            },
            "pathComponents": [ "asdf(param:paramTwo:)" ],
            "names": {
                "title": "asdf(param:paramTwo:)",
                "subHeading": [
                    { "kind": "keyword", "spelling": "func" },
                    { "kind": "text", "spelling": " " },
                    { "kind": "identifier", "spelling": "asdf" },
                    { "kind": "text", "spelling": "(" },
                    { "kind": "externalParam", "spelling": "param" },
                    { "kind": "text", "spelling": ": (" },
                    { "kind": "externalParam", "spelling": "_" },
                    { "kind": "text", "spelling": " " },
                    { "kind": "internalParam", "spelling": "one" },
                    { "kind": "text", "spelling": ": " },
                    { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                    { "kind": "text", "spelling": ", " },
                    { "kind": "externalParam", "spelling": "_" },
                    { "kind": "text", "spelling": " " },
                    { "kind": "internalParam", "spelling": "two" },
                    { "kind": "text", "spelling": ": " },
                    { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                    { "kind": "text", "spelling": ") -> " },
                    { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                    { "kind": "text", "spelling": ", " },
                    { "kind": "externalParam", "spelling": "paramTwo" },
                    { "kind": "text", "spelling": ": " },
                    { "kind": "typeIdentifier", "spelling": "String", "preciseIdentifier": "s:SS" },
                    { "kind": "text", "spelling": ")" }
                ]
            },
            "functionSignature": {
                "parameters": [
                    { "name": "param" },
                    { "name": "paramTwo" }
                ],
                "returns": [
                    { "kind": "text", "spelling": "()" }
                ]
            },
            "declarationFragments": [
                { "kind": "keyword", "spelling": "func" },
                { "kind": "text", "spelling": " " },
                { "kind": "identifier", "spelling": "asdf" },
                { "kind": "text", "spelling": "(" },
                { "kind": "externalParam", "spelling": "param" },
                { "kind": "text", "spelling": ": (" },
                { "kind": "externalParam", "spelling": "_" },
                { "kind": "text", "spelling": " " },
                { "kind": "internalParam", "spelling": "one" },
                { "kind": "text", "spelling": ": " },
                { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                { "kind": "text", "spelling": ", " },
                { "kind": "externalParam", "spelling": "_" },
                { "kind": "text", "spelling": " " },
                { "kind": "internalParam", "spelling": "two" },
                { "kind": "text", "spelling": ": " },
                { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                { "kind": "text", "spelling": ") -> " },
                { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                { "kind": "text", "spelling": ", " },
                { "kind": "externalParam", "spelling": "paramTwo" },
                { "kind": "text", "spelling": ": " },
                { "kind": "typeIdentifier", "spelling": "String", "preciseIdentifier": "s:SS" },
                { "kind": "text", "spelling": ")" }
            ],
            "accessLevel": "public"
        }
        """
        let symbol = try makeSymbol(fromJson: inputJson)

        let overloadDeclaration = symbol.overloadSubheadingFragments()
        // func asdf(param:paramTwo:)
        XCTAssertEqual(overloadDeclaration, [
            .init(kind: .keyword, spelling: "func", preciseIdentifier: nil),
            .init(kind: .text, spelling: " ", preciseIdentifier: nil),
            .init(kind: .identifier, spelling: "asdf", preciseIdentifier: nil),
            .init(kind: .text, spelling: "(", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "param", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "paramTwo", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":)", preciseIdentifier: nil),
        ])
    }

    /// Ensure that the overload declaration can simplify a Swift function with both a named and unnamed parameter.
    func testSimplifyMixedParameterNames() throws {
        // func myFunc(param: Int, _ otherParam: Int)
        let inputJson = """
        {
            "kind": { "identifier": "swift.func", "displayName": "Function" },
            "identifier": {
                "precise": "s:9SwiftDemo6myFunc5param_ySi_SitF",
                "interfaceLanguage": "swift"
            },
            "pathComponents": [ "myFunc(param:_:)" ],
            "names": {
                "title": "myFunc(param:_:)",
                "subHeading": [
                    { "kind": "keyword", "spelling": "func" },
                    { "kind": "text", "spelling": " " },
                    { "kind": "identifier", "spelling": "myFunc" },
                    { "kind": "text", "spelling": "(" },
                    { "kind": "externalParam", "spelling": "param" },
                    { "kind": "text", "spelling": ": " },
                    { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                    { "kind": "text", "spelling": ", " },
                    { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                    { "kind": "text", "spelling": ")" }
                ]
            },
            "functionSignature": {
                "parameters": [
                    {
                        "name": "param"
                    },
                    {
                        "name": "otherParam"
                    }
                ],
                "returns": [
                    { "kind": "text", "spelling": "()" }
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
                { "kind": "text", "spelling": ", " },
                { "kind": "externalParam", "spelling": "_" },
                { "kind": "text", "spelling": " " },
                { "kind": "internalParam", "spelling": "otherParam" },
                { "kind": "text", "spelling": ": " },
                { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                { "kind": "text", "spelling": ")" }
            ],
            "accessLevel": "public"
        }
        """
        let symbol = try makeSymbol(fromJson: inputJson)

        let overloadDeclaration = symbol.overloadSubheadingFragments()
        // func myFunc(param:_:)
        XCTAssertEqual(overloadDeclaration, [
            .init(kind: .keyword, spelling: "func", preciseIdentifier: nil),
            .init(kind: .text, spelling: " ", preciseIdentifier: nil),
            .init(kind: .identifier, spelling: "myFunc", preciseIdentifier: nil),
            .init(kind: .text, spelling: "(", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "param", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "_", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":)", preciseIdentifier: nil),
        ])
    }

    /// Ensure that the overload declaration can simplify a Swift subscript with both a named and an unnamed parameter.
    func testSimplifySubscriptParameters() throws {
        // subscript(param: Int, other paramTwo: Int) -> Int
        let inputJson = """
        {
            "kind": { "identifier": "swift.subscript", "displayName": "Instance Subscript" },
            "identifier": {
                "precise": "s:9SwiftDemo7MyClassC_5otherS2i_Sitcip",
                "interfaceLanguage": "swift"
            },
            "pathComponents": [ "MyClass", "subscript(_:other:)" ],
            "names": {
                "title": "subscript(_:other:)",
                "subHeading": [
                    { "kind": "keyword", "spelling": "subscript" },
                    { "kind": "text", "spelling": "(" },
                    { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                    { "kind": "text", "spelling": ", " },
                    { "kind": "externalParam", "spelling": "other" },
                    { "kind": "text", "spelling": " _: " },
                    { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                    { "kind": "text", "spelling": ") -> " },
                    { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" }
                ]
            },
            "declarationFragments": [
                { "kind": "keyword", "spelling": "subscript" },
                { "kind": "text", "spelling": "(" },
                { "kind": "internalParam", "spelling": "param" },
                { "kind": "text", "spelling": ": " },
                { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                { "kind": "text", "spelling": ", " },
                { "kind": "externalParam", "spelling": "other" },
                { "kind": "text", "spelling": " " },
                { "kind": "internalParam", "spelling": "paramTwo" },
                { "kind": "text", "spelling": ": " },
                { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                { "kind": "text", "spelling": ") -> " },
                { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                { "kind": "text", "spelling": " { " },
                { "kind": "keyword", "spelling": "get" },
                { "kind": "text", "spelling": " }" }
            ],
            "accessLevel": "public"
        }
        """
        let symbol = try makeSymbol(fromJson: inputJson)

        let overloadDeclaration = symbol.overloadSubheadingFragments()
        // subscript(_:other:)
        XCTAssertEqual(overloadDeclaration, [
            .init(kind: .keyword, spelling: "subscript", preciseIdentifier: nil),
            .init(kind: .text, spelling: "(", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "_", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "other", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":)", preciseIdentifier: nil),
        ])
    }

    func testSimplifyComplexParameters() throws {
        // func someFunction<Result: Equatable>(
        //     first: borrowing [Int?],
        //     second: inout Int,
        //     third: (Int, Int),
        //     fourth: @autoclosure () throws -> Void,
        //     fifth: Int...,
        //     sixth: some Sequence<Int>,
        //     seventh: any Hashable
        // ) -> Result?
        let inputJson = """
        {
            "kind": { "identifier": "swift.func", "displayName": "Function" },
            "identifier": {
                "precise": "s:9SwiftDemo12someFunction5first6second5third6fourth5fifth5sixth7seventhxSgSaySiSgG_SizSi_SityyKXKSidq_SH_ptSQRzSTR_Si7ElementRt_r0_lF",
                "interfaceLanguage": "swift"
            },
            "pathComponents": [ "someFunction(first:second:third:fourth:fifth:sixth:seventh:)" ],
            "names": {
                "title": "someFunction(first:second:third:fourth:fifth:sixth:seventh:)",
                "subHeading": [
                    { "kind": "keyword", "spelling": "func" },
                    { "kind": "text", "spelling": " " },
                    { "kind": "identifier", "spelling": "someFunction" },
                    { "kind": "text", "spelling": "<" },
                    { "kind": "genericParameter", "spelling": "Result" },
                    { "kind": "text", "spelling": ">(" },
                    { "kind": "externalParam", "spelling": "first" },
                    { "kind": "text", "spelling": ": " },
                    { "kind": "keyword", "spelling": "borrowing" },
                    { "kind": "text", "spelling": " [" },
                    { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                    { "kind": "text", "spelling": "?], " },
                    { "kind": "externalParam", "spelling": "second" },
                    { "kind": "text", "spelling": ": " },
                    { "kind": "keyword", "spelling": "inout" },
                    { "kind": "text", "spelling": " " },
                    { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                    { "kind": "text", "spelling": ", " },
                    { "kind": "externalParam", "spelling": "third" },
                    { "kind": "text", "spelling": ": (" },
                    { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                    { "kind": "text", "spelling": ", " },
                    { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                    { "kind": "text", "spelling": "), " },
                    { "kind": "externalParam", "spelling": "fourth" },
                    { "kind": "text", "spelling": ": () " },
                    { "kind": "keyword", "spelling": "throws" },
                    { "kind": "text", "spelling": " -> " },
                    { "kind": "typeIdentifier", "spelling": "Void", "preciseIdentifier": "s:s4Voida" },
                    { "kind": "text", "spelling": ", " },
                    { "kind": "externalParam", "spelling": "fifth" },
                    { "kind": "text", "spelling": ": " },
                    { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                    { "kind": "text", "spelling": "..., " },
                    { "kind": "externalParam", "spelling": "sixth" },
                    { "kind": "text", "spelling": ": " },
                    { "kind": "keyword", "spelling": "some" },
                    { "kind": "text", "spelling": " " },
                    { "kind": "typeIdentifier", "spelling": "Sequence", "preciseIdentifier": "s:ST" },
                    { "kind": "text", "spelling": "<" },
                    { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                    { "kind": "text", "spelling": ">, " },
                    { "kind": "externalParam", "spelling": "seventh" },
                    { "kind": "text", "spelling": ": " },
                    { "kind": "keyword", "spelling": "any" },
                    { "kind": "text", "spelling": " " },
                    { "kind": "typeIdentifier", "spelling": "Hashable", "preciseIdentifier": "s:SH" },
                    { "kind": "text", "spelling": ") -> " },
                    {
                        "kind": "typeIdentifier",
                        "spelling": "Result",
                        "preciseIdentifier": "s:9SwiftDemo12someFunction5first6second5third6fourth5fifth5sixth7seventhxSgSaySiSgG_SizSi_SityyKXKSidq_SH_ptSQRzSTR_Si7ElementRt_r0_lF6ResultL_xmfp"
                    },
                    { "kind": "text", "spelling": "?" }
                ]
            },
            "functionSignature": {
                "parameters": [
                    { "name": "first" },
                    { "name": "second" },
                    { "name": "third" },
                    { "name": "fourth" },
                    { "name": "fifth" },
                    { "name": "sixth" },
                    { "name": "seventh" }
                ],
                "returns": [
                    { "kind": "typeIdentifier", "spelling": "Result" },
                    { "kind": "text", "spelling": "?" }
                ]
            },
            "declarationFragments": [
                { "kind": "keyword", "spelling": "func" },
                { "kind": "text", "spelling": " " },
                { "kind": "identifier", "spelling": "someFunction" },
                { "kind": "text", "spelling": "<" },
                { "kind": "genericParameter", "spelling": "Result" },
                { "kind": "text", "spelling": ">(" },
                { "kind": "externalParam", "spelling": "first" },
                { "kind": "text", "spelling": ": " },
                { "kind": "keyword", "spelling": "borrowing" },
                { "kind": "text", "spelling": " [" },
                { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                { "kind": "text", "spelling": "?], " },
                { "kind": "externalParam", "spelling": "second" },
                { "kind": "text", "spelling": ": " },
                { "kind": "keyword", "spelling": "inout" },
                { "kind": "text", "spelling": " " },
                { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                { "kind": "text", "spelling": ", " },
                { "kind": "externalParam", "spelling": "third" },
                { "kind": "text", "spelling": ": (" },
                { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                { "kind": "text", "spelling": ", " },
                { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                { "kind": "text", "spelling": "), " },
                { "kind": "externalParam", "spelling": "fourth" },
                { "kind": "text", "spelling": ": " },
                { "kind": "attribute", "spelling": "@autoclosure" },
                { "kind": "text", "spelling": " () " },
                { "kind": "keyword", "spelling": "throws" },
                { "kind": "text", "spelling": " -> " },
                { "kind": "typeIdentifier", "spelling": "Void", "preciseIdentifier": "s:s4Voida" },
                { "kind": "text", "spelling": ", " },
                { "kind": "externalParam", "spelling": "fifth" },
                { "kind": "text", "spelling": ": " },
                { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                { "kind": "text", "spelling": "..., " },
                { "kind": "externalParam", "spelling": "sixth" },
                { "kind": "text", "spelling": ": " },
                { "kind": "keyword", "spelling": "some" },
                { "kind": "text", "spelling": " " },
                { "kind": "typeIdentifier", "spelling": "Sequence", "preciseIdentifier": "s:ST" },
                { "kind": "text", "spelling": "<" },
                { "kind": "typeIdentifier", "spelling": "Int", "preciseIdentifier": "s:Si" },
                { "kind": "text", "spelling": ">, " },
                { "kind": "externalParam", "spelling": "seventh" },
                { "kind": "text", "spelling": ": " },
                { "kind": "keyword", "spelling": "any" },
                { "kind": "text", "spelling": " " },
                { "kind": "typeIdentifier", "spelling": "Hashable", "preciseIdentifier": "s:SH" },
                { "kind": "text", "spelling": ") -> " },
                {
                    "kind": "typeIdentifier",
                    "spelling": "Result",
                    "preciseIdentifier": "s:9SwiftDemo12someFunction5first6second5third6fourth5fifth5sixth7seventhxSgSaySiSgG_SizSi_SityyKXKSidq_SH_ptSQRzSTR_Si7ElementRt_r0_lF6ResultL_xmfp"
                },
                { "kind": "text", "spelling": "? " },
                { "kind": "keyword", "spelling": "where" },
                { "kind": "text", "spelling": " " },
                { "kind": "typeIdentifier", "spelling": "Result" },
                { "kind": "text", "spelling": " : " },
                { "kind": "typeIdentifier", "spelling": "Equatable", "preciseIdentifier": "s:SQ" }
            ],
            "accessLevel": "public"
        }
        """
        let symbol = try makeSymbol(fromJson: inputJson)

        let overloadDeclaration = symbol.overloadSubheadingFragments()
        // func someFunction(first:second:third:fourth:fifth:sixth:seventh:)
        XCTAssertEqual(overloadDeclaration, [
            .init(kind: .keyword, spelling: "func", preciseIdentifier: nil),
            .init(kind: .text, spelling: " ", preciseIdentifier: nil),
            .init(kind: .identifier, spelling: "someFunction", preciseIdentifier: nil),
            .init(kind: .text, spelling: "(", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "first", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "second", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "third", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "fourth", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "fifth", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "sixth", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "seventh", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":)", preciseIdentifier: nil),
        ])
    }

    func testAttribute() throws {
        // @MainActor public func something() {}
        let inputJSON = """
        {
          "kind": {
            "identifier": "swift.method",
            "displayName": "Instance Method"
          },
          "identifier": {
            "precise": "s:10ModuleName9SomethingV9somethingyyF",
            "interfaceLanguage": "swift"
          },
          "pathComponents": [
            "Something",
            "something()"
          ],
          "names": {
            "title": "something()",
            "subHeading": [
              {
                "kind": "keyword",
                "spelling": "func"
              },
              {
                "kind": "text",
                "spelling": " "
              },
              {
                "kind": "identifier",
                "spelling": "something"
              },
              {
                "kind": "text",
                "spelling": "()"
              }
            ]
          },
          "functionSignature": {
            "returns": [
              {
                "kind": "text",
                "spelling": "()"
              }
            ]
          },
          "declarationFragments": [
            {
              "kind": "attribute",
              "spelling": "@"
            },
            {
              "kind": "attribute",
              "spelling": "MainActor",
              "preciseIdentifier": "s:ScM"
            },
            {
              "kind": "text",
              "spelling": " "
            },
            {
              "kind": "keyword",
              "spelling": "func"
            },
            {
              "kind": "text",
              "spelling": " "
            },
            {
              "kind": "identifier",
              "spelling": "something"
            },
            {
              "kind": "text",
              "spelling": "()"
            }
          ],
          "accessLevel": "public"
        }
        """
        let symbol = try makeSymbol(fromJson: inputJSON)

        let overloadDeclaration = symbol.overloadSubheadingFragments()
        // func something()
        XCTAssertEqual(overloadDeclaration?.map(\.spelling).joined(), "func something()")
        XCTAssertEqual(overloadDeclaration, [
            .init(kind: .keyword, spelling: "func", preciseIdentifier: nil),
            .init(kind: .text, spelling: " ", preciseIdentifier: nil),
            .init(kind: .identifier, spelling: "something", preciseIdentifier: nil),
            .init(kind: .text, spelling: "()", preciseIdentifier: nil),
        ])
    }

    func testRequiredInit() throws {
        // required init(_: String)
        let inputJSON = """
        {
          "kind": {
            "identifier": "swift.init",
            "displayName": "Initializer"
          },
          "identifier": {
            "precise": "s:10ModuleName8SubClassCyACSgSScfc",
            "interfaceLanguage": "swift"
          },
          "pathComponents": [
            "SubClass",
            "init(_:)"
          ],
          "names": {
            "title": "init(_:)",
            "subHeading": [
              {
                "kind": "keyword",
                "spelling": "init"
              },
              {
                "kind": "text",
                "spelling": "("
              },
              {
                "kind": "typeIdentifier",
                "spelling": "String",
                "preciseIdentifier": "s:SS"
              },
              {
                "kind": "text",
                "spelling": ")"
              }
            ]
          },
          "declarationFragments": [
            {
              "kind": "keyword",
              "spelling": "required"
            },
            {
              "kind": "text",
              "spelling": " "
            },
            {
              "kind": "keyword",
              "spelling": "init"
            },
            {
              "kind": "text",
              "spelling": "("
            },
            {
              "kind": "externalParam",
              "spelling": "_"
            },
            {
              "kind": "text",
              "spelling": ": "
            },
            {
              "kind": "typeIdentifier",
              "spelling": "String",
              "preciseIdentifier": "s:SS"
            },
            {
              "kind": "text",
              "spelling": ")"
            }
          ],
          "accessLevel": "public"
        }
        """
        let symbol = try makeSymbol(fromJson: inputJSON)

        let overloadDeclaration = symbol.overloadSubheadingFragments()
        // init()
        XCTAssertEqual(overloadDeclaration?.map(\.spelling).joined(), "init(_:)")
        XCTAssertEqual(overloadDeclaration, [
            .init(kind: .keyword, spelling: "init", preciseIdentifier: nil),
            .init(kind: .text, spelling: "(", preciseIdentifier: nil),
            .init(kind: .externalParameter, spelling: "_", preciseIdentifier: nil),
            .init(kind: .text, spelling: ":)", preciseIdentifier: nil),
        ])
    }
}

fileprivate func makeSymbol(fromJson json: String) throws -> SymbolGraph.Symbol {
    let decoder = JSONDecoder()
    return try decoder.decode(SymbolGraph.Symbol.self, from: json.data(using: .utf8)!)
}
