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

    // MARK: - Currency JSON Tests

    func testLoadCurrencies_fromMainBundle_succeeds() throws {
        // Given: currencies.json exists in main bundle

        // When: Loading currencies
        let result = JSONLoader.loadCurrencies()

        // Then: Should return valid currency data
        XCTAssertNotNil(result, "Should load currencies from main bundle")
        XCTAssertGreaterThan(result?.currencies.count ?? 0, 0, "Should have at least one currency")
        XCTAssertEqual(result?.version, "2.0", "Should match expected version")
    }

    func testLoadCurrencies_verifyStructure() throws {
        // When: Loading currencies
        guard let currencyData = JSONLoader.loadCurrencies() else {
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

    // MARK: - Error Handling Tests

    func testLoadCurrencies_fromInvalidBundle_returnsNil() {
        // Given: Invalid bundle
        let invalidBundle = Bundle(for: JSONLoaderTests.self) // Test bundle, not main bundle

        // When: Trying to load from test bundle (no currencies.json)
        let result = JSONLoader.loadCurrencies(from: invalidBundle, filename: "nonexistent")

        // Then: Should return nil gracefully
        XCTAssertNil(result, "Should return nil for missing file")
    }

    // MARK: - Performance Tests

    func testLoadCurrencies_performance() {
        // Measure performance of loading currencies
        measure {
            _ = JSONLoader.loadCurrencies()
        }
        // Should complete in < 0.01 seconds
    }
}
