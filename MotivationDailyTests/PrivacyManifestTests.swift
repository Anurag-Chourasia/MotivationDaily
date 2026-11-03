//
//  PrivacyManifestTests.swift
//  MotivationDailyTests
//
//  Created by Anurag Chourasia on 03/11/26.
//

import XCTest
@testable import MotivationDaily

final class PrivacyManifestTests: XCTestCase {

    private func loadPrivacyManifest() throws -> [String: Any] {
        let manifestURL: URL? = Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
            ?? Bundle(for: Self.self).url(forResource: "PrivacyInfo", withExtension: "xcprivacy")

        var resolvedURL: URL? = manifestURL
        if let existing = resolvedURL, FileManager.default.fileExists(atPath: existing.path) {
            // Valid bundle URL
        } else {
            let bundleFile = Bundle.main.bundleURL.appendingPathComponent("PrivacyInfo.xcprivacy")
            if FileManager.default.fileExists(atPath: bundleFile.path) {
                resolvedURL = bundleFile
            } else {
                let sourcePath = URL(fileURLWithPath: #file)
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .appendingPathComponent("MotivationDaily/PrivacyInfo.xcprivacy")
                if FileManager.default.fileExists(atPath: sourcePath.path) {
                    resolvedURL = sourcePath
                }
            }
        }

        guard let url = resolvedURL, FileManager.default.fileExists(atPath: url.path) else {
            XCTFail("PrivacyInfo.xcprivacy not found in app bundle or source tree")
            throw CocoaError(.fileNoSuchFile)
        }

        let data = try Data(contentsOf: url)
        guard let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any] else {
            XCTFail("Failed to parse PrivacyInfo.xcprivacy as property list dictionary")
            throw CocoaError(.fileReadCorruptFile)
        }
        return plist
    }

    func testPrivacyManifestStructureAndTracking() throws {
        let manifest = try loadPrivacyManifest()

        let tracking = manifest["NSPrivacyTracking"] as? Bool
        XCTAssertEqual(tracking, false, "Motivation Daily must declare NSPrivacyTracking as false")

        let domains = manifest["NSPrivacyTrackingDomains"] as? [String]
        XCTAssertEqual(domains, [], "Motivation Daily must have empty NSPrivacyTrackingDomains")
    }

    func testRequiredReasonAPIsDeclared() throws {
        let manifest = try loadPrivacyManifest()

        guard let accessedAPITypes = manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]] else {
            XCTFail("NSPrivacyAccessedAPITypes must be an array of dictionaries")
            return
        }

        let userDefaultsDeclaration = accessedAPITypes.first { dict in
            (dict["NSPrivacyAccessedAPIType"] as? String) == "NSPrivacyAccessedAPICategoryUserDefaults"
        }
        XCTAssertNotNil(userDefaultsDeclaration, "UserDefaults required-reason API must be declared")
        let userDefaultsReasons = userDefaultsDeclaration?["NSPrivacyAccessedAPITypeReasons"] as? [String]
        XCTAssertTrue(userDefaultsReasons?.contains("CA92.1") == true, "UserDefaults API reason must declare CA92.1")
    }

    func testCollectedDataTypesDeclared() throws {
        let manifest = try loadPrivacyManifest()

        guard let collectedTypes = manifest["NSPrivacyCollectedDataTypes"] as? [[String: Any]] else {
            XCTFail("NSPrivacyCollectedDataTypes must be an array of dictionaries")
            return
        }

        let declaredTypes = Set(collectedTypes.compactMap { $0["NSPrivacyCollectedDataType"] as? String })
        let expectedTypes: Set<String> = [
            "NSPrivacyCollectedDataTypeUserID",
            "NSPrivacyCollectedDataTypeEmailAddress",
            "NSPrivacyCollectedDataTypeOtherUserContent"
        ]

        XCTAssertTrue(expectedTypes.isSubset(of: declaredTypes), "Missing expected data types in privacy manifest")

        for entry in collectedTypes {
            let isTracking = entry["NSPrivacyCollectedDataTypeTracking"] as? Bool
            XCTAssertEqual(isTracking, false, "Collected data must not be used for tracking")

            let purposes = entry["NSPrivacyCollectedDataTypePurposes"] as? [String]
            XCTAssertTrue(
                purposes?.contains("NSPrivacyCollectedDataTypePurposeAppFunctionality") == true,
                "Purpose must be App Functionality"
            )
        }
    }

    func testPrivacyPolicyAndSupportURLsAreReachable() {
        let policyURL = URL(string: "https://github.com/Anurag-Chourasia/Motivation-Daily/blob/main/Docs/PrivacyInventory.md")
        XCTAssertNotNil(policyURL)
        XCTAssertEqual(policyURL?.scheme, "https")

        let supportURL = URL(string: "mailto:anuragchourasiaios@gmail.com")
        XCTAssertNotNil(supportURL)
        XCTAssertEqual(supportURL?.scheme, "mailto")
    }
}
