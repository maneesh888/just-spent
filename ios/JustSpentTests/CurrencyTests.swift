//
//  CurrencyTests.swift
//  JustSpentTests
//
//  Created by Claude Code on 2025-10-19.
//  Comprehensive tests for currency functionality
//

import XCTest
@testable import JustSpent

final class CurrencyTests: XCTestCase {

    // MARK: - Currency Model Tests

    func testCurrencyProperties() {
        // Test USD
        let usd = Currency.usd
        XCTAssertEqual(usd.rawValue, "USD")
        XCTAssertEqual(usd.symbol, "$")
        XCTAssertEqual(usd.displayName, "US Dollar")
        XCTAssertFalse(usd.isRTL)

        // Test AED
        let aed = Currency.aed
        XCTAssertEqual(aed.rawValue, "AED")
        XCTAssertEqual(aed.symbol, "د.إ")
        XCTAssertEqual(aed.displayName, "UAE Dirham")
        XCTAssertTrue(aed.isRTL)

        // Test EUR
        let eur = Currency.eur
        XCTAssertEqual(eur.rawValue, "EUR")
        XCTAssertEqual(eur.symbol, "€")
        XCTAssertEqual(eur.displayName, "Euro")
        XCTAssertFalse(eur.isRTL)
    }

    func testCurrencyFromISOCode() {
        XCTAssertEqual(Currency.from(isoCode: "USD"), .usd)
        XCTAssertEqual(Currency.from(isoCode: "AED"), .aed)
        XCTAssertEqual(Currency.from(isoCode: "EUR"), .eur)
        XCTAssertEqual(Currency.from(isoCode: "GBP"), .gbp)
        XCTAssertEqual(Currency.from(isoCode: "INR"), .inr)
        XCTAssertEqual(Currency.from(isoCode: "SAR"), .sar)

        // Test case insensitivity
        XCTAssertEqual(Currency.from(isoCode: "usd"), .usd)
        XCTAssertEqual(Currency.from(isoCode: "Aed"), .aed)

        // Test invalid code
        XCTAssertNil(Currency.from(isoCode: "INVALID"))
    }

    func testCurrencyDetectionFromText() {
        // Test symbol detection
        XCTAssertEqual(Currency.detectFromText("$50"), .usd)
        XCTAssertEqual(Currency.detectFromText("د.إ 100"), .aed)
        XCTAssertEqual(Currency.detectFromText("€25"), .eur)
        XCTAssertEqual(Currency.detectFromText("£20"), .gbp)
        XCTAssertEqual(Currency.detectFromText("₹500"), .inr)
        XCTAssertEqual(Currency.detectFromText("﷼50"), .sar)

        // Test name detection
        XCTAssertEqual(Currency.detectFromText("50 dollars"), .usd)
        XCTAssertEqual(Currency.detectFromText("100 dirhams"), .aed)
        XCTAssertEqual(Currency.detectFromText("25 euros"), .eur)
        XCTAssertEqual(Currency.detectFromText("20 pounds"), .gbp)
        XCTAssertEqual(Currency.detectFromText("500 rupees"), .inr)
        XCTAssertEqual(Currency.detectFromText("50 riyals"), .sar)

        // Test colloquial terms
        XCTAssertEqual(Currency.detectFromText("50 bucks"), .usd)
        XCTAssertEqual(Currency.detectFromText("20 quid"), .gbp)

        // Test no match
        XCTAssertNil(Currency.detectFromText("spent money"))
    }

    func testCurrencyVoiceKeywords() {
        let usd = Currency.usd
        XCTAssertTrue(usd.voiceKeywords.contains("usd"))
        XCTAssertTrue(usd.voiceKeywords.contains("dollar"))
        XCTAssertTrue(usd.voiceKeywords.contains("$"))

        let aed = Currency.aed
        XCTAssertTrue(aed.voiceKeywords.contains("aed"))
        XCTAssertTrue(aed.voiceKeywords.contains("dirham"))
        XCTAssertTrue(aed.voiceKeywords.contains("د.إ"))
    }

