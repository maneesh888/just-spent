//
//  NumberPhraseParser.swift
//  JustSpent
//
//  Comprehensive number phrase parser for voice commands
//  Supports basic numbers, hundreds, thousands, lakhs, crores, millions, billions, trillions, and decimals
//

import Foundation

/// Comprehensive number phrase parser for converting spoken numbers to numeric values
class NumberPhraseParser {

    // MARK: - Singleton
    static let shared = NumberPhraseParser()

    private init() {}

    // MARK: - Number Dictionaries

    private let basicNumbers: [String: Double] = [
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4,
        "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9,
        "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14,
        "fifteen": 15, "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19
    ]

    private let tensNumbers: [String: Double] = [
        "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50,
        "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90
    ]

    private let scaleNumbers: [String: Double] = [
        "hundred": 100,
        "thousand": 1_000,
        "lakh": 100_000, "lac": 100_000, "lakhs": 100_000, "lacs": 100_000,
        "million": 1_000_000,
        "crore": 10_000_000, "crores": 10_000_000,
        "billion": 1_000_000_000,
        "trillion": 1_000_000_000_000
    ]

    // MARK: - Public Methods

    /// Parse a number phrase and return the numeric value
    /// - Parameter text: The text containing a number phrase
    /// - Returns: The numeric value as a Double, or nil if parsing fails
    func parse(_ text: String) -> Double? {
        let normalizedText = normalizeText(text)

        // Try numeric extraction first (fast path)
        if let numericAmount = extractNumericAmount(normalizedText) {
            return numericAmount
        }

        // Fall back to written number parsing
        return parseWrittenNumber(normalizedText)
    }

    /// Extract amount from a voice command string
    /// - Parameter command: The voice command containing an amount
    /// - Returns: The extracted amount as Double, or nil if not found
    func extractAmountFromCommand(_ command: String) -> Double? {
        let normalizedCommand = normalizeText(command)

        // Patterns to extract amount substring from common voice command structures
        let amountPatterns = [
            #"(?:spent|spend|paid|pay|cost)\s+(.*?)\s+(?:dollars?|dirhams?|euros?|pounds?|rupees?|riyals?|aed|usd|eur|gbp|inr|sar)"#,
            #"(?:spent|spend|paid|pay|cost)\s+(.*?)\s+(?:on|for|at)"#,
            #"^(.*?)\s+(?:for|on|at)"#
        ]

        for patternString in amountPatterns {
            guard let regex = try? NSRegularExpression(pattern: patternString, options: .caseInsensitive) else {
                continue
            }

            let range = NSRange(location: 0, length: normalizedCommand.utf16.count)
            if let match = regex.firstMatch(in: normalizedCommand, options: [], range: range),
               let matchRange = Range(match.range(at: 1), in: normalizedCommand) {
                let amountText = String(normalizedCommand[matchRange])
                if let amount = parse(amountText) {
                    return amount
                }
            }
        }

        // Fallback: try parsing the whole command
        return parse(normalizedCommand)
    }

    /// Check if text contains number phrases
    /// - Parameter text: The text to check
    /// - Returns: True if number phrases are detected
    func containsNumberPhrase(_ text: String) -> Bool {
        let normalizedText = normalizeText(text)
        let words = normalizedText.components(separatedBy: .whitespaces)

        for word in words {
            if basicNumbers[word] != nil ||
               tensNumbers[word] != nil ||
               scaleNumbers[word] != nil {
                return true
            }
        }

        return false
    }

    // MARK: - Private Methods

    /// Normalize text for parsing (lowercase, trim, clean)
    private func normalizeText(_ text: String) -> String {
        var normalized = text.lowercased()

        // Replace hyphens with spaces for consistency
        normalized = normalized.replacingOccurrences(of: "-", with: " ")

        // Remove extra whitespace
        normalized = normalized.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return normalized
    }

    /// Extract numeric amount from text (e.g., "123", "1,234.56")
    private func extractNumericAmount(_ text: String) -> Double? {
        // Patterns ordered by specificity
        let patterns = [
            #"(\d+(?:,\d{3})*(?:\.\d{1,2})?)"#, // With thousand separators and decimals
            #"(\d+\.\d{1,2})"#,                   // Simple decimals
            #"(\d+)"#                              // Simple integers
        ]

        for patternString in patterns {
            guard let regex = try? NSRegularExpression(pattern: patternString, options: []) else {
                continue
            }

            let range = NSRange(location: 0, length: text.utf16.count)
            if let match = regex.firstMatch(in: text, options: [], range: range),
               let matchRange = Range(match.range(at: 1), in: text) {
                let numberString = String(text[matchRange])
                    .replacingOccurrences(of: ",", with: "")

                if let amount = Double(numberString) {
                    return amount
                }
            }
        }

        return nil
    }

    /// Parse written number from text (e.g., "two thousand five hundred")
    private func parseWrittenNumber(_ text: String) -> Double? {
        let words = text.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty && $0 != "and" } // Remove "and" connectors

        var total: Double = 0
        var current: Double = 0
        var decimalMode = false
        var decimalPlaces: [Double] = []

        for word in words {
            let cleanWord = word.lowercased()

            // Handle decimal point
            if cleanWord == "point" || cleanWord == "dot" {
                decimalMode = true
                continue
            }

            // Process decimal digits after "point"
            if decimalMode {
                if let digitValue = basicNumbers[cleanWord] {
                    decimalPlaces.append(digitValue)
                    continue
                } else {
                    // Exit decimal mode if non-digit word encountered
                    decimalMode = false
                }
            }

            // Process basic numbers (0-19)
            if let value = basicNumbers[cleanWord] {
                current += value
                continue
            }

            // Process tens (20, 30, ..., 90)
            if let value = tensNumbers[cleanWord] {
                current += value
                continue
            }

            // Process scale multipliers (hundred, thousand, million, etc.)
            if let scale = scaleNumbers[cleanWord] {
                if current == 0 {
                    current = 1 // Implicit "one" before scale (e.g., "thousand" = "one thousand")
                }

                if scale == 100 {
                    // Hundred: multiply current value
                    current *= scale
                } else {
                    // Thousand and above: multiply and add to total, reset current
                    current *= scale
                    total += current
                    current = 0
                }
                continue
            }
        }

        // Add any remaining current value to total
        total += current

        // Apply decimal places if any
        if !decimalPlaces.isEmpty {
            var decimalValue = 0.0
            var divisor = 10.0

            for digit in decimalPlaces {
                decimalValue += digit / divisor
                divisor *= 10
            }

            total += decimalValue
        }

        // Return nil if no valid number was parsed
        return total > 0 ? total : nil
    }
}
