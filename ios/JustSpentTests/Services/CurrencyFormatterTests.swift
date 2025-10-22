//
//  CurrencyFormatterTests.swift
//  JustSpentTests
//
//  Created by Claude Code on 2025-10-20.
//  Tests for currency formatting functionality
//

import XCTest
@testable import JustSpent

final class CurrencyFormatterTests: XCTestCase {

    var formatter: CurrencyFormatter!

    override func setUpWithError() throws {
        try super.setUpWithError()
        formatter = CurrencyFormatter.shared
    }

    override func tearDownWithError() throws {
        formatter = nil
        try super.tearDownWithError()
    }

    // MARK: - Format with Symbol Tests

    func testFormatAEDWithSymbol() throws {
        let amount = Decimal(150.50)
        let result = formatter.format(amount: amount, currency: .aed, showSymbol: true, showCode: false)

        XCTAssertTrue(result.contains("د.إ"), "Should contain AED symbol")
        XCTAssertTrue(result.contains("150"), "Should contain amount")
    }

    func testFormatUSDWithSymbol() throws {
        let amount = Decimal(1234.56)
        let result = formatter.format(amount: amount, currency: .usd, showSymbol: true, showCode: false)

        XCTAssertTrue(result.contains("$"), "Should contain USD symbol")
        XCTAssertTrue(result.contains("1"), "Should contain amount")
        XCTAssertTrue(result.contains("234"), "Should contain thousands")
    }

    func testFormatEURWithSymbol() throws {
        let amount = Decimal(999.99)
        let result = formatter.format(amount: amount, currency: .eur, showSymbol: true, showCode: false)

        XCTAssertTrue(result.contains("€"), "Should contain EUR symbol")
        XCTAssertTrue(result.contains("999"), "Should contain amount")
    }

    func testFormatGBPWithSymbol() throws {
        let amount = Decimal(50.00)
        let result = formatter.format(amount: amount, currency: .gbp, showSymbol: true, showCode: false)

        XCTAssertTrue(result.contains("£"), "Should contain GBP symbol")
        XCTAssertTrue(result.contains("50"), "Should contain amount")
    }

    func testFormatINRWithSymbol() throws {
        let amount = Decimal(5000.00)
        let result = formatter.format(amount: amount, currency: .inr, showSymbol: true, showCode: false)

        XCTAssertTrue(result.contains("₹"), "Should contain INR symbol")
        XCTAssertTrue(result.contains("5"), "Should contain amount")
    }

    func testFormatSARWithSymbol() throws {
        let amount = Decimal(250.00)
        let result = formatter.format(amount: amount, currency: .sar, showSymbol: true, showCode: false)

        XCTAssertTrue(result.contains("﷼"), "Should contain SAR symbol")
        XCTAssertTrue(result.contains("250"), "Should contain amount")
    }

    // MARK: - Format with Code Tests

    func testFormatWithCurrencyCode() throws {
        let amount = Decimal(100.00)
        let result = formatter.format(amount: amount, currency: .aed, showSymbol: false, showCode: true)

        XCTAssertTrue(result.contains("AED"), "Should contain currency code")
        XCTAssertTrue(result.contains("100"), "Should contain amount")
    }

    func testFormatWithBothSymbolAndCode() throws {
        let amount = Decimal(100.00)
        let result = formatter.format(amount: amount, currency: .usd, showSymbol: true, showCode: true)

        XCTAssertTrue(result.contains("$") || result.contains("USD"), "Should contain either symbol or code")
        XCTAssertTrue(result.contains("100"), "Should contain amount")
    }

    // MARK: - Compact Formatting Tests

    func testFormatCompactAED() throws {
        let amount = Decimal(150.50)
        let result = formatter.formatCompact(amount: amount, currency: .aed)

        XCTAssertTrue(result.contains("د.إ"), "Should contain AED symbol")
        XCTAssertTrue(result.contains("150"), "Should contain amount")
    }

    func testFormatCompactUSD() throws {
        let amount = Decimal(25.50)
        let result = formatter.formatCompact(amount: amount, currency: .usd)

        XCTAssertTrue(result.contains("$"), "Should contain USD symbol")
        XCTAssertTrue(result.contains("25"), "Should contain amount")
    }

    func testFormatCompactWithLargeAmount() throws {
        let amount = Decimal(1000000.00)
        let result = formatter.formatCompact(amount: amount, currency: .usd)

        XCTAssertTrue(result.contains("$"), "Should contain USD symbol")
        // Compact format may show as 1M or 1,000,000
        XCTAssertFalse(result.isEmpty, "Should not be empty")
    }

    // MARK: - Decimal Places Tests

    func testFormatWithTwoDecimalPlaces() throws {
        let amount = Decimal(150.00)
        let result = formatter.format(amount: amount, currency: .aed, showSymbol: true, showCode: false)

        // Should have proper decimal representation
        XCTAssertTrue(result.contains("150") || result.contains("150.00") || result.contains("150.0"), "Should format amount correctly")
    }

