//
//  LocalizationConsistencyTests.swift
//  JustSpentTests
//
//  Tests to ensure iOS loads localizations correctly from shared JSON
//

import XCTest
@testable import JustSpent

class LocalizationConsistencyTests: XCTestCase {

    var localizationManager: LocalizationManager!

    override func setUp() {
        super.setUp()
        localizationManager = LocalizationManager.shared
    }

    // MARK: - JSON Loading Tests

    /// Test 1: Verify JSON file loads successfully
    func testJSONLoadsSuccessfully() {
        // Should not crash and should return valid strings
        XCTAssertFalse(localizationManager.appTitle.isEmpty)
        XCTAssertFalse(localizationManager.appTitle.hasPrefix("["))
    }

    /// Test 2: Verify app strings match JSON
    func testAppStringsMatchJSON() {
        XCTAssertEqual(localizationManager.appTitle, "Just Spent")
        XCTAssertEqual(localizationManager.appSubtitle, "Voice-enabled expense tracker")
        XCTAssertEqual(localizationManager.appTotalLabel, "Total")
    }

    /// Test 3: Verify empty state strings match JSON
    func testEmptyStateStringsMatchJSON() {
        XCTAssertEqual(localizationManager.emptyStateNoExpenses, "No Expenses Yet")
        // Platform-specific iOS value
        XCTAssertEqual(localizationManager.emptyStateTapVoiceButton,
                      "Tap the voice button below to get started")
    }

    /// Test 4: Verify button strings match JSON
    func testButtonStringsMatchJSON() {
        XCTAssertEqual(localizationManager.buttonOK, "OK")
        XCTAssertEqual(localizationManager.buttonCancel, "Cancel")
        XCTAssertEqual(localizationManager.buttonRetry, "Retry")
    }

    /// Test 5: Verify voice strings match JSON
    func testVoiceStringsMatchJSON() {
        // Should use proper ellipsis character
        XCTAssertEqual(localizationManager.voiceListening, "Listening…")
        XCTAssertEqual(localizationManager.voiceProcessing, "Processing…")

        // Verify it's NOT three dots
        XCTAssertNotEqual(localizationManager.voiceListening, "Listening...")
    }

    /// Test 6: Verify all categories match JSON
    func testCategoryStringsMatchJSON() {
        XCTAssertEqual(localizationManager.categoryFoodDining, "Food & Dining")
        XCTAssertEqual(localizationManager.categoryGrocery, "Grocery")
        XCTAssertEqual(localizationManager.categoryTransportation, "Transportation")
        XCTAssertEqual(localizationManager.categoryShopping, "Shopping")
        XCTAssertEqual(localizationManager.categoryEntertainment, "Entertainment")
        XCTAssertEqual(localizationManager.categoryBills, "Bills & Utilities")
        XCTAssertEqual(localizationManager.categoryHealthcare, "Healthcare")
        XCTAssertEqual(localizationManager.categoryEducation, "Education")
        XCTAssertEqual(localizationManager.categoryOther, "Other")
        XCTAssertEqual(localizationManager.categoryUnknown, "Unknown")
    }

    /// Test 7: Verify platform-specific strings use iOS values
    func testPlatformSpecificStringsUseIOSValues() {
        let voiceAssistantName = localizationManager.get("voiceAssistant.name")
        XCTAssertEqual(voiceAssistantName, "Siri")
        XCTAssertNotEqual(voiceAssistantName, "Assistant") // Android value
    }

    /// Test 8: Verify dot-notation path navigation works
    func testDotNotationPathNavigation() {
        XCTAssertEqual(localizationManager.get("app.title"), "Just Spent")
        XCTAssertEqual(localizationManager.get("buttons.ok"), "OK")
        XCTAssertEqual(localizationManager.get("categories.foodDining"), "Food & Dining")
    }

    /// Test 9: Verify missing keys return bracketed key
    func testMissingKeysReturnBracketedKey() {
        let missingKey = localizationManager.get("nonexistent.key")
        XCTAssertEqual(missingKey, "[nonexistent.key]")
    }

    /// Test 10: Verify no empty strings
    func testNoEmptyStrings() {
        let strings = [
            localizationManager.appTitle,
            localizationManager.appSubtitle,
            localizationManager.buttonOK,
            localizationManager.buttonCancel,
            localizationManager.categoryFoodDining,
            localizationManager.categoryGrocery
        ]

        for string in strings {
            XCTAssertFalse(string.isEmpty, "Found empty string")
            XCTAssertFalse(string.hasPrefix("["), "Found unresolved key: \(string)")
        }
    }

    /// Test 11: Cross-platform consistency documentation
    func testDocumentedCrossPlatformDifferences() {
        // Document intentional platform differences
        let differences = [
            ("emptyState.tapVoiceButton",
             "iOS: Tap the voice button below to get started",
             "Android: Tap the microphone button to add an expense",
             "Different UI terminology"),
            ("voiceAssistant.name",
             "iOS: Siri",
             "Android: Assistant",
             "Platform-specific branding")
        ]

        print("\n=== Cross-Platform Differences ===")
        for (key, ios, android, reason) in differences {
            print("\nKey: \(key)")
            print("  \(ios)")
            print("  \(android)")
            print("  Reason: \(reason)")
        }
        print("\n===================================\n")

        // Verify iOS uses correct platform-specific values
        XCTAssertEqual(localizationManager.get("emptyState.tapVoiceButton"),
                      "Tap the voice button below to get started")
        XCTAssertEqual(localizationManager.get("voiceAssistant.name"), "Siri")
    }
}
