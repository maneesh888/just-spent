//
//  Currency.swift
//  JustSpent
//
//  Created by Claude Code on 2025-10-19.
//  Comprehensive currency model with JSON loading
//

import Foundation

/// Represents a currency in the Just Spent application
/// Follows ISO 4217 standards with extended metadata for localization and display
struct Currency: Codable, Identifiable, Hashable, Comparable {

    // MARK: - Properties

    let code: String
    let symbol: String
    let displayName: String
    let pluralName: String
    let symbolPosition: String
    let decimalSeparator: String
    let groupingSeparator: String
    let decimalPlaces: Int
    let isCommon: Bool
    let voiceKeywords: [String]
    let countryCodes: [String]
    let exampleFormat: String

    // MARK: - Codable Keys

    enum CodingKeys: String, CodingKey {
        case code
        case symbol
        case displayName = "display_name"
        case pluralName = "plural_name"
        case symbolPosition = "symbol_position"
        case decimalSeparator = "decimal_separator"
        case groupingSeparator = "grouping_separator"
        case decimalPlaces = "decimal_places"
        case isCommon = "is_common"
        case voiceKeywords = "voice_keywords"
        case countryCodes = "country_codes"
        case exampleFormat = "example_format"
    }

    // MARK: - Identifiable

    var id: String { code }

    // MARK: - Computed Properties

    /// Localized currency name in English (alias for displayName)
    var name: String { displayName }

    /// Short display name for compact views
    var shortName: String {
        // Extract the first word or use full name if too short
        let components = displayName.components(separatedBy: " ")
        return components.last ?? displayName
    }

    /// Whether this currency uses right-to-left text direction
    var isRTL: Bool {
        return code == "AED" || code == "SAR" || code == "BHD" || code == "KWD" || code == "OMR" || code == "QAR"
    }

    /// Raw value for compatibility with enum-based code
    var rawValue: String { code }

    // MARK: - Static Properties

    /// All available currencies loaded from JSON
    private static var _allCurrencies: [Currency] = []

    /// All available currencies
    static var allCases: [Currency] {
        if _allCurrencies.isEmpty {
            loadCurrencies()
        }
        return _allCurrencies
    }

    /// Common currencies (for quick access in onboarding)
    static var commonCurrencies: [Currency] {
        return allCases.filter { $0.isCommon }.sorted { $0.displayName < $1.displayName }
    }

    // MARK: - Predefined Common Currencies

    static var AED: Currency { allCases.first { $0.code == "AED" } ?? fallbackCurrency }
    static var USD: Currency { allCases.first { $0.code == "USD" } ?? fallbackCurrency }
    static var EUR: Currency { allCases.first { $0.code == "EUR" } ?? fallbackCurrency }
    static var GBP: Currency { allCases.first { $0.code == "GBP" } ?? fallbackCurrency }
    static var INR: Currency { allCases.first { $0.code == "INR" } ?? fallbackCurrency }
    static var SAR: Currency { allCases.first { $0.code == "SAR" } ?? fallbackCurrency }
    static var JPY: Currency { allCases.first { $0.code == "JPY" } ?? fallbackCurrency }
    static var CNY: Currency { allCases.first { $0.code == "CNY" } ?? fallbackCurrency }
    static var AUD: Currency { allCases.first { $0.code == "AUD" } ?? fallbackCurrency }
    static var CAD: Currency { allCases.first { $0.code == "CAD" } ?? fallbackCurrency }

    /// Fallback currency if JSON loading fails
    private static var fallbackCurrency: Currency {
        return Currency(
            code: "USD",
            symbol: "$",
            displayName: "US Dollar",
            pluralName: "US Dollars",
            symbolPosition: "before",
            decimalSeparator: ".",
            groupingSeparator: ",",
            decimalPlaces: 2,
            isCommon: true,
            voiceKeywords: ["dollar", "dollars", "usd", "$"],
            countryCodes: ["US"],
            exampleFormat: "$1,234.56"
        )
    }

    // MARK: - JSON Loading

    /// Load currencies from JSON file
    private static func loadCurrencies() {
        guard let url = Bundle.main.url(forResource: "currencies", withExtension: "json") else {
            print("❌ Currency JSON file not found in bundle")
            _allCurrencies = [fallbackCurrency]
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            guard let currenciesDict = jsonObject?["currencies"] as? [String: [String: Any]] else {
                print("❌ Invalid JSON structure")
                _allCurrencies = [fallbackCurrency]
                return
            }

            var currencies: [Currency] = []

            for (_, currencyData) in currenciesDict {
                guard let code = currencyData["code"] as? String,
                      let symbol = currencyData["symbol"] as? String,
                      let displayName = currencyData["display_name"] as? String,
                      let pluralName = currencyData["plural_name"] as? String,
                      let symbolPosition = currencyData["symbol_position"] as? String,
                      let decimalSeparator = currencyData["decimal_separator"] as? String,
                      let groupingSeparator = currencyData["grouping_separator"] as? String,
                      let decimalPlaces = currencyData["decimal_places"] as? Int,
                      let isCommon = currencyData["is_common"] as? Bool,
                      let voiceKeywords = currencyData["voice_keywords"] as? [String],
                      let countryCodes = currencyData["country_codes"] as? [String],
                      let exampleFormat = currencyData["example_format"] as? String else {
                    continue
                }

                let currency = Currency(
                    code: code,
                    symbol: symbol,
                    displayName: displayName,
                    pluralName: pluralName,
                    symbolPosition: symbolPosition,
                    decimalSeparator: decimalSeparator,
                    groupingSeparator: groupingSeparator,
                    decimalPlaces: decimalPlaces,
                    isCommon: isCommon,
                    voiceKeywords: voiceKeywords,
                    countryCodes: countryCodes,
                    exampleFormat: exampleFormat
                )

                currencies.append(currency)
            }

            // Sort by display name
            _allCurrencies = currencies.sorted { $0.displayName < $1.displayName }

            print("✅ Loaded \(_allCurrencies.count) currencies from JSON")

        } catch {
            print("❌ Failed to load currencies from JSON: \(error)")
            _allCurrencies = [fallbackCurrency]
        }
    }

    // MARK: - Static Utilities

    /// Default currency for new users (based on device locale)
    static var `default`: Currency {
        let deviceLocale = Locale.current
        let currencyCode = deviceLocale.currencyCode?.uppercased() ?? "USD"

        return from(isoCode: currencyCode) ?? USD
    }

    /// Detect currency from text input (voice commands, manual entry)
    /// - Parameter text: Input text to analyze
    /// - Returns: Detected currency or nil if no match found
    static func detectFromText(_ text: String) -> Currency? {
        let lowercasedText = text.lowercased()

        for currency in allCases {
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
    /// - Returns: Currency or nil if invalid
    static func from(isoCode code: String) -> Currency? {
        return allCases.first { $0.code.uppercased() == code.uppercased() }
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    static func == (lhs: Currency, rhs: Currency) -> Bool {
        return lhs.code == rhs.code
    }

    // MARK: - Comparable

    static func < (lhs: Currency, rhs: Currency) -> Bool {
        return lhs.displayName < rhs.displayName
    }
}

// MARK: - CustomStringConvertible

extension Currency: CustomStringConvertible {
    var description: String {
        return "\(symbol) \(code)"
    }
}
