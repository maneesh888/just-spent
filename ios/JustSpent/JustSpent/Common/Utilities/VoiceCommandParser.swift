//
//  VoiceCommandParser.swift
//  JustSpent
//
//  Natural language processing utility for parsing voice commands into expense data
//

import Foundation

/// Result of parsing a voice command
struct ParsedExpenseData {
    let amount: Double?
    let currency: String?
    let category: String?
    let merchant: String?
}

/// Utility class for parsing natural language voice commands into structured expense data
class VoiceCommandParser {

    // MARK: - Singleton
    static let shared = VoiceCommandParser()

    private init() {}

    // MARK: - Public Methods

    /// Parse a voice command string into expense data
    /// - Parameter command: The natural language command from voice input
    /// - Returns: Parsed expense data with extracted amount, currency, category, and merchant
    func parseExpenseCommand(_ command: String) -> ParsedExpenseData {
        let lowercased = command.lowercased()

        // Extract amount and currency
        var amount: Double?
        var currency: String = AppConstants.Currency.defaultCurrency

        // Try numeric patterns first
        let patterns = [
            (#"(\d+(?:\.\d{1,2})?)\s*(?:dirhams?|aed)"#, "AED"),
            (#"(\d+(?:\.\d{1,2})?)\s*(?:dollars?|usd|\$)"#, "USD"),
            (#"(\d+(?:\.\d{1,2})?)\s*(?:euros?|eur|€)"#, "EUR"),
            (#"(\d+(?:\.\d{1,2})?)\s*(?:pounds?|gbp|£)"#, "GBP"),
            (#"(\d+(?:\.\d{1,2})?)"#, "USD") // Default fallback for just numbers
        ]

        let range = NSRange(location: 0, length: command.count)

        for (pattern, curr) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: lowercased, options: [], range: range) {
                let amountStr = String(lowercased[Range(match.range(at: 1), in: lowercased)!])
                if let parsedAmount = Double(amountStr) {
                    amount = parsedAmount
                    currency = curr
                    break // Use first successful match
                }
            }
        }

        // If numeric parsing failed, try written numbers
        if amount == nil {
            amount = extractWrittenAmount(from: lowercased)
            // Detect currency from context
            currency = detectCurrency(from: lowercased)
        }

        // Extract category
        let category = extractCategory(from: lowercased)

        // Extract merchant
        let merchant = extractMerchant(from: command, range: range)

        return ParsedExpenseData(
            amount: amount,
            currency: currency,
            category: category,
            merchant: merchant
        )
    }

    // MARK: - Private Methods

    /// Extract written numbers like "twenty-five dollars", "one hundred"
    private func extractWrittenAmount(from command: String) -> Double? {
        let ones: [String: Int] = [
            "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
            "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
            "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19
        ]

        let tens: [String: Int] = [
            "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50,
            "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90
        ]

        // Extract potential amount substring
        let actionPattern = "(spent|spend|paid|pay|cost)\\s+([\\w\\s]+?)\\s+(dollars?|dirhams?|aed|euros?|pounds?|for|on|at)"
        if let regex = try? NSRegularExpression(pattern: actionPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: command, options: [], range: NSRange(location: 0, length: command.count)),
           let amountRange = Range(match.range(at: 2), in: command) {
            let amountText = String(command[amountRange]).lowercased()
            return parseWrittenNumber(from: amountText, ones: ones, tens: tens)
        }

        // Fallback: try to parse the whole command
        return parseWrittenNumber(from: command, ones: ones, tens: tens)
    }

    /// Parse written number words into numeric value
    private func parseWrittenNumber(from text: String, ones: [String: Int], tens: [String: Int]) -> Double? {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var total = 0
        var current = 0

        for word in words {
            let cleanWord = word.lowercased()

            if let value = ones[cleanWord] {
                current += value
            } else if let value = tens[cleanWord] {
                current += value
            } else if cleanWord == "hundred" {
                if current == 0 { current = 1 }
                current *= 100
            } else if cleanWord == "thousand" {
                if current == 0 { current = 1 }
                current *= 1000
                total += current
                current = 0
            }
        }

        total += current
        return total > 0 && total <= 999999 ? Double(total) : nil
    }

    /// Detect currency from context words in the command
    private func detectCurrency(from command: String) -> String {
        if command.contains("dirham") || command.contains("aed") {
            return "AED"
        } else if command.contains("dollar") || command.contains("usd") {
            return "USD"
        } else if command.contains("euro") || command.contains("eur") {
            return "EUR"
        } else if command.contains("pound") || command.contains("gbp") {
            return "GBP"
        }
        return AppConstants.Currency.defaultCurrency
    }

    /// Extract expense category from command using keyword matching
    private func extractCategory(from command: String) -> String {
        for (keywords, categoryName) in AppConstants.CategoryKeywords.mappings {
            if keywords.contains(where: { command.contains($0) }) {
                return categoryName
                }
        }
        return AppConstants.Category.other // Default category
    }

    /// Extract merchant name from command
    private func extractMerchant(from command: String, range: NSRange) -> String? {
        let merchantPattern = #"(?:at|from)\s+([a-zA-Z\s]+?)(?:\s|$)"#
        let merchantRegex = try? NSRegularExpression(pattern: merchantPattern, options: [])

        if let match = merchantRegex?.firstMatch(in: command.lowercased(), options: [], range: range) {
            return String(command[Range(match.range(at: 1), in: command)!])
                .trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
}