    // MARK: - Currency Formatter Tests

    func testBasicFormatting() {
        let amount: Decimal = 1234.56

        // USD
        let usdFormatted = CurrencyFormatter.shared.format(
            amount: amount,
            currency: .usd,
            showSymbol: true,
            showCode: false
        )
        XCTAssertTrue(usdFormatted.contains("$"))
        XCTAssertTrue(usdFormatted.contains("1,234.56") || usdFormatted.contains("1234.56"))

        // AED
        let aedFormatted = CurrencyFormatter.shared.format(
            amount: amount,
            currency: .aed,
            showSymbol: true,
            showCode: false
        )
        XCTAssertTrue(aedFormatted.contains("د.إ"))

        // EUR
        let eurFormatted = CurrencyFormatter.shared.format(
            amount: amount,
            currency: .eur,
            showSymbol: true,
            showCode: false
        )
        XCTAssertTrue(eurFormatted.contains("€"))
    }

    func testFormattingWithCode() {
        let amount: Decimal = 100.00

        let formatted = CurrencyFormatter.shared.format(
            amount: amount,
            currency: .usd,
            showSymbol: true,
            showCode: true
        )

        XCTAssertTrue(formatted.contains("$"))
        XCTAssertTrue(formatted.contains("USD"))
    }

    func testCompactFormatting() {
        let amount: Decimal = 50.25

        let compact = CurrencyFormatter.shared.formatCompact(amount: amount, currency: .usd)
        XCTAssertTrue(compact.contains("$"))
        XCTAssertTrue(compact.contains("50.25"))
    }

    func testDetailedFormatting() {
        let amount: Decimal = 75.50

        let detailed = CurrencyFormatter.shared.formatDetailed(amount: amount, currency: .gbp)
        XCTAssertTrue(detailed.contains("£"))
        XCTAssertTrue(detailed.contains("GBP"))
    }

    func testDecimalExtensions() {
        let amount: Decimal = 100.00

        let formatted = amount.formatted(as: .usd)
        XCTAssertTrue(formatted.contains("$"))

        let compact = amount.formattedCompact(as: .aed)
        XCTAssertTrue(compact.contains("د.إ"))

        let detailed = amount.formattedDetailed(as: .eur)
        XCTAssertTrue(detailed.contains("€"))
        XCTAssertTrue(detailed.contains("EUR"))
    }

    func testCurrencyParsing() {
        // Test parsing formatted currency
        let parsed = CurrencyFormatter.shared.parse(string: "$100.50", currency: .usd)
        XCTAssertEqual(parsed, Decimal(string: "100.50"))

        // Test parsing with different symbols
        let parsedAED = CurrencyFormatter.shared.parse(string: "د.إ 250.75", currency: .aed)
        XCTAssertEqual(parsedAED, Decimal(string: "250.75"))

        // Test parsing just numbers
        let parsedPlain = CurrencyFormatter.shared.parse(string: "50.25", currency: .usd)
        XCTAssertEqual(parsedPlain, Decimal(string: "50.25"))
    }

    // MARK: - Voice Currency Detector Tests

    func testSimpleAmountCurrencyExtraction() {
        let detector = VoiceCurrencyDetector.shared

        // Test "50 dollars"
        if let result = detector.extractAmountAndCurrency(from: "50 dollars") {
            XCTAssertEqual(result.amount, 50)
            XCTAssertEqual(result.currency, .usd)
        } else {
            XCTFail("Failed to extract amount and currency")
        }

        // Test "د.إ 100"
        if let result = detector.extractAmountAndCurrency(from: "د.إ 100") {
            XCTAssertEqual(result.amount, 100)
            XCTAssertEqual(result.currency, .aed)
        } else {
            XCTFail("Failed to extract amount and currency")
        }
    }

