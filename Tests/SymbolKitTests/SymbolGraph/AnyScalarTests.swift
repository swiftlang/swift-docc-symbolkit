/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2023 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
import SymbolKit

class AnyScalarTests: XCTestCase {
    func testAnyScalarCanBeDecoded() throws {
        let decoder = JSONDecoder()
        var scalar = try decoder.decode(SymbolGraph.AnyScalar.self, from: "3".data(using: .utf8)!)
        XCTAssertEqual(scalar, .integer(3))
        
        scalar = try decoder.decode(SymbolGraph.AnyScalar.self, from: "3.5".data(using: .utf8)!)
        XCTAssertEqual(scalar, .float(3.5))
        
        scalar = try decoder.decode(SymbolGraph.AnyScalar.self, from: "\"test\"".data(using: .utf8)!)
        XCTAssertEqual(scalar, .string("test"))
        
        scalar = try decoder.decode(SymbolGraph.AnyScalar.self, from: "true".data(using: .utf8)!)
        XCTAssertEqual(scalar, .boolean(true))
        
        scalar = try decoder.decode(SymbolGraph.AnyScalar.self, from: "false".data(using: .utf8)!)
        XCTAssertEqual(scalar, .boolean(false))
        
        scalar = try decoder.decode(SymbolGraph.AnyScalar.self, from: "null".data(using: .utf8)!)
        XCTAssertEqual(scalar, .null)
    }
    
    func testAnyScalarThrowsOnError() throws {
        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(SymbolGraph.AnyScalar.self, from: "[3]".data(using: .utf8)!))
        XCTAssertThrowsError(try decoder.decode(SymbolGraph.AnyScalar.self, from: "{}".data(using: .utf8)!))
    }
    
    func testAnyNumberCanBeDecoded() throws {
        let decoder = JSONDecoder()
        var number = try decoder.decode(SymbolGraph.AnyNumber.self, from: "3".data(using: .utf8)!)
        XCTAssertEqual(number, .integer(3))
        
        number = try decoder.decode(SymbolGraph.AnyNumber.self, from: "3.5".data(using: .utf8)!)
        XCTAssertEqual(number, .float(3.5))
    }
    
    func testAnyNumberThrowsOnError() throws {
        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(SymbolGraph.AnyNumber.self, from: "[3]".data(using: .utf8)!))
        XCTAssertThrowsError(try decoder.decode(SymbolGraph.AnyNumber.self, from: "{}".data(using: .utf8)!))
        XCTAssertThrowsError(try decoder.decode(SymbolGraph.AnyNumber.self, from: "\"bad\"".data(using: .utf8)!))
    }
}
