//
//  Currency.swift
//  JustSpent
//
//  Created by Claude Code on 2025-10-19.
//  Comprehensive currency model with metadata and utilities
//  Now loads from shared currencies.json for easy updates
//

import Foundation

/// Represents a currency in the Just Spent application
/// Loaded dynamically from currencies.json for flexibility and easy updates
struct Currency: Codable, Identifiable, Hashable {
    let code: String
    let symbol: String
    let displayName: String
    let shortName: String
    let localeIdentifier: String
    let isRTL: Bool
    let voiceKeywords: [String]

    // MARK: - Identifiable
    var id: String { code }

    // MARK: - Computed Properties

    /// Locale object for formatting operations
    var locale: Locale {
        return Locale(identifier: localeIdentifier)
    }

    /// Number of decimal places for this currency
    var decimalPlaces: Int {
        return 2
    }

    /// Decimal separator character
    var decimalSeparator: String {
        return "."
    }

    /// Thousands grouping separator
    var groupingSeparator: String {
        return ","
    }

    // MARK: - Currency Loading

    /// Cached currencies loaded from JSON
    private static var _allCurrencies: [Currency]?

    /// Initialize the currency system
    /// Should be called once during app initialization
    static func initialize() {
        if _allCurrencies == nil {
            print("🔄 Currency: Starting initialization...")
            _allCurrencies = CurrencyLoader.loadCurrencies()
            print("🔄 Currency: Initialization complete. Loaded \(_allCurrencies?.count ?? 0) currencies")
        } else {
            print("⚠️ Currency: Already initialized with \(_allCurrencies?.count ?? 0) currencies")
        }
    }

    /// All supported currencies
    static var all: [Currency] {
        if _allCurrencies == nil {
            initialize()
        }
        return _allCurrencies ?? []
    }

    /// Commonly used currencies (for onboarding UI)
    static var common: [Currency] {
        let commonCodes = ["AED", "USD", "EUR", "GBP", "INR", "SAR", "JPY"]
        return all.filter { commonCodes.contains($0.code) }
    }

    /// Default currency for new users (based on device locale)
    static var `default`: Currency {
        let deviceLocale = Locale.current
        let currencyCode = deviceLocale.currencyCode?.uppercased() ?? "USD"

        return from(isoCode: currencyCode) ?? from(isoCode: "USD")!
    }

    /// Create currency from ISO code string
    /// - Parameter code: ISO 4217 currency code
    /// - Returns: Currency struct or nil if invalid
    static func from(isoCode code: String) -> Currency? {
        return all.first { $0.code.uppercased() == code.uppercased() }
    }

    /// Detect currency from text input (voice commands, manual entry)
    /// - Parameter text: Input text to analyze
    /// - Returns: Detected currency or nil if no match found
    static func detectFromText(_ text: String) -> Currency? {
        let lowercasedText = text.lowercased()

        for currency in all {
            for keyword in currency.voiceKeywords {
                if lowercasedText.contains(keyword.lowercased()) {
                    return currency
                }
            }
        }

        return nil
    }

    // MARK: - Legacy Accessors for Backward Compatibility

    static var aed: Currency { from(isoCode: "AED")! }
    static var usd: Currency { from(isoCode: "USD")! }
    static var eur: Currency { from(isoCode: "EUR")! }
    static var gbp: Currency { from(isoCode: "GBP")! }
    static var inr: Currency { from(isoCode: "INR")! }
    static var sar: Currency { from(isoCode: "SAR")! }
}

// MARK: - CustomStringConvertible

extension Currency: CustomStringConvertible {
    var description: String {
        return "\(symbol) \(code)"
    }
}

// MARK: - Comparable

extension Currency: Comparable {
    static func < (lhs: Currency, rhs: Currency) -> Bool {
        return lhs.displayName < rhs.displayName
    }
}

// MARK: - Internal Loading Mechanism

/// Internal data structure for JSON parsing
private struct CurrenciesData: Codable {
    let version: String
    let lastUpdated: String
    let currencies: [Currency]
}

