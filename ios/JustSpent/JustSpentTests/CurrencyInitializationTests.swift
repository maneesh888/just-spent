//
//  CurrencyInitializationTests.swift
//  JustSpentTests
//
//  Created by Claude Code on 2025-01-29.
//  Tests to verify Currency initialization works in all environments
//

import XCTest
@testable import JustSpent

class CurrencyInitializationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset currency cache to simulate fresh start
        // Note: Currency doesn't expose reset, so we test actual initialization
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testCurrency_initialize_loadsFromJSON() {
        // Given - Fresh initialization
        Currency.initialize()

        // When - Get all currencies
        let allCurrencies = Currency.all

        // Then - Should load all 36 currencies from currencies.json
        XCTAssertFalse(allCurrencies.isEmpty, "Currency.all should not be empty after initialization")
        XCTAssertGreaterThanOrEqual(allCurrencies.count, 36, "Should load at least 36 currencies from JSON")

        // Verify test data currencies exist
        let testCodes = ["AED", "USD", "EUR", "GBP", "INR", "SAR"]
        for code in testCodes {
            let currency = Currency.from(isoCode: code)
            XCTAssertNotNil(currency, "Should find currency for code: \(code)")
            XCTAssertEqual(currency?.code, code, "Currency code should match")
        }
    }

    func testCurrency_from_returnsValidCurrency() {
        // Given
        Currency.initialize()

        // When/Then - Test all 6 test data currencies
        let aed = Currency.from(isoCode: "AED")
        XCTAssertNotNil(aed)
        XCTAssertEqual(aed?.code, "AED")
        XCTAssertEqual(aed?.displayName, "UAE Dirham")
        XCTAssertEqual(aed?.symbol, "د.إ")

        let usd = Currency.from(isoCode: "USD")
        XCTAssertNotNil(usd)
        XCTAssertEqual(usd?.code, "USD")
        XCTAssertEqual(usd?.displayName, "US Dollar")
        XCTAssertEqual(usd?.symbol, "$")

        let eur = Currency.from(isoCode: "EUR")
        XCTAssertNotNil(eur)
        XCTAssertEqual(eur?.code, "EUR")

        let gbp = Currency.from(isoCode: "GBP")
        XCTAssertNotNil(gbp)
        XCTAssertEqual(gbp?.code, "GBP")

        let inr = Currency.from(isoCode: "INR")
        XCTAssertNotNil(inr)
        XCTAssertEqual(inr?.code, "INR")

        let sar = Currency.from(isoCode: "SAR")
        XCTAssertNotNil(sar)
        XCTAssertEqual(sar?.code, "SAR")
    }

    func testCurrency_from_isCaseInsensitive() {
        // Given
        Currency.initialize()

        // When/Then - Should work with lowercase
        let aedLower = Currency.from(isoCode: "aed")
        XCTAssertNotNil(aedLower)
        XCTAssertEqual(aedLower?.code, "AED")

        // Should work with mixed case
        let usdMixed = Currency.from(isoCode: "uSd")
        XCTAssertNotNil(usdMixed)
        XCTAssertEqual(usdMixed?.code, "USD")
    }

    func testCurrency_from_returnsNilForInvalid() {
        // Given
        Currency.initialize()

        // When/Then
        let invalid = Currency.from(isoCode: "INVALID")
        XCTAssertNil(invalid, "Should return nil for invalid currency code")

        let empty = Currency.from(isoCode: "")
        XCTAssertNil(empty, "Should return nil for empty string")
    }

    // MARK: - UI Test Scenario Tests

    func testCurrency_worksWithStringCurrencyCodes() {
        // This simulates the exact scenario in UI tests:
        // 1. Test data creates expenses with string currency codes
        // 2. ContentView tries to convert them to Currency objects

        // Given - Initialize currencies (as JustSpentApp does)
        Currency.initialize()

        // Given - Simulate test data with string currency codes
        let testCurrencyCodes = ["AED", "USD", "EUR", "GBP", "INR", "SAR"]

        // When - Convert strings to Currency objects (as ContentView does)
        let currencies = testCurrencyCodes.compactMap { Currency.from(isoCode: $0) }

        // Then - Should successfully convert all 6
        XCTAssertEqual(currencies.count, 6, "Should convert all 6 currency codes to Currency objects")

        // Safely check each currency (with defensive guard)
        guard currencies.count >= 6 else {
            XCTFail("Expected 6 currencies but got \(currencies.count). Currency.initialize() may have failed to load currencies.json")
            return
        }

        XCTAssertEqual(currencies[0].code, "AED")
        XCTAssertEqual(currencies[1].code, "USD")
        XCTAssertEqual(currencies[2].code, "EUR")
        XCTAssertEqual(currencies[3].code, "GBP")
        XCTAssertEqual(currencies[4].code, "INR")
        XCTAssertEqual(currencies[5].code, "SAR")
    }

    func testCurrency_multipleInitializationCallsSafe() {
        // Given/When - Call initialize multiple times
        Currency.initialize()
        Currency.initialize()
        Currency.initialize()

        // Then - Should still work
        let allCurrencies = Currency.all
        XCTAssertFalse(allCurrencies.isEmpty)
        XCTAssertGreaterThanOrEqual(allCurrencies.count, 36)
    }
}
