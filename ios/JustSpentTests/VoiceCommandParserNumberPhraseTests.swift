//
//  VoiceCommandParserNumberPhraseTests.swift
//  JustSpentTests
//
//  Integration tests for VoiceCommandParser with NumberPhraseParser
//  Verifies end-to-end voice command processing with number phrases
//

import XCTest
@testable import JustSpent

final class VoiceCommandParserNumberPhraseTests: XCTestCase {

    var parser: VoiceCommandParser!

    override func setUpWithError() throws {
        try super.setUpWithError()
        parser = VoiceCommandParser.shared
    }

    override func tearDownWithError() throws {
        parser = nil
        try super.tearDownWithError()
    }

    // MARK: - Critical Bug Fix Tests

    func testProcessCommandTwoThousandDirhams() throws {
        // USER'S BUG: "two thousand dirhams" was parsed as 200
        let command = "I just spent two thousand dirhams on groceries"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 2000.0, accuracy: 0.01, "Should parse 'two thousand' as 2000, not 200")
        XCTAssertEqual(result.currency, "AED", "Should detect AED currency")
        XCTAssertNotNil(result.category, "Should extract category")
    }

    func testProcessCommandNumeric1000Dirhams() throws {
        // Ensure numeric "1000" works correctly (not parsed as 100)
        let command = "I just spent 1000 dirhams for Android phone"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 1000.0, accuracy: 0.01, "Should parse '1000' as 1000")
        XCTAssertEqual(result.currency, "AED", "Should detect AED currency")
    }

    func testProcessCommandFiveThousandDollars() throws {
        let command = "I spent five thousand dollars on electronics"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 5000.0, accuracy: 0.01, "Should parse 'five thousand' as 5000")
        XCTAssertEqual(result.currency, "USD", "Should detect USD currency")
    }

    func testProcessCommandTenThousandEuros() throws {
        let command = "I just paid ten thousand euros for the trip"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 10000.0, accuracy: 0.01, "Should parse 'ten thousand' as 10000")
        XCTAssertEqual(result.currency, "EUR", "Should detect EUR currency")
    }

    // MARK: - Thousands with Hundreds Tests

    func testProcessCommandTwoThousandFiveHundred() throws {
        let command = "I spent two thousand five hundred dirhams on shopping"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 2500.0, accuracy: 0.01, "Should parse 'two thousand five hundred' as 2500")
        XCTAssertEqual(result.currency, "AED", "Should detect AED currency")
    }

    func testProcessCommandTwentyFiveThousandThreeHundred() throws {
        let command = "I paid twenty five thousand three hundred dollars"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 25300.0, accuracy: 0.01, "Should parse complex number correctly")
        XCTAssertEqual(result.currency, "USD", "Should detect USD currency")
    }

    // MARK: - Indian Numbering System Tests

    func testProcessCommandOneLakhRupees() throws {
        let command = "I spent one lakh rupees on furniture"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 100000.0, accuracy: 0.01, "Should parse 'one lakh' as 100000")
        XCTAssertEqual(result.currency, "INR", "Should detect INR currency")
    }

    func testProcessCommandFiveLakhRupees() throws {
        let command = "I just spent five lakh rupees on the car"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 500000.0, accuracy: 0.01, "Should parse 'five lakh' as 500000")
        XCTAssertEqual(result.currency, "INR", "Should detect INR currency")
    }

    func testProcessCommandOneCroreRupees() throws {
        let command = "I paid one crore rupees for the property"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 10000000.0, accuracy: 0.01, "Should parse 'one crore' as 10000000")
        XCTAssertEqual(result.currency, "INR", "Should detect INR currency")
    }

    func testProcessCommandFiveLakhFiftyThousand() throws {
        let command = "I spent five lakh fifty thousand rupees"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 550000.0, accuracy: 0.01, "Should parse complex Indian number")
        XCTAssertEqual(result.currency, "INR", "Should detect INR currency")
    }

    // MARK: - Western Large Numbers Tests

    func testProcessCommandOneMillionDollars() throws {
        let command = "I spent one million dollars on the house"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 1000000.0, accuracy: 0.01, "Should parse 'one million' as 1000000")
        XCTAssertEqual(result.currency, "USD", "Should detect USD currency")
    }

    func testProcessCommandTwoPointFiveMillion() throws {
        let command = "I paid two point five million dollars"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 2500000.0, accuracy: 0.01, "Should parse decimal million")
        XCTAssertEqual(result.currency, "USD", "Should detect USD currency")
    }

    func testProcessCommandOneMillionTwoHundredThousand() throws {
        let command = "I spent one million two hundred thousand euros"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 1200000.0, accuracy: 0.01, "Should parse complex million")
        XCTAssertEqual(result.currency, "EUR", "Should detect EUR currency")
    }

    // MARK: - Hundreds Tests

    func testProcessCommandFiveHundredDirhams() throws {
        let command = "I spent five hundred dirhams on groceries"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 500.0, accuracy: 0.01, "Should parse 'five hundred' as 500")
        XCTAssertEqual(result.currency, "AED", "Should detect AED currency")
    }

    func testProcessCommandNineHundredNinetyNine() throws {
        let command = "I paid nine hundred ninety nine dollars"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 999.0, accuracy: 0.01, "Should parse complex hundred")
        XCTAssertEqual(result.currency, "USD", "Should detect USD currency")
    }

    // MARK: - Complex Real-World Scenarios

    func testProcessCommandWithMerchantAndCategory() throws {
        let command = "I just spent two thousand five hundred dirhams at Carrefour for groceries"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 2500.0, accuracy: 0.01, "Should parse complex amount")
        XCTAssertEqual(result.currency, "AED", "Should detect AED currency")
        XCTAssertNotNil(result.merchant, "Should extract merchant")
        XCTAssertNotNil(result.category, "Should extract category")
    }

    func testProcessCommandLongDescriptive() throws {
        let command = "I just spent five thousand dollars at the Apple Store on a new MacBook for work"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 5000.0, accuracy: 0.01, "Should parse from long command")
        XCTAssertEqual(result.currency, "USD", "Should detect USD currency")
        XCTAssertNotNil(result.merchant, "Should extract merchant")
    }

    // MARK: - Mixed Format Tests

    func testProcessCommandNumericFormat() throws {
        let testCases: [String: Double] = [
            "I spent 50 dirhams": 50,
            "I spent 500 dirhams": 500,
            "I spent 1000 dirhams": 1000,
            "I spent 5000 dirhams": 5000,
            "I spent 10000 dirhams": 10000,
            "I spent 25000 dirhams": 25000,
            "I spent 100000 dirhams": 100000
        ]

        for (command, expectedAmount) in testCases {
            let result = parser.parseExpenseCommand(command)
            XCTAssertNotNil(result.amount, "Should extract amount from: \(command)")
            XCTAssertEqual(result.amount!, expectedAmount, accuracy: 0.01, "Mismatch for: \(command)")
            XCTAssertEqual(result.currency, "AED", "Should detect AED for: \(command)")
        }
    }

    func testProcessCommandNumericWithCommas() throws {
        let command = "I spent 2,000 dirhams on electronics"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 2000.0, accuracy: 0.01, "Should parse numeric with commas")
        XCTAssertEqual(result.currency, "AED", "Should detect AED currency")
    }

    // MARK: - Decimal Tests

    func testProcessCommandDecimalWithPoint() throws {
        let command = "I spent five point five thousand dollars"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 5500.0, accuracy: 0.01, "Should parse decimal phrase (5.5 * 1000)")
        XCTAssertEqual(result.currency, "USD", "Should detect USD currency")
    }

    // MARK: - Small Numbers Tests

    func testProcessCommandTwentyFiveDollars() throws {
        let command = "I spent twenty five dollars on lunch"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 25.0, accuracy: 0.01, "Should parse 'twenty five' as 25")
        XCTAssertEqual(result.currency, "USD", "Should detect USD currency")
    }

    func testProcessCommandFiftyDirhams() throws {
        let command = "I paid fifty dirhams for gas"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 50.0, accuracy: 0.01, "Should parse 'fifty' as 50")
        XCTAssertEqual(result.currency, "AED", "Should detect AED currency")
    }

    // MARK: - Edge Cases

    func testProcessCommandNoAmount() throws {
        let command = "I went to the store"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNil(result.amount, "Should return nil amount when not present")
    }

    func testProcessCommandNoCurrency() throws {
        let command = "I spent 50 on groceries"

        let result = parser.parseExpenseCommand(command)

        XCTAssertNotNil(result.amount, "Should extract amount")
        XCTAssertEqual(result.amount!, 50.0, accuracy: 0.01, "Should parse amount")
        // Currency should fall back to default
        XCTAssertNotNil(result.currency, "Should have default currency")
    }

    func testProcessCommandCaseInsensitive() throws {
        let commands = [
            "I spent TWO THOUSAND dollars",
            "I spent Two Thousand Dollars",
            "I spent two thousand DOLLARS"
        ]

        for command in commands {
            let result = parser.parseExpenseCommand(command)
            XCTAssertNotNil(result.amount, "Should extract amount from: \(command)")
            XCTAssertEqual(result.amount!, 2000.0, accuracy: 0.01, "Should parse case-insensitively: \(command)")
            XCTAssertEqual(result.currency, "USD", "Should detect USD for: \(command)")
        }
    }

    // MARK: - Performance Tests

    func testParsingPerformanceSimple() throws {
        let command = "I spent two thousand dirhams on groceries"

        measure {
            for _ in 0..<100 {
                _ = parser.parseExpenseCommand(command)
            }
        }
    }

    func testParsingPerformanceComplex() throws {
        let command = "I just spent twenty five thousand three hundred dirhams at Sharaf DG for electronics"

        measure {
            for _ in 0..<100 {
                _ = parser.parseExpenseCommand(command)
            }
        }
    }

    func testParsingPerformanceNumeric() throws {
        let command = "I spent 25,300 dirhams on electronics"

        measure {
            for _ in 0..<100 {
                _ = parser.parseExpenseCommand(command)
            }
        }
    }
}