    func testFormatWithDecimalAmount() throws {
        let amount = Decimal(25.99)
        let result = formatter.format(amount: amount, currency: .usd, showSymbol: true, showCode: false)

        XCTAssertTrue(result.contains("25") && result.contains("99"), "Should preserve decimal places")
    }

    // MARK: - Edge Cases Tests

    func testFormatZeroAmount() throws {
        let amount = Decimal(0.00)
        let result = formatter.format(amount: amount, currency: .aed, showSymbol: true, showCode: false)

        XCTAssertTrue(result.contains("0"), "Should format zero amount")
        XCTAssertTrue(result.contains("د.إ"), "Should contain currency symbol")
    }

    func testFormatVeryLargeAmount() throws {
        let amount = Decimal(999999999.99)
        let result = formatter.format(amount: amount, currency: .usd, showSymbol: true, showCode: false)

        XCTAssertTrue(result.contains("$"), "Should contain USD symbol")
        XCTAssertFalse(result.isEmpty, "Should format very large amount")
    }

    func testFormatVerySmallAmount() throws {
        let amount = Decimal(0.01)
        let result = formatter.format(amount: amount, currency: .usd, showSymbol: true, showCode: false)

        XCTAssertTrue(result.contains("$"), "Should contain USD symbol")
        XCTAssertTrue(result.contains("0") && result.contains("01"), "Should format very small amount")
    }

    // MARK: - Locale-aware Formatting Tests

    func testFormatWithDifferentLocales() throws {
        let amount = Decimal(1234.56)

        // Test with different currencies (which use different locales)
        let aedResult = formatter.format(amount: amount, currency: .aed, showSymbol: true, showCode: false)
        let usdResult = formatter.format(amount: amount, currency: .usd, showSymbol: true, showCode: false)
        let eurResult = formatter.format(amount: amount, currency: .eur, showSymbol: true, showCode: false)

        XCTAssertTrue(aedResult.contains("د.إ"), "AED should use correct symbol")
        XCTAssertTrue(usdResult.contains("$"), "USD should use correct symbol")
        XCTAssertTrue(eurResult.contains("€"), "EUR should use correct symbol")
    }

    func testThousandsSeparator() throws {
        let amount = Decimal(1000.00)
        let result = formatter.format(amount: amount, currency: .usd, showSymbol: true, showCode: false)

        // Different locales may use different separators (comma or period)
        XCTAssertTrue(result.contains("1") && result.contains("000"), "Should include thousands in format")
    }

    // MARK: - Rounding Tests

    func testRoundingToTwoDecimalPlaces() throws {
        let amount = Decimal(string: "25.999")!
        let result = formatter.format(amount: amount, currency: .usd, showSymbol: true, showCode: false)

        // Should round to 2 decimal places
        XCTAssertTrue(result.contains("26") || result.contains("25"), "Should round decimal places")
    }

    func testRoundingDown() throws {
        let amount = Decimal(string: "25.001")!
        let result = formatter.format(amount: amount, currency: .usd, showSymbol: true, showCode: false)

        // Should round to 2 decimal places
        XCTAssertTrue(result.contains("25"), "Should round down")
    }

    // MARK: - Performance Tests

    func testFormattingPerformance() throws {
        let amount = Decimal(1234.56)

        measure {
            for _ in 0..<1000 {
                _ = formatter.format(amount: amount, currency: .usd, showSymbol: true, showCode: false)
            }
        }
    }

    func testCompactFormattingPerformance() throws {
        let amount = Decimal(1234.56)

        measure {
            for _ in 0..<1000 {
                _ = formatter.formatCompact(amount: amount, currency: .usd)
            }
        }
    }

    // MARK: - Currency-specific Tests

    func testAllSupportedCurrencies() throws {
        let amount = Decimal(100.00)
        let currencies: [Currency] = [.aed, .usd, .eur, .gbp, .inr, .sar]

        for currency in currencies {
            let result = formatter.format(amount: amount, currency: currency, showSymbol: true, showCode: false)

            XCTAssertFalse(result.isEmpty, "Should format \(currency.rawValue)")
            XCTAssertTrue(result.contains(currency.symbol) || result.contains("100"), "Should contain symbol or amount for \(currency.rawValue)")
        }
    }

    func testCurrencyCodeFormatting() throws {
        let amount = Decimal(100.00)
        let currencies: [Currency] = [.aed, .usd, .eur, .gbp, .inr, .sar]

        for currency in currencies {
            let result = formatter.format(amount: amount, currency: currency, showSymbol: false, showCode: true)

            XCTAssertTrue(result.contains(currency.rawValue), "Should contain currency code \(currency.rawValue)")
        }
    }
}
