//
//  VoiceCurrencyDetectorTests.swift
//  JustSpentTests
//
//  Created by Claude Code on 2025-10-20.
//  Tests for voice currency detection functionality
//

import XCTest
@testable import JustSpent

final class VoiceCurrencyDetectorTests: XCTestCase {

    var detector: VoiceCurrencyDetector!

    override func setUpWithError() throws {
        try super.setUpWithError()
        detector = VoiceCurrencyDetector.shared
    }

    override func tearDownWithError() throws {
        detector = nil
        try super.tearDownWithError()
    }

    // MARK: - Currency Symbol Detection Tests

    func testDetectDollarSymbol() throws {
        let transcript = "I spent $50 on groceries"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertEqual(result, "USD", "Should detect USD from $ symbol")
    }

    func testDetectEuroSymbol() throws {
        let transcript = "I spent €45 on entertainment"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertEqual(result, "EUR", "Should detect EUR from € symbol")
    }

    func testDetectPoundSymbol() throws {
        let transcript = "I spent £30 on shopping"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertEqual(result, "GBP", "Should detect GBP from £ symbol")
    }

    func testDetectDirhamSymbol() throws {
        let transcript = "I spent د.إ 150 on groceries"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertEqual(result, "AED", "Should detect AED from د.إ symbol")
    }

    // MARK: - Currency Keyword Detection Tests

    func testDetectDollarsKeyword() throws {
        let transcript = "I just spent 50 dollars on groceries"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertEqual(result, "USD", "Should detect USD from 'dollars' keyword")
    }

    func testDetectDirhamsKeyword() throws {
        let transcript = "I just spent 150 dirhams on groceries"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertEqual(result, "AED", "Should detect AED from 'dirhams' keyword")
    }

    func testDetectEurosKeyword() throws {
        let transcript = "I spent 45 euros on entertainment"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertEqual(result, "EUR", "Should detect EUR from 'euros' keyword")
    }

    func testDetectPoundsKeyword() throws {
        let transcript = "I spent 20 pounds on transport"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertEqual(result, "GBP", "Should detect GBP from 'pounds' keyword")
    }

    func testDetectRupeesKeyword() throws {
        let transcript = "I spent 500 rupees on groceries"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertEqual(result, "INR", "Should detect INR from 'rupees' keyword")
    }

    func testDetectRupeeSymbol() throws {
        let transcript = "I spent ₹500 on groceries"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertEqual(result, "INR", "Should detect INR from ₹ symbol")
    }

    func testDetectRupeeSymbolNoSpace() throws {
        let transcript = "I just spent ₹20"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertEqual(result, "INR", "Should detect INR from ₹ symbol without space")
    }

    func testDetectRsAbbreviation() throws {
        let transcript = "I spent Rs 500 on groceries"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertEqual(result, "INR", "Should detect INR from Rs abbreviation")
    }

    func testDetectRiyalsKeyword() throws {
        let transcript = "I spent 100 riyals on shopping"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertEqual(result, "SAR", "Should detect SAR from 'riyals' keyword")
    }

    // MARK: - ISO Code Detection Tests

    func testDetectAEDCode() throws {
        let transcript = "I spent 150 AED on groceries"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertEqual(result, "AED", "Should detect AED from ISO code")
    }

    func testDetectUSDCode() throws {
        let transcript = "I spent 50 USD on shopping"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertEqual(result, "USD", "Should detect USD from ISO code")
    }

    func testDetectEURCode() throws {
        let transcript = "I spent 45 EUR on entertainment"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertEqual(result, "EUR", "Should detect EUR from ISO code")
    }

    // MARK: - Amount and Currency Extraction Tests

    func testExtractAmountAndCurrencyWithSymbol() throws {
        let transcript = "I spent $25.50 at Starbucks"
        let (amount, currency) = detector.extractAmountAndCurrency(from: transcript)

        XCTAssertEqual(amount, 25.50, accuracy: 0.01, "Should extract correct amount")
        XCTAssertEqual(currency, "USD", "Should extract correct currency")
    }

    func testExtractAmountAndCurrencyWithKeyword() throws {
        let transcript = "I just spent 150 dirhams on groceries"
        let (amount, currency) = detector.extractAmountAndCurrency(from: transcript)

        XCTAssertEqual(amount, 150.0, accuracy: 0.01, "Should extract correct amount")
        XCTAssertEqual(currency, "AED", "Should extract correct currency")
    }

