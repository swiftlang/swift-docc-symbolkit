/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2024 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
import SymbolKit

final class PlistDetailsTests: XCTestCase {
    
    func testPlistDetailsCanBeDecoded() throws {
        let jsonData = """
          {
            "accessLevel" : "public",
            "identifier" : {
              "interfaceLanguage" : "plist",
              "precise" : "plist:Information_Property_List.plist"
            },
            "kind" : {
              "displayName" : "Property List Key",
               "identifier" : "typealias"
            },
            "names" : {
              "navigator" : [
                {
                  "kind" : "identifier",
                  "spelling" : "plist"
                }
              ],
              "title" : "plist"
            },
            "pathComponents" : [
              "Information-Property-List",
              "plist"
            ],
            "plistDetails" : {
              "arrayMode" : true,
              "baseType" : "Information Property List",
              "rawKey" : "info-plist"
            }
          }
        """.data(using: .utf8)
        
        let decoder = JSONDecoder()
        let symbol = try decoder.decode(SymbolGraph.Symbol.self, from: jsonData!)
        
        let plistDetails = try XCTUnwrap(symbol.plistDetails)
        XCTAssertEqual(plistDetails.rawKey, "info-plist")
        XCTAssertEqual(plistDetails.baseType, "Information Property List")
        XCTAssertEqual(plistDetails.arrayMode, true)
    }
    
}
