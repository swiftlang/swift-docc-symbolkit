/*
 This source file is part of the Swift.org open source project
 
 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception
 
 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
 */

import XCTest
@testable import SymbolKit

final class SemanticVersionTests: XCTestCase {
    
    typealias Version = SymbolGraph.SemanticVersion
    
    func testVersionInitialization() {
        let v0 = Version(0, 0, 0, prereleaseIdentifiers: [], buildMetadataIdentifiers: [])
        XCTAssertEqual(v0.minor, 0)
        XCTAssertEqual(v0.minor, 0)
        XCTAssertEqual(v0.patch, 0)
        XCTAssertEqual(v0.prereleaseIdentifiers, [])
        XCTAssertEqual(v0.buildMetadataIdentifiers, [])
        
        let v1 = Version(1, 1, 2, prereleaseIdentifiers: ["3", "5"], buildMetadataIdentifiers: ["8", "13"])
        XCTAssertEqual(v1.minor, 1)
        XCTAssertEqual(v1.minor, 1)
        XCTAssertEqual(v1.patch, 2)
        XCTAssertEqual(v1.prereleaseIdentifiers, ["3", "5"])
        XCTAssertEqual(v1.buildMetadataIdentifiers, ["8", "13"])
        
        XCTAssertEqual(
            Version(3, 5, 8),
            Version(3, 5, 8, prereleaseIdentifiers: [], buildMetadataIdentifiers: [])
        )
        
        XCTAssertEqual(
            Version(13, 21, 34, prereleaseIdentifiers: ["55"]),
            Version(13, 21, 34, prereleaseIdentifiers: ["55"], buildMetadataIdentifiers: [])
        )
        
        XCTAssertEqual(
            Version(89, 144, 233, buildMetadataIdentifiers: ["377"]),
            Version(89, 144, 233, prereleaseIdentifiers: [], buildMetadataIdentifiers: ["377"])
        )
    }
    
    func testDecodingFromJSONToVersion() {
        let jsonDecoder = JSONDecoder()
        
        let versionObjectString1 = """
            {
                "major": 1
            }
            """
        let versionObjectData1 = Data(versionObjectString1.utf8)
        let version1 = Version(1, 0, 0)
        XCTAssertNoThrow(
            try {
                let decodedVersion1 = try jsonDecoder.decode(Version.self, from: versionObjectData1)
                XCTAssertEqual(version1, decodedVersion1)
            }()
        )
        
        let versionObjectString2 = """
            {
                "major": 1,
                "minor": 42
            }
            """
        let versionObjectData2 = Data(versionObjectString2.utf8)
        let version2 = Version(1, 42, 0)
        XCTAssertNoThrow(
            try {
                let decodedVersion2 = try jsonDecoder.decode(Version.self, from: versionObjectData2)
                XCTAssertEqual(version2, decodedVersion2)
            }()
        )
        
        let versionObjectString3 = """
            {
                "major": 4,
                "patch": 2
            }
            """
        let versionObjectData3 = Data(versionObjectString3.utf8)
        let version3 = Version(4, 0, 2)
        XCTAssertNoThrow(
            try {
                let decodedVersion3 = try jsonDecoder.decode(Version.self, from: versionObjectData3)
                XCTAssertEqual(version3, decodedVersion3)
            }()
        )
        
        let versionObjectString4 = """
            {
                "major": 100,
                "prerelease": "bvf7yuv"
            }
            """
        let versionObjectData4 = Data(versionObjectString4.utf8)
        let version4 = Version(
            100, 0, 0,
            prereleaseIdentifiers: ["bvf7yuv"]
        )
        XCTAssertNoThrow(
            try {
                let decodedVersion4 = try jsonDecoder.decode(Version.self, from: versionObjectData4)
                XCTAssertEqual(version4, decodedVersion4)
            }()
        )
        
        let versionObjectString5 = """
            {
                "major": 99999,
                "buildMetadata": "UZryk-09btxguch"
            }
            """
        let versionObjectData5 = Data(versionObjectString5.utf8)
        let version5 = Version(
            99999, 0, 0,
            buildMetadataIdentifiers: ["UZryk-09btxguch"]
        )
        XCTAssertNoThrow(
            try {
                let decodedVersion5 = try jsonDecoder.decode(Version.self, from: versionObjectData5)
                XCTAssertEqual(version5, decodedVersion5)
            }()
        )
        
        let versionObjectString6 = """
            {
                "major": 1,
                "minor": 2,
                "patch": 3,
                "prerelease": "abc.def-ghi",
                "buildMetadata": "xyz.abc-def.gf765c7v.7867ft.ghi--uvw"
            }
            """
        let versionObjectData6 = Data(versionObjectString6.utf8)
        let version6 = Version(
            1, 2, 3,
            prereleaseIdentifiers: ["abc", "def-ghi"],
            buildMetadataIdentifiers: ["xyz", "abc-def", "gf765c7v", "7867ft", "ghi--uvw"]
        )
        XCTAssertNoThrow(
            try {
                let decodedVersion6 = try jsonDecoder.decode(Version.self, from: versionObjectData6)
                XCTAssertEqual(version6, decodedVersion6)
            }()
        )
        
        let versionObjectString7 = """
            {
                "major": 1,
                "minor": 2,
                "patch": 3,
                "prerelease": ""
            }
            """
        let versionObjectData7 = Data(versionObjectString7.utf8)
        let version7 = Version(
            1, 2, 3,
            prereleaseIdentifiers: [""],
            buildMetadataIdentifiers: []
        )
        XCTAssertNoThrow(
            try {
                let decodedVersion7 = try jsonDecoder.decode(Version.self, from: versionObjectData7)
                XCTAssertEqual(version7, decodedVersion7)
            }()
        )
        
        let versionObjectString8 = """
            {
                "major": 1,
                "minor": 2,
                "patch": 3,
                "buildMetadata": ""
            }
            """
        let versionObjectData8 = Data(versionObjectString8.utf8)
        let version8 = Version(
            1, 2, 3,
            prereleaseIdentifiers: [],
            buildMetadataIdentifiers: [""]
        )
        XCTAssertNoThrow(
            try {
                let decodedVersion8 = try jsonDecoder.decode(Version.self, from: versionObjectData8)
                XCTAssertEqual(version8, decodedVersion8)
            }()
        )
        
        let versionObjectString9 = """
            {
                "major": 1,
                "minor": 2,
                "patch": 3,
                "prerelease": "",
                "buildMetadata": ""
            }
            """
        let versionObjectData9 = Data(versionObjectString9.utf8)
        let version9 = Version(
            1, 2, 3,
            prereleaseIdentifiers: [""],
            buildMetadataIdentifiers: [""]
        )
        XCTAssertNoThrow(
            try {
                let decodedVersion9 = try jsonDecoder.decode(Version.self, from: versionObjectData9)
                XCTAssertEqual(version9, decodedVersion9)
            }()
        )
    }
    