    func testExtractAmountWithoutCurrency() throws {
        let transcript = "I spent 75 on groceries"
        let (amount, currency) = detector.extractAmountAndCurrency(from: transcript)

        XCTAssertEqual(amount, 75.0, accuracy: 0.01, "Should extract correct amount")
        XCTAssertNil(currency, "Should return nil currency when not specified")
    }

    func testExtractDecimalAmount() throws {
        let transcript = "I spent $12.99 on lunch"
        let (amount, currency) = detector.extractAmountAndCurrency(from: transcript)

        XCTAssertEqual(amount, 12.99, accuracy: 0.01, "Should extract decimal amount correctly")
        XCTAssertEqual(currency, "USD", "Should extract correct currency")
    }

    func testExtractAmountWithRupeeSymbol() throws {
        let transcript = "I just spent ₹20"
        let (amount, currency) = detector.extractAmountAndCurrency(from: transcript)

        XCTAssertEqual(amount, 20.0, accuracy: 0.01, "Should extract amount from ₹20")
        XCTAssertEqual(currency, "INR", "Should detect INR from ₹ symbol")
    }

    func testExtractAmountWithRsAbbreviation() throws {
        let transcript = "I spent Rs 500 on groceries"
        let (amount, currency) = detector.extractAmountAndCurrency(from: transcript)

        XCTAssertEqual(amount, 500.0, accuracy: 0.01, "Should extract amount with Rs")
        XCTAssertEqual(currency, "INR", "Should detect INR from Rs abbreviation")
    }

    // MARK: - Written Number Detection Tests

    func testDetectWrittenNumberTwenty() throws {
        let transcript = "I spent twenty dollars on food"
        let (amount, currency) = detector.extractAmountAndCurrency(from: transcript)

        XCTAssertEqual(amount, 20.0, accuracy: 0.01, "Should extract written number 'twenty'")
        XCTAssertEqual(currency, "USD", "Should detect USD currency")
    }

    func testDetectWrittenNumberFifty() throws {
        let transcript = "I spent fifty dirhams on groceries"
        let (amount, currency) = detector.extractAmountAndCurrency(from: transcript)

        XCTAssertEqual(amount, 50.0, accuracy: 0.01, "Should extract written number 'fifty'")
        XCTAssertEqual(currency, "AED", "Should detect AED currency")
    }

    func testDetectWrittenNumberOneHundred() throws {
        let transcript = "I spent one hundred euros on shopping"
        let (amount, currency) = detector.extractAmountAndCurrency(from: transcript)

        XCTAssertEqual(amount, 100.0, accuracy: 0.01, "Should extract written number 'one hundred'")
        XCTAssertEqual(currency, "EUR", "Should detect EUR currency")
    }

    // MARK: - Edge Cases and Error Handling Tests

    func testNoCurrencyDetectedReturnsNil() throws {
        let transcript = "I spent something on groceries"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertNil(result, "Should return nil when no currency detected")
    }

    func testEmptyTranscriptReturnsNil() throws {
        let transcript = ""
        let result = detector.detectCurrency(from: transcript)

        XCTAssertNil(result, "Should return nil for empty transcript")
    }

    func testNoAmountDetectedReturnsNil() throws {
        let transcript = "I went to the store"
        let (amount, _) = detector.extractAmountAndCurrency(from: transcript)

        XCTAssertNil(amount, "Should return nil when no amount detected")
    }

    func testCaseInsensitiveDetection() throws {
        let transcript1 = "I spent 50 DOLLARS on groceries"
        let result1 = detector.detectCurrency(from: transcript1)

        let transcript2 = "I spent 50 DoLLaRs on groceries"
        let result2 = detector.detectCurrency(from: transcript2)

        XCTAssertEqual(result1, "USD", "Should detect USD case-insensitively (uppercase)")
        XCTAssertEqual(result2, "USD", "Should detect USD case-insensitively (mixed case)")
    }

    func testMultipleCurrencyMentions() throws {
        // Should detect the first mentioned currency
        let transcript = "I spent 50 dollars and 30 euros"
        let result = detector.detectCurrency(from: transcript)

        XCTAssertEqual(result, "USD", "Should detect first mentioned currency")
    }

    // MARK: - Performance Tests

    func testDetectionPerformance() throws {
        let transcript = "I just spent 150 dirhams on groceries at Carrefour"

        measure {
            for _ in 0..<100 {
                _ = detector.detectCurrency(from: transcript)
            }
        }
    }

    func testExtractionPerformance() throws {
        let transcript = "I just spent $25.50 at Starbucks for coffee"

        measure {
            for _ in 0..<100 {
                _ = detector.extractAmountAndCurrency(from: transcript)
            }
        }
    }
}
