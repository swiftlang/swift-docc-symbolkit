/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2023 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
import SymbolKit

final class HTTPTests: XCTestCase {
    func testRequestCanBeDecoded() throws {
        let jsonData = """
          {
            "accessLevel" : "public",
            "identifier" : {
              "interfaceLanguage" : "data",
              "precise" : "data:example:get:path1"
            },
            "kind" : {
              "displayName" : "HTTP Request",
              "identifier" : "httpRequest"
            },
            "names" : {
              "title" : "Get Something"
            },
            "pathComponents": [],
            "httpEndpoint": {
                "method": "get",
                "baseURL": "http://example.com",
                "path": "path1"
            }
        }
        """.data(using: .utf8)
        
        let decoder = JSONDecoder()
        let symbol = try decoder.decode(SymbolGraph.Symbol.self, from: jsonData!)
        
        XCTAssertEqual(symbol.kind.identifier, .httpRequest)
        XCTAssertNotNil(symbol.httpEndpoint)
        if let endpoint = symbol.httpEndpoint {
            XCTAssertEqual(endpoint.method, "GET")
            XCTAssertEqual(endpoint.baseURL, URL(string: "http://example.com"))
            XCTAssertEqual(endpoint.path, "path1")
            XCTAssertNil(endpoint.sandboxURL)
        }

        // Verify that the endpoint's method is always forced to uppercase
        var endpoint = SymbolGraph.Symbol.HTTP.Endpoint(method: "get", baseURL: URL(string: "http://example.com")!, path: "path")
        XCTAssertEqual(endpoint.method, "GET")
        endpoint.method = "put"
        XCTAssertEqual(endpoint.method, "PUT")
    }
    
    func testParameterCanBeDecoded() throws {
        let jsonData = """
          {
            "accessLevel" : "public",
            "identifier" : {
              "interfaceLanguage" : "data",
              "precise" : "data:example:get:path1@q=param1"
            },
            "kind" : {
              "displayName" : "HTTP Parameter",
              "identifier" : "httpParameter"
            },
            "names" : {
              "title" : "param1"
            },
            "pathComponents": [],
            "httpParameterSource": "query",
        }
        """.data(using: .utf8)
        
        let decoder = JSONDecoder()
        let symbol = try decoder.decode(SymbolGraph.Symbol.self, from: jsonData!)
        
        XCTAssertEqual(symbol.kind.identifier, .httpParameter)
        XCTAssertEqual(symbol.httpParameterSource, "query")
        XCTAssertNil(symbol.httpEndpoint)
    }
    
    func testResponseCanBeDecoded() throws {
        let jsonData = """
          {
            "accessLevel" : "public",
            "identifier" : {
              "interfaceLanguage" : "data",
              "precise" : "data:example:get:path1=200-application/json"
            },
            "kind" : {
              "displayName" : "HTTP Response",
              "identifier" : "httpResponse"
            },
            "names" : {
              "title" : "200"
            },
            "pathComponents": [],
            "httpMediaType": "application/json",
        }
        """.data(using: .utf8)
        
        let decoder = JSONDecoder()
        let symbol = try decoder.decode(SymbolGraph.Symbol.self, from: jsonData!)
        
        XCTAssertEqual(symbol.kind.identifier, .httpResponse)
        XCTAssertEqual(symbol.httpMediaType, "application/json")
        XCTAssertNil(symbol.httpEndpoint)
    }
    
    func testBodyCanBeDecoded() throws {
        let jsonData = """
          {
            "accessLevel" : "public",
            "identifier" : {
              "interfaceLanguage" : "data",
              "precise" : "data:example:get:path1@body=application/json"
            },
            "kind" : {
              "displayName" : "HTTP Body",
              "identifier" : "httpBody"
            },
            "names" : {
              "title" : "body"
            },
            "pathComponents": [],
            "httpMediaType": "application/json",
        }
        """.data(using: .utf8)
        
        let decoder = JSONDecoder()
        let symbol = try decoder.decode(SymbolGraph.Symbol.self, from: jsonData!)
        
        XCTAssertEqual(symbol.kind.identifier, .httpBody)
        XCTAssertEqual(symbol.httpMediaType, "application/json")
        XCTAssertNil(symbol.httpEndpoint)
    }
}