    func testEncodingFromVersionToJSON() {
        let jsonEncoder1 = JSONEncoder()
        jsonEncoder1.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        let versionObjectString1 = """
            {
                "major": 1,
                "minor": 0,
                "patch": 0
            }
            """
        let version1 = Version(1, 0, 0)
        XCTAssertNoThrow(
            try {
                let encodedVersion1 = try jsonEncoder1.encode(version1)
                XCTAssertEqual(
                    String(data: encodedVersion1, encoding: .utf8),
                    // Because Semantic Versioning 2.0.0 does not allow whitespace in identifiers, we can remove whitespace from the string with no worry.
                    versionObjectString1.filter { !$0.isWhitespace }
                )
            }()
        )
        
        let jsonEncoder2 = JSONEncoder()
        jsonEncoder2.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        let versionObjectString2 = """
            {
                "buildMetadata": "",
                "major": 1,
                "minor": 0,
                "patch": 0,
                "prerelease": ""
            }
            """
        let version2 = Version(1, 0, 0, prereleaseIdentifiers: [""], buildMetadataIdentifiers: [""])
        XCTAssertNoThrow(
            try {
                let encodedVersion2 = try jsonEncoder2.encode(version2)
                XCTAssertEqual(
                    String(data: encodedVersion2, encoding: .utf8),
                    // Because Semantic Versioning 2.0.0 does not allow whitespace in identifiers, we can remove whitespace from the string with no worry.
                    versionObjectString2.filter { !$0.isWhitespace }
                )
            }()
        )
        
        let jsonEncoder3 = JSONEncoder()
        jsonEncoder3.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        let versionObjectString3 = """
            {
                "major": 1,
                "minor": 42,
                "patch": 0
            }
            """
        let version3 = Version(1, 42, 0)
        XCTAssertNoThrow(
            try {
                let encodedVersion3 = try jsonEncoder3.encode(version3)
                XCTAssertEqual(
                    String(data: encodedVersion3, encoding: .utf8),
                    versionObjectString3.filter { !$0.isWhitespace }
                )
            }()
        )
        
        let jsonEncoder4 = JSONEncoder()
        jsonEncoder4.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        let versionObjectString4 = """
            {
                "buildMetadata": "",
                "major": 1,
                "minor": 42,
                "patch": 0,
                "prerelease": ""
            }
            """
        let version4 = Version(1, 42, 0, prereleaseIdentifiers: [""], buildMetadataIdentifiers: [""])
        XCTAssertNoThrow(
            try {
                let encodedVersion4 = try jsonEncoder4.encode(version4)
                XCTAssertEqual(
                    String(data: encodedVersion4, encoding: .utf8),
                    versionObjectString4.filter { !$0.isWhitespace }
                )
            }()
        )
        
        let jsonEncoder5 = JSONEncoder()
        jsonEncoder5.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        let versionObjectString5 = """
            {
                "major": 4,
                "minor": 0,
                "patch": 2
            }
            """
        let version5 = Version(4, 0, 2)
        XCTAssertNoThrow(
            try {
                let encodedVersion5 = try jsonEncoder5.encode(version5)
                XCTAssertEqual(
                    String(data: encodedVersion5, encoding: .utf8),
                    versionObjectString5.filter { !$0.isWhitespace }
                )
            }()
        )
        
        let jsonEncoder6 = JSONEncoder()
        jsonEncoder6.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        let versionObjectString6 = """
            {
                "buildMetadata": "",
                "major": 4,
                "minor": 0,
                "patch": 2,
                "prerelease": ""
            }
            """
        let version6 = Version(4, 0, 2, prereleaseIdentifiers: [""], buildMetadataIdentifiers: [""])
        XCTAssertNoThrow(
            try {
                let encodedVersion6 = try jsonEncoder6.encode(version6)
                XCTAssertEqual(
                    String(data: encodedVersion6, encoding: .utf8),
                    versionObjectString6.filter { !$0.isWhitespace }
                )
            }()
        )
        
        let jsonEncoder7 = JSONEncoder()
        jsonEncoder7.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        let versionObjectString7 = """
            {
                "major": 100,
                "minor": 0,
                "patch": 0,
                "prerelease": "-j9uh08y97"
            }
            """
        let version7 = Version(
            100, 0, 0,
            prereleaseIdentifiers: ["-j9uh08y97"]
        )
        XCTAssertNoThrow(
            try {
                let encodedVersion7 = try jsonEncoder7.encode(version7)
                XCTAssertEqual(
                    String(data: encodedVersion7, encoding: .utf8),
                    versionObjectString7.filter { !$0.isWhitespace }
                )
            }()
        )
        
        let jsonEncoder8 = JSONEncoder()
        jsonEncoder8.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        let versionObjectString8 = """
            {
                "buildMetadata": "",
                "major": 100,
                "minor": 0,
                "patch": 0,
                "prerelease": "-j9uh08y97"
            }
            """
        let version8 = Version(
            100, 0, 0,
            prereleaseIdentifiers: ["-j9uh08y97"],
            buildMetadataIdentifiers: [""]
        )
        XCTAssertNoThrow(
            try {
                let encodedVersion8 = try jsonEncoder8.encode(version8)
                XCTAssertEqual(
                    String(data: encodedVersion8, encoding: .utf8),
                    versionObjectString8.filter { !$0.isWhitespace }
                )
            }()
        )
        
        let jsonEncoder9 = JSONEncoder()
        jsonEncoder9.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        let versionObjectString9 = """
            {
                "buildMetadata": "vvbcxqbo-bvy.HIu",
                "major": 99999,
                "minor": 0,
                "patch": 0
            }
            """
        let version9 = Version(
            99999, 0, 0,
            buildMetadataIdentifiers: ["vvbcxqbo-bvy", "HIu"]
        )
        XCTAssertNoThrow(
            try {
                let encodedVersion9 = try jsonEncoder9.encode(version9)
                XCTAssertEqual(
                    String(data: encodedVersion9, encoding: .utf8),
                    versionObjectString9.filter { !$0.isWhitespace }
                )
            }()
        )
        
        let jsonEncoder10 = JSONEncoder()
        jsonEncoder10.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        let versionObjectString10 = """
            {
                "buildMetadata": "vvbcxqbo-bvy.HIu",
                "major": 99999,
                "minor": 0,
                "patch": 0,
                "prerelease": ""
            }
            """
        let version10 = Version(
            99999, 0, 0,
            prereleaseIdentifiers: [""],
            buildMetadataIdentifiers: ["vvbcxqbo-bvy", "HIu"]
        )
        XCTAssertNoThrow(
            try {
                let encodedVersion10 = try jsonEncoder10.encode(version10)
                XCTAssertEqual(
                    String(data: encodedVersion10, encoding: .utf8),
                    versionObjectString10.filter { !$0.isWhitespace }
                )
            }()
        )
        
        let jsonEncoder11 = JSONEncoder()
        jsonEncoder11.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        let versionObjectString11 = """
            {
                "buildMetadata": "xyz.abc-def.----..ghi-uvw",
                "major": 1,
                "minor": 2,
                "patch": 3,
                "prerelease": "abc.def-ghi"
            }
            """
        let version11 = Version(
            1, 2, 3,
            prereleaseIdentifiers: ["abc", "def-ghi"],
            buildMetadataIdentifiers: ["xyz", "abc-def", "----", "", "ghi-uvw"]
        )
        XCTAssertNoThrow(
            try {
                let encodedVersion11 = try jsonEncoder11.encode(version11)
                XCTAssertEqual(
                    String(data: encodedVersion11, encoding: .utf8),
                    versionObjectString11.filter { !$0.isWhitespace }
                )
            }()
        )
    }
    
