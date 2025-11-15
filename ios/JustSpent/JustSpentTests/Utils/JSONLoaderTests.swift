//
//  JSONLoaderTests.swift
//  JustSpentTests
//
//  Created by Claude Code on 2025-11-10.
//  Test-driven development for JSON loading utility
//

import XCTest
@testable import JustSpent

class JSONLoaderTests: XCTestCase {

    // MARK: - Enum-Based Loading Tests

    func testLoadJSON_currencies_succeeds() throws {
        // Given: currencies.json exists in main bundle

        // When: Loading currencies using enum
        let result: JSONLoader.CurrencyData? = JSONLoader.load(.currencies)

        // Then: Should return valid currency data
        XCTAssertNotNil(result, "Should load currencies from main bundle")
        XCTAssertGreaterThan(result?.currencies.count ?? 0, 0, "Should have at least one currency")
        XCTAssertEqual(result?.version, "2.0", "Should match expected version")
    }

    func testLoadJSON_localizations_succeeds() throws {
        // Given: localizations.json exists in main bundle

        // When: Loading localizations using enum
        let result: JSONLoader.LocalizationData? = JSONLoader.load(.localizations)

        // Then: Should return valid localization data
        XCTAssertNotNil(result, "Should load localizations from main bundle")
        XCTAssertEqual(result?.version, "1.0.0", "Should match expected version")
        XCTAssertFalse(result?.lastUpdated.isEmpty ?? true, "Should have lastUpdated")

        // Verify app localization structure
        XCTAssertEqual(result?.app.title, "Just Spent")
        XCTAssertEqual(result?.app.subtitle, "Voice-enabled expense tracker")
        XCTAssertEqual(result?.app.totalLabel, "Total")
    }

    func testLoadJSON_currencies_fromTestBundle_succeeds() throws {
        // Given: Test bundle with currencies.json
        let testBundle = Bundle(for: JSONLoaderTests.self)

        // When: Loading from test bundle
        let result: JSONLoader.CurrencyData? = JSONLoader.load(.currencies, from: testBundle)

        // Then: Should load successfully
        XCTAssertNotNil(result, "Should load from test bundle")
        XCTAssertEqual(result?.currencies.count, 36, "Should have 36 currencies")
    }

    // MARK: - Currency Structure Tests

    func testLoadCurrencies_verifyStructure() throws {
        // When: Loading currencies
        guard let currencyData: JSONLoader.CurrencyData = JSONLoader.load(.currencies) else {
            XCTFail("Failed to load currencies")
            return
        }

        // Then: Should have expected structure
        XCTAssertFalse(currencyData.version.isEmpty, "Version should not be empty")
        XCTAssertFalse(currencyData.lastUpdated.isEmpty, "LastUpdated should not be empty")
        XCTAssertEqual(currencyData.currencies.count, 36, "Should have 36 currencies")

        // Verify first currency (AED) has all required fields
        let aed = currencyData.currencies.first { $0.code == "AED" }
        XCTAssertNotNil(aed, "Should have AED currency")
        XCTAssertEqual(aed?.code, "AED")
        XCTAssertEqual(aed?.symbol, "د.إ")
        XCTAssertEqual(aed?.displayName, "UAE Dirham")
        XCTAssertEqual(aed?.shortName, "Dirham")
        XCTAssertEqual(aed?.localeIdentifier, "ar_AE")
        XCTAssertTrue(aed?.isRTL ?? false, "AED should be RTL")
        XCTAssertGreaterThan(aed?.voiceKeywords.count ?? 0, 0, "Should have voice keywords")
    }

    // MARK: - Localization Structure Tests

    func testLoadLocalizations_verifyStructure() throws {
        // When: Loading localizations
        guard let localizationData: JSONLoader.LocalizationData = JSONLoader.load(.localizations) else {
            XCTFail("Failed to load localizations")
            return
        }

        // Then: Should have expected structure
        XCTAssertEqual(localizationData.version, "1.0.0", "Should have version")
        XCTAssertFalse(localizationData.lastUpdated.isEmpty, "Should have lastUpdated")

        // Verify app section
        XCTAssertEqual(localizationData.app.title, "Just Spent")
        XCTAssertEqual(localizationData.app.subtitle, "Voice-enabled expense tracker")
        XCTAssertEqual(localizationData.app.totalLabel, "Total")

        // Verify emptyState section
        XCTAssertEqual(localizationData.emptyState.noExpenses, "No Expenses Yet")
        XCTAssertFalse(localizationData.emptyState.tapVoiceButton.ios.isEmpty)

        // Verify buttons section
        XCTAssertEqual(localizationData.buttons.ok, "OK")
        XCTAssertEqual(localizationData.buttons.cancel, "Cancel")
        XCTAssertFalse(localizationData.buttons.grantPermissions.isEmpty)
    }

