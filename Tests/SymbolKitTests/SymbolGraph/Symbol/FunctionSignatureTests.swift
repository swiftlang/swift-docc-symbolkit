/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2023 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
import SymbolKit

class FunctionSignatureTests: XCTestCase {
    func testDecoding() throws {
        let jsonData = """
{
  "kind": {
    "identifier": "swift.func",
    "displayName": "Function"
  },
  "identifier": {
    "precise": "s:9Something02doA04withySi_tF",
    "interfaceLanguage": "swift"
  },
  "pathComponents": [
    "doSomething(with:)"
  ],
  "names": {
    "title": "doSomething(with:)"
  },
  "functionSignature": {
    "parameters": [
      {
        "name": "with",
        "internalName": "someValue",
        "declarationFragments": [
          {
            "kind": "identifier",
            "spelling": "someValue"
          },
          {
            "kind": "text",
            "spelling": ": "
          },
          {
            "kind": "typeIdentifier",
            "spelling": "Int",
            "preciseIdentifier": "s:Si"
          }
        ]
      }
    ],
    "returns": [
      {
        "kind": "typeIdentifier",
        "spelling": "Void",
        "preciseIdentifier": "s:s4Voida"
      }
    ]
  },
  "declarationFragments": [
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
      "spelling": "doSomething"
    },
    {
      "kind": "text",
      "spelling": "("
    },
    {
      "kind": "externalParam",
      "spelling": "with"
    },
    {
      "kind": "text",
      "spelling": " "
    },
    {
      "kind": "internalParam",
      "spelling": "someValue"
    },
    {
      "kind": "text",
      "spelling": ": "
    },
    {
      "kind": "typeIdentifier",
      "spelling": "Int",
      "preciseIdentifier": "s:Si"
    },
    {
      "kind": "text",
      "spelling": ")"
    }
  ],
  "accessLevel": "public",
  "location": {
    "uri": "file:///Users/username/path/to/SomeFile.swift",
    "position": {
      "line": 9,
      "character": 12
    }
  }
}
""".data(using: .utf8)
        
        let decoder = JSONDecoder()
        let symbol = try decoder.decode(SymbolGraph.Symbol.self, from: jsonData!)
        
        let functionSignature = try XCTUnwrap(symbol.functionSignature)
        
        XCTAssertEqual(functionSignature.parameters.count, 1)
        
        let parameter = try XCTUnwrap(functionSignature.parameters.first)
        XCTAssertEqual(parameter.externalName, "with")
        XCTAssertEqual(parameter.internalName, "someValue")
        XCTAssertEqual(parameter.declarationFragments.map(\.spelling).joined(), "someValue: Int")
        
        XCTAssertEqual(parameter.name, "someValue")
        
        XCTAssertEqual(functionSignature.returns.count, 1)
        XCTAssertEqual(functionSignature.returns.first?.spelling, "Void")
    }
    
    func testEncoding() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        // Different external and internal parameter names
        let functionSignatureWithDifferentParameterNames = SymbolGraph.Symbol.FunctionSignature(
            parameters: [
                .init(
                    externalName: "externalName",
                    internalName: "internalName",
                    declarationFragments: [
                        .init(kind: .identifier, spelling: "internalParam", preciseIdentifier: nil),
                        .init(kind: .text, spelling: ": ", preciseIdentifier: nil),
                        .init(kind: .typeIdentifier, spelling: "Int", preciseIdentifier: "s:Si"),
                    ],
                    children: []
                )
            ],
            returns: [
                .init(kind: .typeIdentifier, spelling: "Void", preciseIdentifier: "s:s4Voida")
            ]
        )
        
        let encodedDifferentParameterNames = try XCTUnwrap(String(data: encoder.encode(functionSignatureWithDifferentParameterNames), encoding: .utf8))
        XCTAssertEqual(encodedDifferentParameterNames, """
            {
              "parameters" : [
                {
                  "children" : [

                  ],
                  "declarationFragments" : [
                    {
                      "kind" : "identifier",
                      "spelling" : "internalParam"
                    },
                    {
                      "kind" : "text",
                      "spelling" : ": "
                    },
                    {
                      "kind" : "typeIdentifier",
                      "preciseIdentifier" : "s:Si",
                      "spelling" : "Int"
                    }
                  ],
                  "internalName" : "internalName",
                  "name" : "externalName"
                }
              ],
              "returns" : [
                {
                  "kind" : "typeIdentifier",
                  "preciseIdentifier" : "s:s4Voida",
                  "spelling" : "Void"
                }
              ]
            }
            """
        )
        
        // Same external and internal parameter name
        let functionSignatureWithSameParameterNames = SymbolGraph.Symbol.FunctionSignature(
            parameters: [
                .init(
                    externalName: "externalName",
                    internalName: "externalName",
                    declarationFragments: [
                        .init(kind: .identifier, spelling: "externalParam", preciseIdentifier: nil),
                        .init(kind: .text, spelling: ": ", preciseIdentifier: nil),
                        .init(kind: .typeIdentifier, spelling: "Int", preciseIdentifier: "s:Si"),
                    ],
                    children: []
                )
            ],
            returns: [
                .init(kind: .typeIdentifier, spelling: "Void", preciseIdentifier: "s:s4Voida")
            ]
        )
        
        let encodedSameParameterNames = try XCTUnwrap(String(data: encoder.encode(functionSignatureWithSameParameterNames), encoding: .utf8))
        XCTAssertEqual(encodedSameParameterNames, """
            {
              "parameters" : [
                {
                  "children" : [

                  ],
                  "declarationFragments" : [
                    {
                      "kind" : "identifier",
                      "spelling" : "externalParam"
                    },
                    {
                      "kind" : "text",
                      "spelling" : ": "
                    },
                    {
                      "kind" : "typeIdentifier",
                      "preciseIdentifier" : "s:Si",
                      "spelling" : "Int"
                    }
                  ],
                  "name" : "externalName"
                }
              ],
              "returns" : [
                {
                  "kind" : "typeIdentifier",
                  "preciseIdentifier" : "s:s4Voida",
                  "spelling" : "Void"
                }
              ]
            }
            """
        )
        