    func testJSONRoundTrip() {
        let jsonDecoder = JSONDecoder()
        
        let jsonEncoder1 = JSONEncoder()
        let version1 = Version(1, 0, 0)
        XCTAssertNoThrow(
            try {
                let roundTripVersion1 = try jsonDecoder.decode(Version.self, from: jsonEncoder1.encode(version1))
                print(version1.prereleaseIdentifiers)
                print(roundTripVersion1.prereleaseIdentifiers)
                XCTAssertEqual(version1, roundTripVersion1)
            }()
        )
        
        let jsonEncoder2 = JSONEncoder()
        let version2 = Version(1, 42, 0)
        XCTAssertNoThrow(
            try {
                let roundTripVersion2 = try jsonDecoder.decode(Version.self, from: jsonEncoder2.encode(version2))
                XCTAssertEqual(version2, roundTripVersion2)
            }()
        )
        
        let jsonEncoder3 = JSONEncoder()
        let version3 = Version(4, 0, 2)
        XCTAssertNoThrow(
            try {
                let roundTripVersion3 = try jsonDecoder.decode(Version.self, from: jsonEncoder3.encode(version3))
                XCTAssertEqual(version3, roundTripVersion3)
            }()
        )
        
        let jsonEncoder4 = JSONEncoder()
        let version4 = Version(
            100, 0, 0,
            prereleaseIdentifiers: ["bvf7yuv"]
        )
        XCTAssertNoThrow(
            try {
                let roundTripVersion4 = try jsonDecoder.decode(Version.self, from: jsonEncoder4.encode(version4))
                XCTAssertEqual(version4, roundTripVersion4)
            }()
        )
        
        let jsonEncoder5 = JSONEncoder()
        let version5 = Version(
            99999, 0, 0,
            buildMetadataIdentifiers: ["UZryk-09btxguch"]
        )
        XCTAssertNoThrow(
            try {
                let roundTripVersion5 = try jsonDecoder.decode(Version.self, from: jsonEncoder5.encode(version5))
                XCTAssertEqual(version5, roundTripVersion5)
            }()
        )
        
        let jsonEncoder6 = JSONEncoder()
        let version6 = Version(
            1, 2, 3,
            prereleaseIdentifiers: ["abc", "def-ghi"],
            buildMetadataIdentifiers: ["xyz", "abc-def", "gf765c7v", "7867ft", "ghi--uvw"]
        )
        XCTAssertNoThrow(
            try {
                let roundTripVersion6 = try jsonDecoder.decode(Version.self, from: jsonEncoder6.encode(version6))
                XCTAssertEqual(version6, roundTripVersion6)
            }()
        )
        
        let jsonEncoder7 = JSONEncoder()
        let version7 = Version(
            1, 2, 3,
            prereleaseIdentifiers: [""],
            buildMetadataIdentifiers: []
        )
        XCTAssertNoThrow(
            try {
                let roundTripVersion7 = try jsonDecoder.decode(Version.self, from: jsonEncoder7.encode(version7))
                XCTAssertEqual(version7, roundTripVersion7)
            }()
        )
        
        let jsonEncoder8 = JSONEncoder()
        let version8 = Version(
            1, 2, 3,
            prereleaseIdentifiers: [],
            buildMetadataIdentifiers: [""]
        )
        XCTAssertNoThrow(
            try {
                let roundTripVersion8 = try jsonDecoder.decode(Version.self, from: jsonEncoder8.encode(version8))
                XCTAssertEqual(version8, roundTripVersion8)
            }()
        )
        
        let jsonEncoder9 = JSONEncoder()
        let version9 = Version(
            1, 2, 3,
            prereleaseIdentifiers: [""],
            buildMetadataIdentifiers: [""]
        )
        XCTAssertNoThrow(
            try {
                let roundTripVersion9 = try jsonDecoder.decode(Version.self, from: jsonEncoder9.encode(version9))
                XCTAssertEqual(version9, roundTripVersion9)
            }()
        )
    }
    
