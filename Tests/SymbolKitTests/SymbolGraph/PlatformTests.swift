/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
import SymbolKit

class PlatformTests: XCTestCase {
    func testMacosIsValidOperatingSystem() {
        let macosPlatform = SymbolGraph.Platform(
            architecture: nil,
            vendor: nil,
            operatingSystem: SymbolGraph.OperatingSystem(name: "macos"),
            environment: nil
        )
        
        XCTAssertEqual(macosPlatform.name, "macOS", "'macos' should be a valid OS identifier.")
    }
    
    func testMacosxIsValidOperatingSystem() {
        let macosxPlatform = SymbolGraph.Platform(
            architecture: nil,
            vendor: nil,
            operatingSystem: SymbolGraph.OperatingSystem(name: "macosx"),
            environment: nil
        )
        
        XCTAssertEqual(macosxPlatform.name, "macOS", "'macosx' should be a valid OS identifier.")
    }
}
