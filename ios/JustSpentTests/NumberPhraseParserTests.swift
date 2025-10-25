//
//  NumberPhraseParserTests.swift
//  JustSpentTests
//
//  Comprehensive tests for NumberPhraseParser
//  Tests basic numbers, hundreds, thousands, lakhs, crores, millions, billions, and decimals
//

import XCTest
@testable import JustSpent

final class NumberPhraseParserTests: XCTestCase {

    var parser: NumberPhraseParser!

    override func setUpWithError() throws {
        try super.setUpWithError()
        parser = NumberPhraseParser.shared
    }

    override func tearDownWithError() throws {
        parser = nil
        try super.tearDownWithError()
    }

    // MARK: - Basic Numbers Tests (0-19)

    func testParseBasicNumbersOnes() throws {
        let testCases: [String: Double] = [
            "zero": 0,
            "one": 1,
            "two": 2,
            "three": 3,
            "four": 4,
            "five": 5,
            "six": 6,
            "seven": 7,
            "eight": 8,
            "nine": 9
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    func testParseBasicNumbersTeens() throws {
        let testCases: [String: Double] = [
            "ten": 10,
            "eleven": 11,
            "twelve": 12,
            "thirteen": 13,
            "fourteen": 14,
            "fifteen": 15,
            "sixteen": 16,
            "seventeen": 17,
            "eighteen": 18,
            "nineteen": 19
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    // MARK: - Tens Numbers Tests (20-90)

    func testParseTensNumbers() throws {
        let testCases: [String: Double] = [
            "twenty": 20,
            "thirty": 30,
            "forty": 40,
            "fifty": 50,
            "sixty": 60,
            "seventy": 70,
            "eighty": 80,
            "ninety": 90
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    func testParseCompoundTensNumbers() throws {
        let testCases: [String: Double] = [
            "twenty one": 21,
            "twenty five": 25,
            "thirty two": 32,
            "forty seven": 47,
            "fifty nine": 59,
            "sixty eight": 68,
            "seventy three": 73,
            "eighty four": 84,
            "ninety nine": 99
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    // MARK: - Hundreds Tests

    func testParseHundredsBasic() throws {
        let testCases: [String: Double] = [
            "one hundred": 100,
            "hundred": 100,
            "two hundred": 200,
            "three hundred": 300,
            "five hundred": 500,
            "nine hundred": 900
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    func testParseHundredsWithTens() throws {
        let testCases: [String: Double] = [
            "one hundred twenty": 120,
            "two hundred fifty": 250,
            "three hundred thirty three": 333,
            "five hundred forty five": 545,
            "nine hundred ninety nine": 999
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    func testParseHundredsWithAnd() throws {
        let testCases: [String: Double] = [
            "one hundred and fifty": 150,
            "two hundred and twenty five": 225,
            "five hundred and fifty": 550
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    // MARK: - Thousands Tests

    func testParseThousandsBasic() throws {
        let testCases: [String: Double] = [
            "one thousand": 1000,
            "thousand": 1000,
            "two thousand": 2000, // USER'S BUG: Was parsing as 200
            "five thousand": 5000,
            "ten thousand": 10000,
            "twenty thousand": 20000,
            "fifty thousand": 50000,
            "ninety nine thousand": 99000
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    func testParseThousandsWithHundreds() throws {
        let testCases: [String: Double] = [
            "two thousand five hundred": 2500,
            "five thousand three hundred": 5300,
            "ten thousand two hundred": 10200,
            "twenty five thousand three hundred": 25300,
            "fifty thousand seven hundred fifty": 50750
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    func testParseHundredThousand() throws {
        let testCases: [String: Double] = [
            "one hundred thousand": 100000,
            "hundred thousand": 100000,
            "two hundred fifty thousand": 250000,
            "nine hundred ninety nine thousand": 999000
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    // MARK: - Indian Numbering System Tests

    func testParseLakhBasic() throws {
        let testCases: [String: Double] = [
            "one lakh": 100000,
            "lakh": 100000,
            "lac": 100000, // Alternative spelling
            "five lakh": 500000,
            "ten lakh": 1000000,
            "twenty lakh": 2000000,
            "fifty lakhs": 5000000 // Plural form
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    func testParseLakhWithThousands() throws {
        let testCases: [String: Double] = [
            "five lakh fifty thousand": 550000,
            "ten lakh twenty thousand": 1020000,
            "twenty lakh five thousand": 2005000
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    func testParseCroreBasic() throws {
        let testCases: [String: Double] = [
            "one crore": 10000000,
            "crore": 10000000,
            "five crore": 50000000,
            "ten crore": 100000000,
            "fifty crores": 500000000 // Plural form
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    // MARK: - Western Large Numbers Tests

    func testParseMillionBasic() throws {
        let testCases: [String: Double] = [
            "one million": 1000000,
            "million": 1000000,
            "two million": 2000000,
            "five million": 5000000,
            "ten million": 10000000,
            "fifty million": 50000000
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    func testParseMillionWithThousands() throws {
        let testCases: [String: Double] = [
            "one million two hundred thousand": 1200000,
            "five million five hundred thousand": 5500000,
            "ten million fifty thousand": 10050000
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    func testParseBillion() throws {
        let testCases: [String: Double] = [
            "one billion": 1000000000,
            "billion": 1000000000,
            "two billion": 2000000000,
            "five billion": 5000000000
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    func testParseTrillion() throws {
        let testCases: [String: Double] = [
            "one trillion": 1000000000000,
            "trillion": 1000000000000,
            "two trillion": 2000000000000
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    // MARK: - Decimal Numbers Tests

    func testParseDecimalBasic() throws {
        let testCases: [String: Double] = [
            "five point five": 5.5,
            "two point five": 2.5,
            "one point two five": 1.25,
            "three point one four": 3.14
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    func testParseDecimalWithScale() throws {
        let testCases: [String: Double] = [
            "two point five million": 2500000,
            "five point five thousand": 5500,
            "one point two million": 1200000,
            "three point five billion": 3500000000
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    // MARK: - Extract From Command Tests

    func testExtractAmountFromCommandSimple() throws {
        let commands: [String: Double] = [
            "I spent two thousand dirhams on groceries": 2000,
            "I just spent five lakh rupees on furniture": 500000,
            "I paid one million dollars for the house": 1000000,
            "I spent fifty dollars on lunch": 50
        ]

        for (command, expected) in commands {
            let result = parser.extractAmountFromCommand(command)
            XCTAssertNotNil(result, "Failed to extract from: \(command)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(command)")
        }
    }

    func testExtractAmountFromCommandComplex() throws {
        let commands: [String: Double] = [
            "I just spent twenty five thousand three hundred dirhams at Sharaf DG for electronics": 25300,
            "I paid two million five hundred thousand dollars for the property": 2500000
        ]

        for (command, expected) in commands {
            let result = parser.extractAmountFromCommand(command)
            XCTAssertNotNil(result, "Failed to extract from: \(command)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(command)")
        }
    }

    // MARK: - Numeric Extraction Tests

    func testExtractNumericSimple() throws {
        let testCases: [String: Double] = [
            "50": 50,
            "100": 100,
            "1000": 1000,
            "5000": 5000,
            "10000": 10000,
            "25000": 25000,
            "100000": 100000
        ]

        for (text, expected) in testCases {
            let result = parser.parse(text)
            XCTAssertNotNil(result, "Failed to parse: \(text)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(text)")
        }
    }

    func testExtractNumericWithCommas() throws {
        let testCases: [String: Double] = [
            "1,000": 1000,
            "10,000": 10000,
            "100,000": 100000,
            "1,000,000": 1000000
        ]

        for (text, expected) in testCases {
            let result = parser.parse(text)
            XCTAssertNotNil(result, "Failed to parse: \(text)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(text)")
        }
    }

    func testExtractNumericWithDecimals() throws {
        let testCases: [String: Double] = [
            "25.50": 25.50,
            "100.99": 100.99,
            "1000.00": 1000.00,
            "1,234.56": 1234.56
        ]

        for (text, expected) in testCases {
            let result = parser.parse(text)
            XCTAssertNotNil(result, "Failed to parse: \(text)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(text)")
        }
    }

    // MARK: - Edge Cases Tests

    func testParseEmptyString() throws {
        let result = parser.parse("")
        XCTAssertNil(result, "Should return nil for empty string")
    }

    func testParseInvalidPhrase() throws {
        let result = parser.parse("not a number phrase")
        XCTAssertNil(result, "Should return nil for invalid phrase")
    }

    func testParseOnlyConnectors() throws {
        let result = parser.parse("and and point")
        XCTAssertNil(result, "Should return nil for only connectors")
    }

    func testParseCaseInsensitive() throws {
        let testCases: [String: Double] = [
            "TWO THOUSAND": 2000,
            "Five Million": 5000000,
            "ONE HUNDRED": 100
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    func testParseWithHyphens() throws {
        let testCases: [String: Double] = [
            "twenty-five": 25,
            "fifty-five": 55,
            "ninety-nine": 99
        ]

        for (phrase, expected) in testCases {
            let result = parser.parse(phrase)
            XCTAssertNotNil(result, "Failed to parse: \(phrase)")
            XCTAssertEqual(result!, expected, accuracy: 0.01, "Mismatch for: \(phrase)")
        }
    }

    // MARK: - Contains Number Phrase Tests

    func testContainsNumberPhraseTrue() throws {
        let phrases = [
            "I spent two thousand dirhams",
            "five lakh rupees",
            "one million dollars"
        ]

        for phrase in phrases {
            XCTAssertTrue(parser.containsNumberPhrase(phrase), "Should detect number phrase in: \(phrase)")
        }
    }

    func testContainsNumberPhraseFalse() throws {
        let phrases = [
            "I went to the store",
            "groceries at carrefour",
            "lunch with friends"
        ]

        for phrase in phrases {
            XCTAssertFalse(parser.containsNumberPhrase(phrase), "Should not detect number phrase in: \(phrase)")
        }
    }

    // MARK: - Performance Tests

    func testParsingPerformance() throws {
        let phrases = [
            "two thousand",
            "five lakh",
            "one million",
            "twenty five thousand three hundred"
        ]

        measure {
            for _ in 0..<100 {
                for phrase in phrases {
                    _ = parser.parse(phrase)
                }
            }
        }
    }

    func testExtractionPerformance() throws {
        let command = "I just spent twenty five thousand three hundred dirhams at Sharaf DG for electronics"

        measure {
            for _ in 0..<100 {
                _ = parser.extractAmountFromCommand(command)
            }
        }
    }
}