    func testVersionComparison() {
        
        // MARK: version core vs. version core
        
        XCTAssertGreaterThan(Version(2, 1, 1), Version(1, 2, 3))
        XCTAssertGreaterThan(Version(1, 3, 1), Version(1, 2, 3))
        XCTAssertGreaterThan(Version(1, 2, 4), Version(1, 2, 3))
        
        XCTAssertFalse(Version(2, 1, 1) < Version(1, 2, 3))
        XCTAssertFalse(Version(1, 3, 1) < Version(1, 2, 3))
        XCTAssertFalse(Version(1, 2, 4) < Version(1, 2, 3))
        
        // MARK: version core vs. version core + pre-release
        
        XCTAssertGreaterThan(Version(1, 2, 3), Version(1, 2, 3, prereleaseIdentifiers: [""]))
        XCTAssertGreaterThan(Version(1, 2, 3), Version(1, 2, 3, prereleaseIdentifiers: ["beta"]))
        XCTAssertFalse(Version(1, 2, 3) < Version(1, 2, 3, prereleaseIdentifiers: [""]))
        XCTAssertFalse(Version(1, 2, 3) < Version(1, 2, 3, prereleaseIdentifiers: ["beta"]))
        XCTAssertLessThan(Version(1, 2, 2), Version(1, 2, 3, prereleaseIdentifiers: ["beta"]))
        
        // MARK: version core + pre-release vs. version core + pre-release
        
        XCTAssertEqual(Version(1, 2, 3, prereleaseIdentifiers: [""]), Version(1, 2, 3, prereleaseIdentifiers: [""]))
        
        XCTAssertEqual(Version(1, 2, 3, prereleaseIdentifiers: ["beta"]), Version(1, 2, 3, prereleaseIdentifiers: ["beta"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["alpha"]), Version(1, 2, 3, prereleaseIdentifiers: ["beta"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["alpha1"]), Version(1, 2, 3, prereleaseIdentifiers: ["alpha2"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["alpha"]), Version(1, 2, 3, prereleaseIdentifiers: ["alpha-"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["beta", "alpha"]), Version(1, 2, 3, prereleaseIdentifiers: ["beta", "beta"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["alpha", "beta"]), Version(1, 2, 3, prereleaseIdentifiers: ["beta", "alpha"]))
        
        XCTAssertEqual(Version(1, 2, 3, prereleaseIdentifiers: ["1"]), Version(1, 2, 3, prereleaseIdentifiers: ["1"]))
        XCTAssertEqual(Version(1, 2, 3, prereleaseIdentifiers: ["1"]), Version(1, 2, 3, prereleaseIdentifiers: ["001"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["1"]), Version(1, 2, 3, prereleaseIdentifiers: ["2"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["1", "1"]), Version(1, 2, 3, prereleaseIdentifiers: ["1", "2"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["001", "1"]), Version(1, 2, 3, prereleaseIdentifiers: ["1", "2"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["1", "1"]), Version(1, 2, 3, prereleaseIdentifiers: ["001", "2"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["1", "1"]), Version(1, 2, 3, prereleaseIdentifiers: ["1", "002"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["1", "2"]), Version(1, 2, 3, prereleaseIdentifiers: ["2", "1"]))
        
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["123"]), Version(1, 2, 3, prereleaseIdentifiers: ["123alpha"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["223"]), Version(1, 2, 3, prereleaseIdentifiers: ["123alpha"]))
        
        XCTAssertGreaterThan(Version(1, 2, 3, prereleaseIdentifiers: ["abc"]), Version(1, 2, 3, prereleaseIdentifiers: ["123"]))
        XCTAssertGreaterThan(Version(1, 2, 3, prereleaseIdentifiers: ["123abc"]), Version(1, 2, 3, prereleaseIdentifiers: ["223"]))
        
        XCTAssertFalse(Version(1, 2, 3, prereleaseIdentifiers: ["abc"]) < Version(1, 2, 3, prereleaseIdentifiers: ["123"]))
        XCTAssertFalse(Version(1, 2, 3, prereleaseIdentifiers: ["123abc"]) < Version(1, 2, 3, prereleaseIdentifiers: ["223"]))
        
        XCTAssertGreaterThan(Version(1, 2, 3, prereleaseIdentifiers: ["baa"]), Version(1, 2, 3, prereleaseIdentifiers: ["azzz"]))
        XCTAssertGreaterThan(Version(1, 2, 3, prereleaseIdentifiers: ["b", "z"]), Version(1, 2, 3, prereleaseIdentifiers: ["abc", "a", "zzz"]))
        
        XCTAssertFalse(Version(1, 2, 3, prereleaseIdentifiers: ["baa"]) < Version(1, 2, 3, prereleaseIdentifiers: ["azzz"]))
        XCTAssertFalse(Version(1, 2, 3, prereleaseIdentifiers: ["b", "z"]) < Version(1, 2, 3, prereleaseIdentifiers: ["abc", "a", "zzz"]))
        
        // MARK: version core vs. version core + build metadata
        
        XCTAssertEqual(Version(1, 2, 3), Version(1, 2, 3, buildMetadataIdentifiers: [""]))
        XCTAssertEqual(Version(1, 2, 3), Version(1, 2, 3, buildMetadataIdentifiers: ["beta"]))
        XCTAssertLessThan(Version(1, 2, 2), Version(1, 2, 3, buildMetadataIdentifiers: ["beta"]))
        
        // MARK: version core + pre-release vs. version core + build metadata
        
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: [""]), Version(1, 2, 3, buildMetadataIdentifiers: [""]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["beta"]), Version(1, 2, 3, buildMetadataIdentifiers: ["alpha"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["alpha"]), Version(1, 2, 3, buildMetadataIdentifiers: ["beta"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["beta"]), Version(1, 2, 3, buildMetadataIdentifiers: ["beta"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["alpha"]), Version(1, 2, 3, buildMetadataIdentifiers: ["alpha-"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["123"]), Version(1, 2, 3, buildMetadataIdentifiers: ["123alpha"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["223"]), Version(1, 2, 3, buildMetadataIdentifiers: ["123alpha"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["123alpha"]), Version(1, 2, 3, buildMetadataIdentifiers: ["123"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["123alpha"]), Version(1, 2, 3, buildMetadataIdentifiers: ["223"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["123alpha"]), Version(1, 2, 3, buildMetadataIdentifiers: ["223"]))
        XCTAssertLessThan(Version(1, 2, 3, prereleaseIdentifiers: ["alpha"]), Version(1, 2, 3, buildMetadataIdentifiers: ["beta"]))
        XCTAssertGreaterThan(Version(2, 2, 3, prereleaseIdentifiers: [""]), Version(1, 2, 3, buildMetadataIdentifiers: [""]))
        XCTAssertGreaterThan(Version(1, 3, 3, prereleaseIdentifiers: ["alpha"]), Version(1, 2, 3, buildMetadataIdentifiers: ["beta"]))
        XCTAssertGreaterThan(Version(1, 2, 4, prereleaseIdentifiers: ["223"]), Version(1, 2, 3, buildMetadataIdentifiers: ["123alpha"]))
        
        XCTAssertFalse(Version(2, 2, 3, prereleaseIdentifiers: [""]) < Version(1, 2, 3, buildMetadataIdentifiers: [""]))
        XCTAssertFalse(Version(1, 3, 3, prereleaseIdentifiers: ["alpha"]) < Version(1, 2, 3, buildMetadataIdentifiers: ["beta"]))
        XCTAssertFalse(Version(1, 2, 4, prereleaseIdentifiers: ["223"]) < Version(1, 2, 3, buildMetadataIdentifiers: ["123alpha"]))
        
        // MARK: version core + build metadata vs. version core + build metadata
        
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: [""]), Version(1, 2, 3, buildMetadataIdentifiers: [""]))
        
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: ["beta"]), Version(1, 2, 3, buildMetadataIdentifiers: ["beta"]))
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: ["alpha"]), Version(1, 2, 3, buildMetadataIdentifiers: ["beta"]))
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: ["alpha1"]), Version(1, 2, 3, buildMetadataIdentifiers: ["alpha2"]))
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: ["alpha"]), Version(1, 2, 3, buildMetadataIdentifiers: ["alpha-"]))
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: ["beta", "alpha"]), Version(1, 2, 3, buildMetadataIdentifiers: ["beta", "beta"]))
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: ["alpha", "beta"]), Version(1, 2, 3, buildMetadataIdentifiers: ["beta", "alpha"]))
        
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: ["1"]), Version(1, 2, 3, buildMetadataIdentifiers: ["1"]))
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: ["1"]), Version(1, 2, 3, buildMetadataIdentifiers: ["2"]))
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: ["1", "1"]), Version(1, 2, 3, buildMetadataIdentifiers: ["1", "2"]))
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: ["1", "2"]), Version(1, 2, 3, buildMetadataIdentifiers: ["2", "1"]))
        
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: ["123"]), Version(1, 2, 3, buildMetadataIdentifiers: ["123alpha"]))
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: ["223"]), Version(1, 2, 3, buildMetadataIdentifiers: ["123alpha"]))
        
        // MARK: version core vs. version core + pre-release + build metadata
        
        XCTAssertGreaterThan(Version(1, 2, 3), Version(1, 2, 3, prereleaseIdentifiers: [""], buildMetadataIdentifiers: [""]))
        XCTAssertGreaterThan(Version(1, 2, 3), Version(1, 2, 3, prereleaseIdentifiers: [""], buildMetadataIdentifiers: ["123alpha"]))
        XCTAssertGreaterThan(Version(1, 2, 3), Version(1, 2, 3, prereleaseIdentifiers: ["alpha"], buildMetadataIdentifiers: ["alpha"]))
        XCTAssertGreaterThan(Version(1, 2, 3), Version(1, 2, 3, prereleaseIdentifiers: ["beta"], buildMetadataIdentifiers: ["123"]))
        XCTAssertFalse(Version(1, 2, 3) < Version(1, 2, 3, prereleaseIdentifiers: [""], buildMetadataIdentifiers: [""]))
        XCTAssertFalse(Version(1, 2, 3) < Version(1, 2, 3, prereleaseIdentifiers: [""], buildMetadataIdentifiers: ["123alpha"]))
        XCTAssertFalse(Version(1, 2, 3) < Version(1, 2, 3, prereleaseIdentifiers: ["alpha"], buildMetadataIdentifiers: ["alpha"]))
        XCTAssertFalse(Version(1, 2, 3) < Version(1, 2, 3, prereleaseIdentifiers: ["beta"], buildMetadataIdentifiers: ["123"]))
        XCTAssertLessThan(Version(1, 2, 2), Version(1, 2, 3, prereleaseIdentifiers: ["beta"], buildMetadataIdentifiers: ["alpha", "beta"]))
        XCTAssertLessThan(Version(1, 2, 2), Version(1, 2, 3, prereleaseIdentifiers: ["beta"], buildMetadataIdentifiers: ["alpha-"]))
        
        // MARK: version core + pre-release vs. version core + pre-release + build metadata
        
        XCTAssertEqual(
            Version(1, 2, 3, prereleaseIdentifiers: [""]),
            Version(1, 2, 3, prereleaseIdentifiers: [""], buildMetadataIdentifiers: [""])
        )
        
        XCTAssertEqual(
            Version(1, 2, 3, prereleaseIdentifiers: ["beta"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["beta"], buildMetadataIdentifiers: [""])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["alpha"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["beta"], buildMetadataIdentifiers: ["123alpha"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["alpha1"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["alpha2"], buildMetadataIdentifiers: ["alpha"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["alpha"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["alpha-"], buildMetadataIdentifiers: ["alpha", "beta"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["beta", "alpha"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["beta", "beta"], buildMetadataIdentifiers: ["123"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["alpha", "beta"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["beta", "alpha"], buildMetadataIdentifiers: ["alpha-"])
        )
        
        XCTAssertEqual(
            Version(1, 2, 3, prereleaseIdentifiers: ["1"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["1"], buildMetadataIdentifiers: [""])
        )
        XCTAssertEqual(
            Version(1, 2, 3, prereleaseIdentifiers: ["1"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["001"], buildMetadataIdentifiers: [""])
        )
        XCTAssertEqual(
            Version(1, 2, 3, prereleaseIdentifiers: ["0001"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["1"], buildMetadataIdentifiers: [""])
        )
        XCTAssertEqual(
            Version(1, 2, 3, prereleaseIdentifiers: ["00001"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["000001"], buildMetadataIdentifiers: [""])
        )
        
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["1"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["2"], buildMetadataIdentifiers: ["123alpha"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["1", "1"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["1", "2"], buildMetadataIdentifiers: ["123"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["1", "1"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["00000001", "2"], buildMetadataIdentifiers: ["123"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["000000001", "1"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["1", "2"], buildMetadataIdentifiers: ["123"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["01", "1"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["0000000001", "2"], buildMetadataIdentifiers: ["123"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["1", "2"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["2", "1"], buildMetadataIdentifiers: ["alpha", "beta"])
        )
        
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["123"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["123alpha"], buildMetadataIdentifiers: ["-alpha"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["223"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["123alpha"], buildMetadataIdentifiers: ["123"])
        )
        
        XCTAssertGreaterThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["xyz"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["123"], buildMetadataIdentifiers: ["hgjkalmfvdfua"])
        )
        XCTAssertGreaterThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["111uvw"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["999999"], buildMetadataIdentifiers: ["iouiytrdfghj", "3rfey89rr"])
        )
        
        XCTAssertFalse(
            Version(1, 2, 3, prereleaseIdentifiers: ["xyz"]) <
            Version(1, 2, 3, prereleaseIdentifiers: ["123"], buildMetadataIdentifiers: ["hgjkalmfvdfua"])
        )
        XCTAssertFalse(
            Version(1, 2, 3, prereleaseIdentifiers: ["111uvw"]) <
            Version(1, 2, 3, prereleaseIdentifiers: ["999999"], buildMetadataIdentifiers: ["dfghjkiohgf", "3rfey89rr"])
        )
        
        // MARK: version core + pre-release + build metadata vs. version core + pre-release + build metadata
        
        XCTAssertEqual(
            Version(1, 2, 3, prereleaseIdentifiers: [""], buildMetadataIdentifiers: [""]),
            Version(1, 2, 3, prereleaseIdentifiers: [""], buildMetadataIdentifiers: [""])
        )
        
        XCTAssertEqual(
            Version(1, 2, 3, prereleaseIdentifiers: ["beta"], buildMetadataIdentifiers: ["123"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["beta"], buildMetadataIdentifiers: [""])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["alpha"], buildMetadataIdentifiers: ["-alpha"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["beta"], buildMetadataIdentifiers: ["123alpha"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["alpha1"], buildMetadataIdentifiers: ["alpha", "beta"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["alpha2"], buildMetadataIdentifiers: ["alpha"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["alpha"], buildMetadataIdentifiers: ["123"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["alpha-"], buildMetadataIdentifiers: ["alpha", "beta"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["beta", "alpha"], buildMetadataIdentifiers: ["123alpha"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["beta", "beta"], buildMetadataIdentifiers: ["123"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["alpha", "beta"], buildMetadataIdentifiers: [""]),
            Version(1, 2, 3, prereleaseIdentifiers: ["beta", "alpha"], buildMetadataIdentifiers: ["alpha-"])
        )
        
        XCTAssertEqual(
            Version(1, 2, 3, prereleaseIdentifiers: ["1"], buildMetadataIdentifiers: ["alpha-"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["1"], buildMetadataIdentifiers: [""])
        )
        XCTAssertEqual(
            Version(1, 2, 3, prereleaseIdentifiers: ["01"], buildMetadataIdentifiers: ["alpha-"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["1"], buildMetadataIdentifiers: [""])
        )
        XCTAssertEqual(
            Version(1, 2, 3, prereleaseIdentifiers: ["1"], buildMetadataIdentifiers: ["alpha-"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["01"], buildMetadataIdentifiers: [""])
        )
        XCTAssertEqual(
            Version(1, 2, 3, prereleaseIdentifiers: ["001"], buildMetadataIdentifiers: ["alpha-"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["0001"], buildMetadataIdentifiers: [""])
        )
        
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["1"], buildMetadataIdentifiers: ["123"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["2"], buildMetadataIdentifiers: ["123alpha"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["1", "1"], buildMetadataIdentifiers: ["alpha", "beta"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["1", "2"], buildMetadataIdentifiers: ["123"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["00001", "1"], buildMetadataIdentifiers: ["alpha", "beta"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["1", "2"], buildMetadataIdentifiers: ["123"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["1", "1"], buildMetadataIdentifiers: ["alpha", "beta"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["000001", "2"], buildMetadataIdentifiers: ["123"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["0000001", "1"], buildMetadataIdentifiers: ["alpha", "beta"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["001", "2"], buildMetadataIdentifiers: ["123"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["1", "2"], buildMetadataIdentifiers: ["alpha"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["2", "1"], buildMetadataIdentifiers: ["alpha", "beta"])
        )
        
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["123"], buildMetadataIdentifiers: ["123alpha"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["123alpha"], buildMetadataIdentifiers: ["-alpha"])
        )
        XCTAssertLessThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["223"], buildMetadataIdentifiers: ["123alpha"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["123alpha"], buildMetadataIdentifiers: ["123"])
        )
        
        XCTAssertGreaterThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["xyz"], buildMetadataIdentifiers: ["-09tyfvgubh"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["123"], buildMetadataIdentifiers: ["765resdfu89"])
        )
        XCTAssertGreaterThan(
            Version(1, 2, 3, prereleaseIdentifiers: ["111uvw"], buildMetadataIdentifiers: ["-----MNgyftcyvu---vcxzAQwsd-------"]),
            Version(1, 2, 3, prereleaseIdentifiers: ["999999"], buildMetadataIdentifiers: ["bvgh--9-ygtfyvg", "hgvh-0vb-"])
        )
        
        XCTAssertFalse(
            Version(1, 2, 3, prereleaseIdentifiers: ["xyz"], buildMetadataIdentifiers: ["fhieaw98y76ftrcwrjk"]) <
            Version(1, 2, 3, prereleaseIdentifiers: ["123"], buildMetadataIdentifiers: ["-jhgbivuy-gh"])
        )
        XCTAssertFalse(
            Version(1, 2, 3, prereleaseIdentifiers: ["111uvw"], buildMetadataIdentifiers: ["bvcx67t"]) <
            Version(1, 2, 3, prereleaseIdentifiers: ["999999"], buildMetadataIdentifiers: ["nuybvfcrd6ty", "3rfey89rr"])
        )
        
    }
    
    func testCustomConversionFromVersionToString() {
        
        // MARK: Version.description
        
        XCTAssertEqual(Version(0, 0, 0).description, "0.0.0" as String)
        XCTAssertEqual(Version(1, 2, 3).description, "1.2.3" as String)
        XCTAssertEqual(Version(1, 2, 3, prereleaseIdentifiers: [""]).description, "1.2.3-" as String)
        XCTAssertEqual(Version(1, 2, 3, prereleaseIdentifiers: ["", ""]).description, "1.2.3-." as String)
        XCTAssertEqual(Version(1, 2, 3, prereleaseIdentifiers: ["beta1"]).description, "1.2.3-beta1" as String)
        XCTAssertEqual(Version(1, 2, 3, prereleaseIdentifiers: ["beta", "1"]).description, "1.2.3-beta.1" as String)
        XCTAssertEqual(Version(1, 2, 3, prereleaseIdentifiers: ["beta", "", "1"]).description, "1.2.3-beta..1" as String)
        XCTAssertEqual(Version(1, 2, 3, prereleaseIdentifiers: ["be-ta", "", "1"]).description, "1.2.3-be-ta..1" as String)
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: [""]).description, "1.2.3+" as String)
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: ["", ""]).description, "1.2.3+." as String)
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: ["beta1"]).description, "1.2.3+beta1" as String)
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: ["beta", "1"]).description, "1.2.3+beta.1" as String)
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: ["beta", "", "1"]).description, "1.2.3+beta..1" as String)
        XCTAssertEqual(Version(1, 2, 3, buildMetadataIdentifiers: ["be-ta", "", "1"]).description, "1.2.3+be-ta..1" as String)
        XCTAssertEqual(Version(1, 2, 3, prereleaseIdentifiers: [""], buildMetadataIdentifiers: [""]).description, "1.2.3-+" as String)
        XCTAssertEqual(Version(1, 2, 3, prereleaseIdentifiers: ["", ""], buildMetadataIdentifiers: ["", "-", ""]).description, "1.2.3-.+.-." as String)
        XCTAssertEqual(Version(1, 2, 3, prereleaseIdentifiers: ["beta1"], buildMetadataIdentifiers: ["alpha1"]).description, "1.2.3-beta1+alpha1" as String)
        XCTAssertEqual(Version(1, 2, 3, prereleaseIdentifiers: ["beta", "1"], buildMetadataIdentifiers: ["alpha", "1"]).description, "1.2.3-beta.1+alpha.1" as String)
        XCTAssertEqual(Version(1, 2, 3, prereleaseIdentifiers: ["beta", "", "1"], buildMetadataIdentifiers: ["alpha", "", "1"]).description, "1.2.3-beta..1+alpha..1" as String)
        XCTAssertEqual(Version(1, 2, 3, prereleaseIdentifiers: ["be-ta", "", "1"], buildMetadataIdentifiers: ["al-pha", "", "1"]).description, "1.2.3-be-ta..1+al-pha..1" as String)
        
        // MARK: String interpolation
        
        XCTAssertEqual("\(Version(0, 0, 0))", "0.0.0" as String)
        XCTAssertEqual("\(Version(1, 2, 3))", "1.2.3" as String)
        XCTAssertEqual("\(Version(1, 2, 3, prereleaseIdentifiers: [""]))", "1.2.3-" as String)
        XCTAssertEqual("\(Version(1, 2, 3, prereleaseIdentifiers: ["", ""]))", "1.2.3-." as String)
        XCTAssertEqual("\(Version(1, 2, 3, prereleaseIdentifiers: ["beta1"]))", "1.2.3-beta1" as String)
        XCTAssertEqual("\(Version(1, 2, 3, prereleaseIdentifiers: ["beta", "1"]))", "1.2.3-beta.1" as String)
        XCTAssertEqual("\(Version(1, 2, 3, prereleaseIdentifiers: ["beta", "", "1"]))", "1.2.3-beta..1" as String)
        XCTAssertEqual("\(Version(1, 2, 3, prereleaseIdentifiers: ["be-ta", "", "1"]))", "1.2.3-be-ta..1" as String)
        XCTAssertEqual("\(Version(1, 2, 3, buildMetadataIdentifiers: [""]))", "1.2.3+" as String)
        XCTAssertEqual("\(Version(1, 2, 3, buildMetadataIdentifiers: ["", ""]))", "1.2.3+." as String)
        XCTAssertEqual("\(Version(1, 2, 3, buildMetadataIdentifiers: ["beta1"]))", "1.2.3+beta1" as String)
        XCTAssertEqual("\(Version(1, 2, 3, buildMetadataIdentifiers: ["beta", "1"]))", "1.2.3+beta.1" as String)
        XCTAssertEqual("\(Version(1, 2, 3, buildMetadataIdentifiers: ["beta", "", "1"]))", "1.2.3+beta..1" as String)
        XCTAssertEqual("\(Version(1, 2, 3, buildMetadataIdentifiers: ["be-ta", "", "1"]))", "1.2.3+be-ta..1" as String)
        XCTAssertEqual("\(Version(1, 2, 3, prereleaseIdentifiers: [""], buildMetadataIdentifiers: [""]))", "1.2.3-+" as String)
        XCTAssertEqual("\(Version(1, 2, 3, prereleaseIdentifiers: ["", ""], buildMetadataIdentifiers: ["", "-", ""]))", "1.2.3-.+.-." as String)
        XCTAssertEqual("\(Version(1, 2, 3, prereleaseIdentifiers: ["beta1"], buildMetadataIdentifiers: ["alpha1"]))", "1.2.3-beta1+alpha1" as String)
        XCTAssertEqual("\(Version(1, 2, 3, prereleaseIdentifiers: ["beta", "1"], buildMetadataIdentifiers: ["alpha", "1"]))", "1.2.3-beta.1+alpha.1" as String)
        XCTAssertEqual("\(Version(1, 2, 3, prereleaseIdentifiers: ["beta", "", "1"], buildMetadataIdentifiers: ["alpha", "", "1"]))", "1.2.3-beta..1+alpha..1" as String)
        XCTAssertEqual("\(Version(1, 2, 3, prereleaseIdentifiers: ["be-ta", "", "1"], buildMetadataIdentifiers: ["al-pha", "", "1"]))", "1.2.3-be-ta..1+al-pha..1" as String)
        
    }
    
    func testLosslessConversionFromStringToVersion() {
        
        // MARK: Well-formed version core
        
        XCTAssertNotNil(Version("0.0.0" as String))
        XCTAssertEqual(Version("0.0.0" as String), Version(0, 0, 0))
        
        XCTAssertNotNil(Version("1.1.2" as String))
        XCTAssertEqual(Version("1.1.2" as String), Version(1, 1, 2))
        
        // MARK: Malformed version core
        
        XCTAssertNil(Version("3" as String))
        XCTAssertNil(Version("3 5" as String))
        XCTAssertNil(Version("5.8" as String))
        XCTAssertNil(Version("-5.8.13" as String))
        XCTAssertNil(Version("8.-13.21" as String))
        XCTAssertNil(Version("13.21.-34" as String))
        XCTAssertNil(Version("-0.0.0" as String))
        XCTAssertNil(Version("0.-0.0" as String))
        XCTAssertNil(Version("0.0.-0" as String))
        XCTAssertNil(Version("21.34.55.89" as String))
        XCTAssertNil(Version("6 x 9 = 42" as String))
        XCTAssertNil(Version("forty two" as String))
        
        // MARK: Well-formed version core, well-formed pre-release identifiers
        
        XCTAssertNotNil(Version("0.0.0-pre-alpha" as String))
        XCTAssertEqual(Version("0.0.0-pre-alpha" as String), Version(0, 0, 0, prereleaseIdentifiers: ["pre-alpha"]))
        
        XCTAssertNotNil(Version("55.89.144-beta.1" as String))
        XCTAssertEqual(Version("55.89.144-beta.1" as String), Version(55, 89, 144, prereleaseIdentifiers: ["beta", "1"]))
        
        XCTAssertNotNil(Version("89.144.233-a.whole..lot.of.pre-release.identifiers" as String))
        XCTAssertEqual(Version("89.144.233-a.whole..lot.of.pre-release.identifiers" as String), Version(89, 144, 233, prereleaseIdentifiers: ["a", "whole", "", "lot", "of", "pre-release", "identifiers"]))
        
        XCTAssertNotNil(Version("144.233.377-" as String))
        XCTAssertEqual(Version("144.233.377-" as String), Version(144, 233, 377, prereleaseIdentifiers: [""]))
        
        // MARK: Well-formed version core, malformed pre-release identifiers
        
        XCTAssertNil(Version("233.377.610-hello world" as String))
        
        // MARK: Malformed version core, well-formed pre-release identifiers
        
        XCTAssertNil(Version("987-Hello.world--------" as String))
        XCTAssertNil(Version("987.1597-half-life.3" as String))
        XCTAssertNil(Version("1597.2584.4181.6765-a.whole.lot.of.pre-release.identifiers" as String))
        XCTAssertNil(Version("6 x 9 = 42-" as String))
        XCTAssertNil(Version("forty-two" as String))
        
        // MARK: Well-formed version core, well-formed build metadata identifiers
        
        XCTAssertNotNil(Version("0.0.0+some-metadata" as String))
        XCTAssertEqual(Version("0.0.0+some-metadata" as String), Version(0, 0, 0, buildMetadataIdentifiers: ["some-metadata"]))
        
        XCTAssertNotNil(Version("4181.6765.10946+more.meta..more.data" as String))
        XCTAssertEqual(Version("4181.6765.10946+more.meta..more.data" as String), Version(4181, 6765, 10946, buildMetadataIdentifiers: ["more", "meta", "", "more", "data"]))
        
        XCTAssertNotNil(Version("6765.10946.17711+-a-very--long---build-----metadata--------identifier-------------with---------------------many----------------------------------hyphens-------------------------------------------------------" as String))
        XCTAssertEqual(Version("6765.10946.17711+-a-very--long---build-----metadata--------identifier-------------with---------------------many----------------------------------hyphens-------------------------------------------------------" as String), Version(6765, 10946, 17711, buildMetadataIdentifiers: ["-a-very--long---build-----metadata--------identifier-------------with---------------------many----------------------------------hyphens-------------------------------------------------------"]))
        
        XCTAssertNotNil(Version("10946.17711.28657+" as String))
        XCTAssertEqual(Version("10946.17711.28657+" as String), Version(10946, 17711, 28657, buildMetadataIdentifiers: [""]))
        
        // MARK: Well-formed version core, malformed build metadata identifiers
        
        XCTAssertNil(Version("17711.28657.46368+hello world" as String))
        XCTAssertNil(Version("28657.46368.75025+hello+world" as String))
        
        // MARK: Malformed version core, well-formed build metadata identifiers
        
        XCTAssertNil(Version("121393+Hello.world--------" as String))
        XCTAssertNil(Version("121393.196418+half-life.3" as String))
        XCTAssertNil(Version("196418.317811.514229.832040+a.whole.lot.of.build.metadata.identifiers" as String))
        XCTAssertNil(Version("196418.317811.514229.832040+a.whole.lot.of.build.metadata.identifiers" as String))
        XCTAssertNil(Version("6 x 9 = 42+" as String))
        XCTAssertNil(Version("forty two+a-very-long-build-metadata-identifier-with-many-hyphens" as String))
        
        // MARK: Well-formed version core, well-formed pre-release identifiers, well-formed build metadata identifiers
        
        XCTAssertNotNil(Version("0.0.0-beta.-42+42-42.42" as String))
        XCTAssertEqual(Version("0.0.0-beta.-42+42-42.42" as String), Version(0, 0, 0, prereleaseIdentifiers: ["beta", "-42"], buildMetadataIdentifiers: ["42-42", "42"]))
        
        // MARK: Well-formed version core, well-formed pre-release identifiers, malformed build metadata identifiers
        
        XCTAssertNil(Version("514229.832040.1346269-beta1+  " as String))
        
        // MARK: Well-formed version core, malformed pre-release identifiers, well-formed build metadata identifiers
        
        XCTAssertNil(Version("832040.1346269.2178309-beta 1+-" as String))
        
        // MARK: Well-formed version core, malformed pre-release identifiers, malformed build metadata identifiers
        
        XCTAssertNil(Version("1346269.2178309.3524578-beta 1++" as String))
        
        // MARK: malformed version core, well-formed pre-release identifiers, well-formed build metadata identifiers
        
        XCTAssertNil(Version(" 832040.1346269.3524578-beta1+abc" as String))
        
        // MARK: malformed version core, well-formed pre-release identifiers, malformed build metadata identifiers
        
        XCTAssertNil(Version("1346269.3524578.5702887-beta1+😀" as String))
        
        // MARK: malformed version core, malformed pre-release identifiers, well-formed build metadata identifiers
        
        XCTAssertNil(Version("3524578.5702887.9227465-beta!@#$%^&*1+asdfghjkl123456789" as String))
        
        // MARK: malformed version core, malformed pre-release identifiers, malformed build metadata identifiers
        
        XCTAssertNil(Version("5702887.9227465-bètá1+±" as String))
        
    }
}
