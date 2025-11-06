//
//  VoiceCurrencyDetector.swift
//  JustSpent
//
//  Created by Claude Code on 2025-10-19.
//  Utility for detecting currency from voice commands and text input
//

import Foundation

/// Utility for detecting currency from voice commands and text input
class VoiceCurrencyDetector {

    // MARK: - Singleton

    static let shared = VoiceCurrencyDetector()

    private init() {}

    // MARK: - Public Methods

    /// Detect currency from voice transcript or text input
    ///
    /// Supports:
    /// - ISO codes (USD, AED, EUR, etc.)
    /// - Currency symbols ($, د.إ, €, £, ₹, ﷼)
    /// - Spoken names (dollar, dirham, euro, pound, rupee, riyal)
    /// - Colloquial terms (buck, quid, etc.)
    ///
    /// - Parameters:
    ///   - text: Input text from voice or manual entry
    ///   - defaultCurrency: Fallback currency if no match found
    /// - Returns: Detected currency or default
    func detectCurrency(from text: String, default defaultCurrency: Currency = .usd) -> Currency {
        // First try the built-in detection from Currency model
        if let detected = Currency.detectFromText(text) {
            return detected
        }

        // Additional detection patterns for voice input
        let lowercasedText = text.lowercased()

        // Check for amount patterns with currency (e.g., "50 dollars", "$100")
        if let match = lowercasedText.range(of: #"(\d+\.?\d*)\s*([a-zA-Z\$€£₹₨﷼د.إ]+)"#, options: .regularExpression) {
            let matchedText = String(lowercasedText[match])
            if let currency = Currency.detectFromText(matchedText) {
                return currency
            }
        }

        // Check for currency at the end (e.g., "spent 50 in dollars")
        if let match = lowercasedText.range(of: #"in\s+([a-zA-Z]+)$"#, options: .regularExpression) {
            let matchedText = String(lowercasedText[match])
            if let currency = Currency.detectFromText(matchedText) {
                return currency
            }
        }

        // Return default if no currency detected
        return defaultCurrency
    }

    /// Extract amount and currency from voice command
    ///
    /// Examples:
    /// - "spent 50 dollars" → (50.0, USD)
    /// - "د.إ 100 for groceries" → (100.0, AED)
    /// - "paid 25.50 euros" → (25.50, EUR)
    ///
    /// - Parameters:
    ///   - text: Input text from voice command
    ///   - defaultCurrency: Fallback currency
    /// - Returns: Tuple of amount and currency, or nil if amount not found
    func extractAmountAndCurrency(
        from text: String,
        default defaultCurrency: Currency = .usd
    ) -> (amount: Decimal, currency: Currency)? {

        // Pattern: number followed by currency
        // Matches: "50 dollars", "100 dirhams", "$50", "د.إ 100", "₹20", "Rs 500"
        let patterns = [
            // Specific currency symbol patterns (highest priority)
            (#"₹\s*(\d+\.?\d*)"#, "INR"),         // ₹20, ₹ 500
            (#"₨\s*(\d+\.?\d*)"#, "INR"),         // ₨20, ₨ 500
            (#"[Rr]s\.?\s+(\d+\.?\d*)"#, "INR"),  // Rs 500, rs. 500 (with space)
            (#"\$(\d+\.?\d*)"#, "USD"),           // $50
            (#"€(\d+\.?\d*)"#, "EUR"),            // €50
            (#"£(\d+\.?\d*)"#, "GBP"),            // £50
            (#"د\.إ\s*(\d+\.?\d*)"#, "AED"),      // د.إ 100
            (#"﷼\s*(\d+\.?\d*)"#, "SAR"),         // ﷼100

            // Currency symbol after number
            (#"(\d+\.?\d*)\s*₹"#, "INR"),
            (#"(\d+\.?\d*)\s*₨"#, "INR"),
            (#"(\d+\.?\d*)\s+[Rr]s\.?"#, "INR"),  // 500 Rs, 500 rs.

            // Generic patterns (lower priority)
            (#"(\d+\.?\d*)\s*([a-zA-Z\$€£₹₨﷼د.إ]+)"#, nil),
            (#"([a-zA-Z\$€£₹₨﷼د.إ]+)\s*(\d+\.?\d*)"#, nil)
        ]

        for (pattern, explicitCurrency) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {

                // Extract amount from first capture group
                if match.numberOfRanges > 1,
                   let amountRange = Range(match.range(at: 1), in: text) {
                    let amountString = String(text[amountRange])
                    if let amount = Decimal(string: amountString) {

                        // Use explicit currency if provided (for specific symbol patterns)
                        if let currencyCode = explicitCurrency,
                           let currency = Currency(rawValue: currencyCode) {
                            return (amount: amount, currency: currency)
                        }

                        // Otherwise detect from matched text
                        let matchedText = String(text[Range(match.range, in: text)!])
                        let currency = detectCurrency(from: matchedText, default: defaultCurrency)
                        return (amount: amount, currency: currency)
                    }
                }
            }
        }

        // If no currency found, try to extract just the amount
        if let match = text.range(of: #"\d+\.?\d*"#, options: .regularExpression) {
            let amountString = String(text[match])
            if let amount = Decimal(string: amountString) {
                // Detect currency from the rest of the text
                let currency = detectCurrency(from: text, default: defaultCurrency)
                return (amount: amount, currency: currency)
            }
        }

        return nil
    }

    /// Check if text contains a currency mention
    ///
    /// - Parameter text: Input text
    /// - Returns: true if currency is mentioned, false otherwise
    func containsCurrency(_ text: String) -> Bool {
        return Currency.detectFromText(text) != nil
    }

    /// Replace currency symbols with ISO codes in text
    ///
    /// Useful for normalization before processing
    ///
    /// - Parameter text: Input text
    /// - Returns: Text with symbols replaced by codes
    func normalizeCurrencySymbols(in text: String) -> String {
        var normalized = text

        for currency in Currency.allCases {
            normalized = normalized.replacingOccurrences(of: currency.symbol, with: currency.rawValue)
        }

        return normalized
    }
}
