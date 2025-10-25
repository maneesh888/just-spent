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

        // Try numeric patterns first (prioritize for performance)
        let patterns = [
            // Currency symbol formats: $25.50, $25, $1,234.56, $1000
            (#"\$(\d+(?:,\d{3})*(?:\.\d{1,2})?)"#, "USD"),

            // With currency name and decimals: 25.50 dollars, 1,234.56 dollars, 1000.50 dirhams
            (#"(\d+(?:,\d{3})*\.\d{1,2})\s*dollars?"#, "USD"),
            (#"(\d+(?:,\d{3})*\.\d{1,2})\s*(?:AED|aed|dirhams?)"#, "AED"),
            (#"(\d+(?:,\d{3})*\.\d{1,2})\s*euros?"#, "EUR"),
            (#"(\d+(?:,\d{3})*\.\d{1,2})\s*pounds?"#, "GBP"),
            (#"(\d+(?:,\d{3})*\.\d{1,2})\s*rupees?"#, "INR"),
            (#"(\d+(?:,\d{3})*\.\d{1,2})\s*riyals?"#, "SAR"),

            // With currency name (whole numbers): 25 dollars, 1000 dirhams, 1,234 dollars
            (#"(\d+(?:,\d{3})*)\s*dollars?"#, "USD"),
            (#"(\d+(?:,\d{3})*)\s*(?:AED|aed|dirhams?)"#, "AED"),
            (#"(\d+(?:,\d{3})*)\s*euros?"#, "EUR"),
            (#"(\d+(?:,\d{3})*)\s*pounds?"#, "GBP"),
            (#"(\d+(?:,\d{3})*)\s*rupees?"#, "INR"),
            (#"(\d+(?:,\d{3})*)\s*riyals?"#, "SAR"),

            // Plain numbers with decimals: 25.50, 1000.56, 1,234.56
            (#"(\d+(?:,\d{3})*\.\d{1,2})"#, "USD"),

            // Plain whole numbers: 25, 1000, 1,234
            (#"(\d+(?:,\d{3})*)"#, "USD")
        ]

        let range = NSRange(location: 0, length: command.count)

        for (pattern, curr) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: lowercased, options: [], range: range),
               let matchRange = Range(match.range(at: 1), in: lowercased) {
                let amountStr = String(lowercased[matchRange])
                    .replacingOccurrences(of: ",", with: "")
                if let parsedAmount = Double(amountStr) {
                    amount = parsedAmount
                    currency = curr
                    break // Use first successful match
                }
            }
        }

        // Use NumberPhraseParser for comprehensive written number extraction
        // Handles "two thousand", "five lakh", "two point five million", etc.
        if amount == nil,
           let parsedAmount = NumberPhraseParser.shared.extractAmountFromCommand(command) {
            amount = parsedAmount
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
