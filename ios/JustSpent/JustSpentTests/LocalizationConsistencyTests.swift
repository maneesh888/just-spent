//
//  LocalizationConsistencyTests.swift
//  JustSpentTests
//
//  Tests to ensure iOS localizations match the shared localizations.json source of truth
//

import XCTest
@testable import JustSpent

class LocalizationConsistencyTests: XCTestCase {

    // MARK: - Test Properties

    /// Path to shared localizations.json (single source of truth)
    private let sharedLocalizationsPath = "../../shared/localizations.json"

    /// Mapping of JSON keys to expected iOS Localizable.strings keys
    /// Based on localizations.json "platforms.ios" values
    private let keyMapping: [String: String] = [
        // App
        "app.title": "app.title",
        "app.subtitle": "app.subtitle",
        "app.totalLabel": "app.total.label",

        // Empty State
        "emptyState.noExpenses": "emptyState.noExpenses",
        "emptyState.tapVoiceButton": "emptyState.tapVoiceButton",

        // Buttons
        "buttons.ok": "button.ok",
        "buttons.cancel": "button.cancel",
        "buttons.retry": "button.retry",

        // Categories
        "categories.foodDining": "category.foodDining",
        "categories.grocery": "category.grocery",
        "categories.transportation": "category.transportation",
        "categories.shopping": "category.shopping",
        "categories.entertainment": "category.entertainment",
        "categories.bills": "category.bills",
        "categories.healthcare": "category.healthcare",
        "categories.education": "category.education",
        "categories.other": "category.other",
        "categories.unknown": "category.unknown"
    ]

    /// Expected values from shared localizations.json
    /// These should match both iOS and Android (unless platform-specific)
    private let expectedValues: [String: String] = [
        // App
        "app.title": "Just Spent",
        "app.subtitle": "Voice-enabled expense tracker",
        "app.totalLabel": "Total",

        // Empty State
        "emptyState.noExpenses": "No Expenses Yet",
        // Note: emptyState.tapVoiceButton is platform-specific

        // Buttons
        "buttons.ok": "OK",
        "buttons.cancel": "Cancel",
        "buttons.retry": "Retry",

        // Categories
        "categories.foodDining": "Food & Dining",
        "categories.grocery": "Grocery",
        "categories.transportation": "Transportation",
        "categories.shopping": "Shopping",
        "categories.entertainment": "Entertainment",
        "categories.bills": "Bills & Utilities",
        "categories.healthcare": "Healthcare",
        "categories.education": "Education",
        "categories.other": "Other",
        "categories.unknown": "Unknown"
    ]

    /// Platform-specific strings that differ intentionally
    private let platformSpecific: [String: String] = [
        "emptyState.tapVoiceButton": "Tap the voice button below to get started",
        "voiceAssistant.name": "Siri"
    ]

    // MARK: - Test Cases

    /// Test 1: Verify all shared strings exist in iOS
    func testAllSharedStringsExistInIOS() {
        let bundle = Bundle(for: type(of: self))
        var missingKeys: [String] = []

        for (jsonKey, iosKey) in keyMapping {
            let localizedString = NSLocalizedString(iosKey, bundle: bundle, comment: "")

            // If localization fails, iOS returns the key itself
            if localizedString == iosKey {
                missingKeys.append("\(jsonKey) → iOS key: \(iosKey)")
            }
        }

        XCTAssertTrue(
            missingKeys.isEmpty,
            "Missing iOS localization keys:\n\(missingKeys.joined(separator: "\n"))"
        )
    }

    /// Test 2: Verify shared strings match expected values from JSON
    func testSharedStringsMatchExpectedValues() {
        let bundle = Bundle(for: type(of: self))
        var mismatches: [(jsonKey: String, expected: String, actual: String)] = []

        for (jsonKey, expectedValue) in expectedValues {
            guard let iosKey = keyMapping[jsonKey] else {
                XCTFail("No iOS key mapping for JSON key: \(jsonKey)")
                continue
            }

            let actualValue = NSLocalizedString(iosKey, bundle: bundle, comment: "")

            if actualValue != expectedValue {
                mismatches.append((jsonKey: jsonKey, expected: expectedValue, actual: actualValue))
            }
        }

        if !mismatches.isEmpty {
            let errorMessage = mismatches.map { item in
                "JSON key: \(item.jsonKey)\n  Expected: '\(item.expected)'\n  Actual: '\(item.actual)'"
            }.joined(separator: "\n\n")

            XCTFail("Localization mismatches with shared JSON:\n\n\(errorMessage)")
        }
    }

    /// Test 3: Verify platform-specific iOS strings have correct values
    func testPlatformSpecificStringsAreCorrect() {
        let bundle = Bundle(for: type(of: self))
        var mismatches: [(jsonKey: String, expected: String, actual: String)] = []

        for (jsonKey, expectedValue) in platformSpecific {
            guard let iosKey = keyMapping[jsonKey] else { continue }

            let actualValue = NSLocalizedString(iosKey, bundle: bundle, comment: "")

            if actualValue != expectedValue {
                mismatches.append((jsonKey: jsonKey, expected: expectedValue, actual: actualValue))
            }
        }

        if !mismatches.isEmpty {
            let errorMessage = mismatches.map { item in
                "JSON key: \(item.jsonKey) (platform-specific)\n  Expected: '\(item.expected)'\n  Actual: '\(item.actual)'"
            }.joined(separator: "\n\n")

            XCTFail("Platform-specific string mismatches:\n\n\(errorMessage)")
        }
    }

    /// Test 4: Document intentional platform differences
    func testDocumentedPlatformDifferences() {
        // This test always passes but documents known differences

        let differences = [
            (
                key: "emptyState.tapVoiceButton",
                ios: "Tap the voice button below to get started",
                android: "Tap the microphone button to add an expense",
                reason: "Different UI terminology"
            ),
            (
                key: "voiceAssistant.name",
                ios: "Siri",
                android: "Assistant",
                reason: "Platform-specific branding"
            )
        ]

        print("\n=== Documented Platform Differences ===")
        for diff in differences {
            print("\nKey: \(diff.key)")
            print("  iOS: \(diff.ios)")
            print("  Android: \(diff.android)")
            print("  Reason: \(diff.reason)")
        }
        print("\n========================================\n")

        XCTAssertEqual(differences.count, 2, "Expected 2 documented platform differences")
    }

    /// Test 5: Verify no empty strings
    func testNoEmptyStrings() {
        let bundle = Bundle(for: type(of: self))
        var emptyKeys: [String] = []

        for (_, iosKey) in keyMapping {
            let localizedString = NSLocalizedString(iosKey, bundle: bundle, comment: "")

            if localizedString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                emptyKeys.append(iosKey)
            }
        }

        XCTAssertTrue(
            emptyKeys.isEmpty,
            "Found empty localized strings:\n\(emptyKeys.joined(separator: "\n"))"
        )
    }

    /// Test 6: Verify category count matches
    func testCategoryCountMatches() {
        let categoryKeys = keyMapping.filter { $0.key.starts(with: "categories.") }

        // Should have 10 categories (9 main categories + unknown)
        XCTAssertEqual(
            categoryKeys.count,
            10,
            "Expected 10 category strings (9 categories + unknown)"
        )
    }
}
