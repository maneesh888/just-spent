//
//  CurrencyFormatter.swift
//  JustSpent
//
//  Created by Claude Code on 2025-10-19.
//  Currency formatting utilities with locale-aware display
//

import Foundation

/// Provides currency formatting with proper locale support and customization
class CurrencyFormatter {

    // MARK: - Singleton

    static let shared = CurrencyFormatter()

    private init() {}

    // MARK: - Public Formatting Methods

    /// Format amount with currency symbol and locale-aware number formatting
    /// - Parameters:
    ///   - amount: The monetary amount to format
    ///   - currency: The currency to use for formatting
    ///   - showSymbol: Whether to include the currency symbol (default: true)
    ///   - showCode: Whether to include the currency code (default: false)
    /// - Returns: Formatted currency string (e.g., "د.إ 100.00", "$50.25")
    func format(
        amount: Decimal,
        currency: Currency,
        showSymbol: Bool = true,
        showCode: Bool = false
    ) -> String {
        let formatter = createFormatter(for: currency)

        formatter.currencySymbol = showSymbol ? currency.symbol : ""
        formatter.currencyCode = currency.code

        guard let formattedString = formatter.string(from: amount as NSDecimalNumber) else {
            // Fallback to basic formatting
            return basicFormat(amount: amount, currency: currency, showSymbol: showSymbol)
        }

        // Add currency code if requested
        if showCode && !showSymbol {
            return "\(formattedString) \(currency.code)"
        } else if showCode && showSymbol {
            return "\(formattedString) (\(currency.code))"
        }

        return formattedString
    }

    /// Format amount for compact display (e.g., in lists)
    /// - Parameters:
    ///   - amount: The monetary amount to format
    ///   - currency: The currency to use for formatting
    /// - Returns: Compact formatted string
    func formatCompact(amount: Decimal, currency: Currency) -> String {
        return format(amount: amount, currency: currency, showSymbol: true, showCode: false)
    }

    /// Format amount for detailed display (e.g., in forms, detail views)
    /// - Parameters:
    ///   - amount: The monetary amount to format
    ///   - currency: The currency to use for formatting
    /// - Returns: Detailed formatted string with currency code
    func formatDetailed(amount: Decimal, currency: Currency) -> String {
        return format(amount: amount, currency: currency, showSymbol: true, showCode: true)
    }

    /// Parse currency string to Decimal amount
    /// - Parameters:
    ///   - string: String to parse (e.g., "د.إ 100", "$50.25")
    ///   - currency: Currency context for parsing
    /// - Returns: Parsed Decimal value or nil if parsing fails
    func parse(string: String, currency: Currency) -> Decimal? {
        let formatter = createFormatter(for: currency)

        // Remove all currency symbols and codes (supports 160+ currencies)
        var cleanedString = string
        for curr in Currency.all {
            cleanedString = cleanedString.replacingOccurrences(of: curr.symbol, with: "")
            cleanedString = cleanedString.replacingOccurrences(of: curr.code, with: "")
        }
        cleanedString = cleanedString.trimmingCharacters(in: .whitespaces)

        // Try parsing with the formatter
        if let number = formatter.number(from: cleanedString) {
            return Decimal(string: number.stringValue)
        }

        // Fallback: try direct Decimal conversion
        return Decimal(string: cleanedString)
    }

    // MARK: - Private Helper Methods

    /// Create a NumberFormatter configured for the specified currency
    /// - Parameter currency: The currency to configure for
    /// - Returns: Configured NumberFormatter
    private func createFormatter(for currency: Currency) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = currency.locale
        formatter.currencyCode = currency.code
        formatter.currencySymbol = currency.symbol
        formatter.minimumFractionDigits = currency.decimalPlaces
        formatter.maximumFractionDigits = currency.decimalPlaces

        return formatter
    }

    /// Basic formatting fallback when NumberFormatter fails
    /// - Parameters:
    ///   - amount: The amount to format
    ///   - currency: The currency
    ///   - showSymbol: Whether to show symbol
    /// - Returns: Basic formatted string
    private func basicFormat(
        amount: Decimal,
        currency: Currency,
        showSymbol: Bool
    ) -> String {
        let amountString = String(format: "%.2f", NSDecimalNumber(decimal: amount).doubleValue)

        if showSymbol {
            if currency.isRTL {
                return "\(currency.symbol) \(amountString)"
            } else {
                return "\(currency.symbol)\(amountString)"
            }
        }

        return amountString
    }
}

// MARK: - Decimal Extension

extension Decimal {
    /// Format this decimal as currency
    /// - Parameter currency: Currency to use for formatting
    /// - Returns: Formatted string
    func formatted(as currency: Currency) -> String {
        return CurrencyFormatter.shared.format(amount: self, currency: currency)
    }

    /// Format this decimal compactly
    /// - Parameter currency: Currency to use for formatting
    /// - Returns: Compact formatted string
    func formattedCompact(as currency: Currency) -> String {
        return CurrencyFormatter.shared.formatCompact(amount: self, currency: currency)
    }

    /// Format this decimal with full details
    /// - Parameter currency: Currency to use for formatting
    /// - Returns: Detailed formatted string
    func formattedDetailed(as currency: Currency) -> String {
        return CurrencyFormatter.shared.formatDetailed(amount: self, currency: currency)
    }
}

// MARK: - String Extension

extension String {
    /// Parse this string as a currency amount
    /// - Parameter currency: Currency context for parsing
    /// - Returns: Parsed Decimal or nil
    func parsedAsCurrency(using currency: Currency) -> Decimal? {
        return CurrencyFormatter.shared.parse(string: self, currency: currency)
    }
}
