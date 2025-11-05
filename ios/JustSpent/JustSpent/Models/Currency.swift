//
//  Currency.swift
//  JustSpent
//
//  Created by Claude Code on 2025-10-19.
//  Comprehensive currency model with metadata and utilities
//

import Foundation

/// Represents supported currencies in the Just Spent application
/// Follows ISO 4217 standards with extended metadata for localization and display
enum Currency: String, CaseIterable, Codable {
    case aed = "AED"  // UAE Dirham
    case usd = "USD"  // US Dollar
    case eur = "EUR"  // Euro
    case gbp = "GBP"  // British Pound
    case inr = "INR"  // Indian Rupee
    case sar = "SAR"  // Saudi Riyal

    // MARK: - Display Properties

    /// Currency symbol for display (e.g., "$", "د.إ")
    var symbol: String {
        switch self {
        case .aed: return "د.إ"
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .inr: return "₹"
        case .sar: return "﷼"
        }
    }

    /// Localized currency name in English
    var displayName: String {
        switch self {
        case .aed: return "UAE Dirham"
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .inr: return "Indian Rupee"
        case .sar: return "Saudi Riyal"
        }
    }

    /// Short display name for compact views
    var shortName: String {
        switch self {
        case .aed: return "Dirham"
        case .usd: return "Dollar"
        case .eur: return "Euro"
        case .gbp: return "Pound"
        case .inr: return "Rupee"
        case .sar: return "Riyal"
        }
    }

    /// Locale identifier for proper number formatting
    var localeIdentifier: String {
        switch self {
        case .aed: return "ar_AE"
        case .usd: return "en_US"
        case .eur: return "en_DE"  // Using German format for Euro
        case .gbp: return "en_GB"
        case .inr: return "en_IN"
        case .sar: return "ar_SA"
        }
    }

    /// Locale object for formatting operations
    var locale: Locale {
        return Locale(identifier: localeIdentifier)
    }

    /// Whether this currency uses right-to-left text direction
    var isRTL: Bool {
        switch self {
        case .aed, .sar:
            return true
        default:
            return false
        }
    }

    // MARK: - Voice Recognition Keywords

    /// Keywords for voice command detection (symbols, names, colloquial terms)
    var voiceKeywords: [String] {
        switch self {
        case .aed:
            return ["aed", "dirham", "dirhams", "د.إ", "dhs", "emirati dirham"]
        case .usd:
            return ["usd", "dollar", "dollars", "$", "buck", "bucks", "us dollar"]
        case .eur:
            return ["eur", "euro", "euros", "€"]
        case .gbp:
            return ["gbp", "pound", "pounds", "£", "quid", "sterling", "british pound"]
        case .inr:
            return ["inr", "rupee", "rupees", "₹", "rs", "rs.", "₨", "indian rupee"]
        case .sar:
            return ["sar", "riyal", "riyals", "﷼", "saudi riyal"]
        }
    }

    // MARK: - Formatting Configuration

    /// Number of decimal places for this currency
    var decimalPlaces: Int {
        // All supported currencies use 2 decimal places
        return 2
    }

    /// Decimal separator character
    var decimalSeparator: String {
        return locale.decimalSeparator ?? "."
    }

    /// Thousands grouping separator
    var groupingSeparator: String {
        return locale.groupingSeparator ?? ","
    }

    // MARK: - Static Utilities

    /// Default currency for new users (based on device locale)
    static var `default`: Currency {
        let deviceLocale = Locale.current
        let currencyCode = deviceLocale.currencyCode?.uppercased() ?? "USD"

        return Currency(rawValue: currencyCode) ?? .usd
    }

    /// Detect currency from text input (voice commands, manual entry)
    /// - Parameter text: Input text to analyze
    /// - Returns: Detected currency or nil if no match found
    static func detectFromText(_ text: String) -> Currency? {
        let lowercasedText = text.lowercased()

        for currency in Currency.allCases {
            for keyword in currency.voiceKeywords {
                if lowercasedText.contains(keyword.lowercased()) {
                    return currency
                }
            }
        }

        return nil
    }

    /// Create currency from ISO code string
    /// - Parameter code: ISO 4217 currency code
    /// - Returns: Currency enum or nil if invalid
    static func from(isoCode code: String) -> Currency? {
        return Currency(rawValue: code.uppercased())
    }
}

// MARK: - CustomStringConvertible

extension Currency: CustomStringConvertible {
    var description: String {
        return "\(symbol) \(rawValue)"
    }
}

// MARK: - Identifiable

extension Currency: Identifiable {
    var id: String {
        return rawValue
    }
}

// MARK: - Comparable

extension Currency: Comparable {
    static func < (lhs: Currency, rhs: Currency) -> Bool {
        return lhs.displayName < rhs.displayName
    }
}