        // Initialized with no internal name
        let functionSignatureWithNoInternalParameterNames = SymbolGraph.Symbol.FunctionSignature(
            parameters: [
                .init(
                    externalName: "externalName",
                    internalName: nil,
                    declarationFragments: [
                        .init(kind: .identifier, spelling: "externalParam", preciseIdentifier: nil),
                        .init(kind: .text, spelling: ": ", preciseIdentifier: nil),
                        .init(kind: .typeIdentifier, spelling: "Int", preciseIdentifier: "s:Si"),
                    ],
                    children: []
                )
            ],
            returns: [
                .init(kind: .typeIdentifier, spelling: "Void", preciseIdentifier: "s:s4Voida")
            ]
        )
        
        let encodedNoInternalParameterName = try XCTUnwrap(String(data: encoder.encode(functionSignatureWithNoInternalParameterNames), encoding: .utf8))
        XCTAssertEqual(encodedNoInternalParameterName, """
            {
              "parameters" : [
                {
                  "children" : [

                  ],
                  "declarationFragments" : [
                    {
                      "kind" : "identifier",
                      "spelling" : "externalParam"
                    },
                    {
                      "kind" : "text",
                      "spelling" : ": "
                    },
                    {
                      "kind" : "typeIdentifier",
                      "preciseIdentifier" : "s:Si",
                      "spelling" : "Int"
                    }
                  ],
                  "name" : "externalName"
                }
              ],
              "returns" : [
                {
                  "kind" : "typeIdentifier",
                  "preciseIdentifier" : "s:s4Voida",
                  "spelling" : "Void"
                }
              ]
            }
            """
        )
    }
    
    func testSettingFunctionParameterName() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        // Different external and internal parameter names
        var functionSignatureWithDifferentParameterNames = SymbolGraph.Symbol.FunctionSignature(
            parameters: [
                .init(
                    externalName: "externalName",
                    internalName: "internalName",
                    declarationFragments: [],
                    children: []
                )
            ],
            returns: []
        )
        functionSignatureWithDifferentParameterNames.parameters[0].name = "newName"
        
        let encodedDifferentParameterNames = try XCTUnwrap(String(data: encoder.encode(functionSignatureWithDifferentParameterNames), encoding: .utf8))
        XCTAssertEqual(encodedDifferentParameterNames, """
            {
              "parameters" : [
                {
                  "children" : [

                  ],
                  "declarationFragments" : [

                  ],
                  "internalName" : "newName",
                  "name" : "externalName"
                }
              ],
              "returns" : [

              ]
            }
            """
        )
        
        // Same external and internal parameter name
        var functionSignatureWithSameParameterNames = SymbolGraph.Symbol.FunctionSignature(
            parameters: [
                .init(
                    externalName: "externalName",
                    internalName: "externalName",
                    declarationFragments: [],
                    children: []
                )
            ],
            returns: []
        )
        functionSignatureWithSameParameterNames.parameters[0].name = "newName"
            
        let encodedSameParameterNames = try XCTUnwrap(String(data: encoder.encode(functionSignatureWithSameParameterNames), encoding: .utf8))
        XCTAssertEqual(encodedSameParameterNames, """
            {
              "parameters" : [
                {
                  "children" : [

                  ],
                  "declarationFragments" : [

                  ],
                  "name" : "newName"
                }
              ],
              "returns" : [

              ]
            }
            """
        )
        
        // Initialized with no internal name
        var functionSignatureWithNoInternalParameterNames = SymbolGraph.Symbol.FunctionSignature(
            parameters: [
                .init(
                    externalName: "externalName",
                    internalName: nil,
                    declarationFragments: [],
                    children: []
                )
            ],
            returns: []
        )
        functionSignatureWithNoInternalParameterNames.parameters[0].name = "newName"
        
        let encodedNoInternalParameterName = try XCTUnwrap(String(data: encoder.encode(functionSignatureWithNoInternalParameterNames), encoding: .utf8))
        XCTAssertEqual(encodedNoInternalParameterName, """
            {
              "parameters" : [
                {
                  "children" : [

                  ],
                  "declarationFragments" : [

                  ],
                  "name" : "newName"
                }
              ],
              "returns" : [

              ]
            }
            """
        )
        
        // Different external and internal parameter names
        var functionSignatureInternalParameterNameSetAfterInitialization = SymbolGraph.Symbol.FunctionSignature(
            parameters: [
                .init(
                    externalName: "externalName",
                    internalName: nil,
                    declarationFragments: [],
                    children: []
                )
            ],
            returns: []
        )
        functionSignatureInternalParameterNameSetAfterInitialization.parameters[0].internalName = "newInternalName"
        functionSignatureInternalParameterNameSetAfterInitialization.parameters[0].name = "newName"
        
        let encodedInternalParameterNameSetAfterInitialization = try XCTUnwrap(String(data: encoder.encode(functionSignatureInternalParameterNameSetAfterInitialization), encoding: .utf8))
        XCTAssertEqual(encodedInternalParameterNameSetAfterInitialization, """
            {
              "parameters" : [
                {
                  "children" : [

                  ],
                  "declarationFragments" : [

                  ],
                  "internalName" : "newName",
                  "name" : "externalName"
                }
              ],
              "returns" : [

              ]
            }
            """
        )
    }
}