/// Utility object to load currencies from JSON resource file
private struct CurrencyLoader {
    static func loadCurrencies() -> [Currency] {
        print("📂 Currency: Searching for currencies.json...")

        let fileManager = FileManager.default
        var jsonURL: URL?

        // 1. Try from current working directory and relative paths (works in tests and CI)
        let currentDirPath = fileManager.currentDirectoryPath
        let possiblePaths = [
            "\(currentDirPath)/shared/currencies.json",        // From project root
            "\(currentDirPath)/../shared/currencies.json",     // From ios/ directory
            "\(currentDirPath)/../../shared/currencies.json"   // From ios/JustSpent/ directory
        ]

        for path in possiblePaths {
            if fileManager.fileExists(atPath: path) {
                jsonURL = URL(fileURLWithPath: path)
                print("✅ Currency: Found currencies.json in shared folder (from current dir: \(path))")
                break
            }
        }

        // 2. Try searching up from bundle path to find project root (works in simulator)
        if jsonURL == nil {
            jsonURL = findCurrencyFileFromBundle(fileManager: fileManager)
        }

        // 3. Fallback: load from bundle (production build with file added to Xcode)
        if jsonURL == nil {
            jsonURL = Bundle.main.url(forResource: "currencies", withExtension: "json")
            if jsonURL != nil {
                print("✅ Currency: Found currencies.json in app bundle")
            }
        }

        guard let url = jsonURL else {
            print("❌ Currency: currencies.json NOT FOUND in any location")
            print("   Searched: shared folder, bundle path, and app bundle")
            print("📂 Currency: Bundle path: \(Bundle.main.bundlePath)")
            print("📂 Currency: Current dir: \(currentDirPath)")
            return []
        }

        print("✅ Currency: Loading from: \(url.path)")

        do {
            let data = try Data(contentsOf: url)
            print("📊 Currency: JSON file size: \(data.count) bytes")

            let decoder = JSONDecoder()
            let currenciesData = try decoder.decode(CurrenciesData.self, from: data)
            print("✅ Currency: Successfully decoded JSON")
            print("✅ Currency: Loaded \(currenciesData.currencies.count) currencies from JSON (version \(currenciesData.version))")
            print("✅ Currency: Sample currencies: \(currenciesData.currencies.prefix(3).map { $0.code }.joined(separator: ", "))")
            return currenciesData.currencies
        } catch let decodingError as DecodingError {
            print("❌ Currency: JSON DECODING ERROR: \(decodingError)")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("   Missing key: \(key.stringValue) at \(context.codingPath)")
            case .typeMismatch(let type, let context):
                print("   Type mismatch for type: \(type) at \(context.codingPath)")
            case .valueNotFound(let type, let context):
                print("   Value not found for type: \(type) at \(context.codingPath)")
            case .dataCorrupted(let context):
                print("   Data corrupted at \(context.codingPath): \(context.debugDescription)")
            @unknown default:
                print("   Unknown decoding error")
            }
            return []
        } catch {
            print("❌ Currency: Failed to load currencies from JSON: \(error)")
            return []
        }
    }

    /// Search for project root by looking for shared/currencies.json
    private static func findCurrencyFileFromBundle(fileManager: FileManager) -> URL? {
        let bundlePath = Bundle.main.bundlePath

        var currentPath = (bundlePath as NSString).deletingLastPathComponent

        // Search up to 10 levels to find project root
        for _ in 0..<10 {
            let sharedPath = (currentPath as NSString).appendingPathComponent("shared/currencies.json")
            if fileManager.fileExists(atPath: sharedPath) {
                print("✅ Currency: Found currencies.json in shared folder (from bundle path)")
                return URL(fileURLWithPath: sharedPath)
            }

            // Go up one level
            let parentPath = (currentPath as NSString).deletingLastPathComponent
            if parentPath == currentPath {
                break // Reached root
            }
            currentPath = parentPath
        }

        return nil
    }
}
