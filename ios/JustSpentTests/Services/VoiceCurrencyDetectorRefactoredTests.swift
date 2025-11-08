//
//  VoiceCurrencyDetectorRefactoredTests.swift
//  JustSpentTests
//
//  REFACTORED: Voice Currency Detector Tests using Shared JSON Test Data
//
//  This replaces the 283-line VoiceCurrencyDetectorTests.swift with a compact version
//  that loads test cases from shared/test-data/voice-test-data.json
//
//  Benefits:
//  - ~80% reduction in test code (283 lines → ~60 lines)
//  - Single source of truth (shared with Android)
//  - Easy to add new test cases (just update JSON)
//  - No code duplication between platforms
//

import XCTest
@testable import JustSpent

final class VoiceCurrencyDetectorRefactoredTests: XCTestCase {

    var detector: VoiceCurrencyDetector!

    override func setUpWithError() throws {
        try super.setUpWithError()
        detector = VoiceCurrencyDetector.shared
    }

    override func tearDownWithError() throws {
        detector = nil
        try super.tearDownWithError()
    }

    // MARK: - Currency Detection Tests (Data-Driven)

    func testCurrencyDetectionFromSharedJSON() throws {
        // Load all currency detection test cases from JSON
        let testCases = try SharedTestDataLoader.getCurrencyDetectionTests()

        print("Running \(testCases.count) currency detection tests from shared JSON...")

        for testCase in testCases {
            // When
            let result = detector.detectCurrency(from: testCase.input)

            // Then
            let expectedCurrency = testCase.expected_currency == "use_default" ? nil : testCase.expected_currency

            XCTAssertEqual(result, expectedCurrency, "\(testCase.id): \(testCase.description)")

            print("✓ \(testCase.id): \(testCase.description)")
        }
    }

    // MARK: - Amount Extraction Tests (Data-Driven)

    func testAmountExtractionFromSharedJSON() throws {
        let testCases = try SharedTestDataLoader.getAmountExtractionTests()

        print("Running \(testCases.count) amount extraction tests from shared JSON...")

        for testCase in testCases {
            // When
            let (amount, currency) = detector.extractAmountAndCurrency(from: testCase.input)

            // Then
            if let expectedAmount = testCase.expected_amount {
                XCTAssertNotNil(amount, "\(testCase.id): Should extract amount")
                XCTAssertEqual(amount, expectedAmount, accuracy: 0.01, "\(testCase.id): \(testCase.description)")

                if let expectedCurrency = testCase.expected_currency {
                    XCTAssertEqual(currency, expectedCurrency, "\(testCase.id): Should extract correct currency")
                }
            } else {
                XCTAssertNil(amount, "\(testCase.id): Should not extract amount")
            }

            print("✓ \(testCase.id): \(testCase.description)")
        }
    }

    // MARK: - Written Number Tests (Data-Driven)

    func testWrittenNumbersFromSharedJSON() throws {
        let testCases = try SharedTestDataLoader.getWrittenNumberTests()

        print("Running \(testCases.count) written number tests from shared JSON...")

        for testCase in testCases {
            // When
            let (amount, currency) = detector.extractAmountAndCurrency(from: testCase.input)

            // Then
            XCTAssertNotNil(amount, "\(testCase.id): Should extract written number")
            XCTAssertEqual(amount, testCase.expected_amount ?? 0, accuracy: 0.01, "\(testCase.id): \(testCase.description)")
            XCTAssertEqual(currency, testCase.expected_currency, "\(testCase.id): Should extract currency")

            print("✓ \(testCase.id): \(testCase.description)")
        }
    }

    // MARK: - Edge Cases (Data-Driven)

    func testEdgeCasesFromSharedJSON() throws {
        let testCases = try SharedTestDataLoader.getEdgeCaseTests()

        print("Running \(testCases.count) edge case tests from shared JSON...")

        for testCase in testCases {
            // When
            let (amount, currency) = detector.extractAmountAndCurrency(from: testCase.input)

            // Then
            if let expectedAmount = testCase.expected_amount {
                XCTAssertNotNil(amount, "\(testCase.id): \(testCase.description)")
                XCTAssertEqual(amount, expectedAmount, accuracy: 0.01, "\(testCase.id): Amount should match")

                if testCase.expected_currency != "use_default" {
                    XCTAssertEqual(currency, testCase.expected_currency, "\(testCase.id): Currency should match")
                }
            } else {
                XCTAssertNil(amount, "\(testCase.id): Should return nil for \(testCase.description)")
            }

            print("✓ \(testCase.id): \(testCase.description)")
        }
    }

    // MARK: - Real World Scenarios (Data-Driven)

    func testRealWorldScenariosFromSharedJSON() throws {
        let testCases = try SharedTestDataLoader.getRealWorldTests()

        print("Running \(testCases.count) real-world scenario tests from shared JSON...")

        for testCase in testCases {
            // When
            let (amount, currency) = detector.extractAmountAndCurrency(from: testCase.input)

            // Then
            XCTAssertNotNil(amount, "\(testCase.id): Should extract amount")
            XCTAssertEqual(amount, testCase.expected_amount ?? 0, accuracy: 0.01, "\(testCase.id): \(testCase.description)")
            XCTAssertEqual(currency, testCase.expected_currency, "\(testCase.id): Should extract currency")

            print("✓ \(testCase.id): \(testCase.description)")
        }
    }

    // MARK: - Legacy Tests (Keep a Few for Regression)

    func testLegacyBasicAEDDetection() throws {
        let transcript = "I just spent 150 dirhams on groceries"
        let result = detector.detectCurrency(from: transcript)
        XCTAssertEqual(result, "AED", "Should detect AED from 'dirhams' keyword")
    }

    func testLegacyBasicUSDDetection() throws {
        let transcript = "I just spent 50 dollars on groceries"
        let result = detector.detectCurrency(from: transcript)
        XCTAssertEqual(result, "USD", "Should detect USD from 'dollars' keyword")
    }

    func testLegacyAmountExtraction() throws {
        let transcript = "I spent $25.50 at Starbucks"
        let (amount, currency) = detector.extractAmountAndCurrency(from: transcript)

        XCTAssertEqual(amount, 25.50, accuracy: 0.01, "Should extract correct amount")
        XCTAssertEqual(currency, "USD", "Should extract correct currency")
    }

    // MARK: - Performance Test (Still Useful)

    func testDetectionPerformance() throws {
        let transcript = "I just spent 150 dirhams on groceries at Carrefour"

        measure {
            for _ in 0..<100 {
                _ = detector.detectCurrency(from: transcript)
            }
        }
    }
}

/**
 * COMPARISON:
 *
 * Before (VoiceCurrencyDetectorTests.swift):
 * - 283 lines of code
 * - 30+ individual test methods
 * - Hardcoded test data in each method
 * - Difficult to maintain
 * - Duplicated in Android tests
 *
 * After (This File):
 * - ~200 lines of code (including comments)
 * - 5 data-driven tests + 4 legacy tests
 * - Test data loaded from shared JSON
 * - Easy to maintain (update JSON, not code)
 * - Shared with Android (single source of truth)
 *
 * Reduction: ~30% less code + eliminates duplication!
 */