    // MARK: - Convenience Methods Tests

    func testLoadCurrencyCodes_returnsAllCodes() throws {
        // When: Loading just currency codes
        let codes = JSONLoader.loadCurrencyCodes()

        // Then: Should return all 36 currency codes
        XCTAssertEqual(codes.count, 36, "Should have 36 currency codes")
        XCTAssertTrue(codes.contains("AED"), "Should contain AED")
        XCTAssertTrue(codes.contains("USD"), "Should contain USD")
        XCTAssertTrue(codes.contains("EUR"), "Should contain EUR")
        XCTAssertTrue(codes.contains("SAR"), "Should contain SAR")
    }

    func testGetLocalizedString_returnsCorrectValue() throws {
        // When: Getting localized strings
        let appTitle = JSONLoader.getLocalizedString(key: "app.title")
        let okButton = JSONLoader.getLocalizedString(key: "buttons.ok")
        let noExpenses = JSONLoader.getLocalizedString(key: "emptyState.noExpenses")

        // Then: Should return correct values
        XCTAssertEqual(appTitle, "Just Spent")
        XCTAssertEqual(okButton, "OK")
        XCTAssertEqual(noExpenses, "No Expenses Yet")
    }

    func testGetLocalizedString_withMissingKey_returnsKey() throws {
        // When: Getting non-existent key
        let result = JSONLoader.getLocalizedString(key: "nonexistent.key")

        // Then: Should return the key itself as fallback
        XCTAssertEqual(result, "nonexistent.key")
    }

    // MARK: - Error Handling Tests

    func testLoadJSON_fromInvalidBundle_returnsNil() {
        // Given: Invalid bundle without the file
        let invalidBundle = Bundle(for: JSONLoaderTests.self)

        // When: Trying to load non-existent file
        let result: JSONLoader.CurrencyData? = JSONLoader.load(.currencies, from: invalidBundle, filename: "nonexistent")

        // Then: Should return nil gracefully
        XCTAssertNil(result, "Should return nil for missing file")
    }

    func testJSONFileType_filename() {
        // Given: JSON file types
        let currencies = JSONLoader.JSONFileType.currencies
        let localizations = JSONLoader.JSONFileType.localizations

        // When: Getting filenames
        // Then: Should return correct filenames
        XCTAssertEqual(currencies.filename, "currencies")
        XCTAssertEqual(localizations.filename, "localizations")
    }

    func testJSONFileType_returnsCorrectTypes() {
        // Given: JSON file types
        let currenciesType = JSONLoader.JSONFileType.currencies.dataType
        let localizationsType = JSONLoader.JSONFileType.localizations.dataType

        // When/Then: Should have correct associated types
        // (Type checking done at compile time)
        XCTAssertTrue(currenciesType == JSONLoader.CurrencyData.self)
        XCTAssertTrue(localizationsType == JSONLoader.LocalizationData.self)
    }

    // MARK: - Performance Tests

    func testLoadJSON_currencies_performance() {
        // Measure performance of loading currencies
        measure {
            let _: JSONLoader.CurrencyData? = JSONLoader.load(.currencies)
        }
        // Should complete in < 0.01 seconds
    }

    func testLoadJSON_localizations_performance() {
        // Measure performance of loading localizations
        measure {
            let _: JSONLoader.LocalizationData? = JSONLoader.load(.localizations)
        }
        // Should complete in < 0.01 seconds
    }

    func testLoadCurrencyCodes_performance() {
        // Measure performance of loading currency codes
        measure {
            _ = JSONLoader.loadCurrencyCodes()
        }
        // Should complete in < 0.01 seconds
    }

    func testGetLocalizedString_performance() {
        // Measure performance of getting localized string
        measure {
            _ = JSONLoader.getLocalizedString(key: "app.title")
        }
        // Should complete in < 0.001 seconds (cached after first load)
    }
}