    func testComplexVoiceCommandExtraction() {
        let detector = VoiceCurrencyDetector.shared

        // Test full sentence
        if let result = detector.extractAmountAndCurrency(from: "I just spent 25.50 euros on groceries") {
            XCTAssertEqual(result.amount, 25.50)
            XCTAssertEqual(result.currency, .eur)
        } else {
            XCTFail("Failed to extract from complex sentence")
        }

        // Test with merchant
        if let result = detector.extractAmountAndCurrency(from: "Paid 20 pounds at the store") {
            XCTAssertEqual(result.amount, 20)
            XCTAssertEqual(result.currency, .gbp)
        } else {
            XCTFail("Failed to extract from sentence with merchant")
        }
    }

    func testCurrencyDetectionWithoutAmount() {
        let detector = VoiceCurrencyDetector.shared

        let usd = detector.detectCurrency(from: "spent some dollars", default: .aed)
        XCTAssertEqual(usd, .usd)

        let aed = detector.detectCurrency(from: "paid in dirhams", default: .usd)
        XCTAssertEqual(aed, .aed)

        // Test default fallback
        let defaultCurrency = detector.detectCurrency(from: "spent money", default: .gbp)
        XCTAssertEqual(defaultCurrency, .gbp)
    }

    func testContainsCurrency() {
        let detector = VoiceCurrencyDetector.shared

        XCTAssertTrue(detector.containsCurrency("50 dollars"))
        XCTAssertTrue(detector.containsCurrency("د.إ 100"))
        XCTAssertTrue(detector.containsCurrency("paid in euros"))
        XCTAssertFalse(detector.containsCurrency("spent money"))
    }

    func testNormalizeCurrencySymbols() {
        let detector = VoiceCurrencyDetector.shared

        let normalized = detector.normalizeCurrencySymbols(in: "$50 and €25 and د.إ 100")
        XCTAssertTrue(normalized.contains("USD"))
        XCTAssertTrue(normalized.contains("EUR"))
        XCTAssertTrue(normalized.contains("AED"))
    }

    // MARK: - User Preferences Tests

    func testDefaultCurrencyPersistence() {
        let preferences = UserPreferences.shared

        // Set new currency
        preferences.setDefaultCurrency(.aed)

        // Verify it's saved
        XCTAssertEqual(preferences.getCurrentCurrency(), .aed)

        // Reset to default
        preferences.resetToDefaults()
    }

    func testCurrencyChangeNotification() {
        let preferences = UserPreferences.shared
        let expectation = XCTestExpectation(description: "Currency changed")

        var receivedCurrency: Currency?
        let cancellable = preferences.$defaultCurrency
            .dropFirst() // Skip initial value
            .sink { currency in
                receivedCurrency = currency
                expectation.fulfill()
            }

        // Change currency
        preferences.setDefaultCurrency(.eur)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedCurrency, .eur)

        cancellable.cancel()
        preferences.resetToDefaults()
    }

    // MARK: - Integration Tests

    func testEndToEndCurrencyFlow() {
        // Simulate voice command: "I spent 50 dirhams on groceries"
        let voiceCommand = "I spent 50 dirhams on groceries"

        // 1. Detect currency
        guard let currency = Currency.detectFromText(voiceCommand) else {
            XCTFail("Failed to detect currency")
            return
        }
        XCTAssertEqual(currency, .aed)

        // 2. Extract amount
        let detector = VoiceCurrencyDetector.shared
        guard let (amount, extractedCurrency) = detector.extractAmountAndCurrency(from: voiceCommand) else {
            XCTFail("Failed to extract amount and currency")
            return
        }
        XCTAssertEqual(amount, 50)
        XCTAssertEqual(extractedCurrency, .aed)

        // 3. Format for display
        let formatted = CurrencyFormatter.shared.formatCompact(amount: amount, currency: extractedCurrency)
        XCTAssertTrue(formatted.contains("د.إ"))
        XCTAssertTrue(formatted.contains("50"))
    }
}
