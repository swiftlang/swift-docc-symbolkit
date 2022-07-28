/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2022 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
import SymbolKit

extension SymbolGraph.Module {
    func roundTripDecode() throws -> Self {
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(self)
        let decoder = JSONDecoder()
        return try decoder.decode(SymbolGraph.Module.self, from: encoded)
    }
}

class ModuleTests: XCTestCase {
    static let os = SymbolGraph.OperatingSystem(name: "macOS", minimumVersion: .init(major: 10, minor: 9, patch: 0))
    static let platform = SymbolGraph.Platform(architecture: "arm64", vendor: "Apple", operatingSystem: os)

    func testFullRoundTripCoding() throws {
        let module = SymbolGraph.Module(name: "Test", platform: ModuleTests.platform, bystanders: ["A"], isVirtual: true)
        let decodedModule = try module.roundTripDecode()
        XCTAssertEqual(module, decodedModule)
    }
    
    func testOptionalBystanders() throws {
        do {
            // bystanders = nil
            let module = SymbolGraph.Module(name: "Test", platform: ModuleTests.platform)
            let decodedModule = try module.roundTripDecode()
            XCTAssertNil(decodedModule.bystanders)
        }
        
        do {
            // bystanders = ["A"]
            let module = SymbolGraph.Module(name: "Test", platform: ModuleTests.platform, bystanders: ["A"])
            let decodedModule = try module.roundTripDecode()
            XCTAssertEqual(["A"], decodedModule.bystanders)
        }
    }
    
    func testOptionalIsVirtual() throws {
        do {
            // isVirtual = false
            let module = SymbolGraph.Module(name: "Test", platform: ModuleTests.platform)
            let decodedModule = try module.roundTripDecode()
            XCTAssertFalse(decodedModule.isVirtual)
        }
        
        do {
            // isVirtual = true
            let module = SymbolGraph.Module(name: "Test", platform: ModuleTests.platform, isVirtual: true)
            let decodedModule = try module.roundTripDecode()
            XCTAssertTrue(decodedModule.isVirtual)
        }
    }
    
    func testOptionalVersion() throws {
        do {
            // version = nil
            let module = SymbolGraph.Module(name: "Test", platform: ModuleTests.platform)
            let decodedModule = try module.roundTripDecode()
            XCTAssertNil(decodedModule.version)
        }
        
        do {
            // version = 1.0.0
            let version = SymbolGraph.SemanticVersion(major: 1, minor: 0, patch: 0)
            let module = SymbolGraph.Module(name: "Test", platform: ModuleTests.platform, version: version)
            let decodedModule = try module.roundTripDecode()
            XCTAssertEqual(version, decodedModule.version)
        }
    }
}
