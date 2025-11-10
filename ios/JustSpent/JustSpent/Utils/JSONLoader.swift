//
//  JSONLoader.swift
//  JustSpent
//
//  Created by Claude Code on 2025-11-10.
//  Unified JSON loading utility for main app and tests
//

import Foundation

/// Unified JSON loader for loading configuration and data files
/// Used by both main app and test targets for consistency
class JSONLoader {

    // MARK: - Currency Models

    /// Root structure of currencies.json
    struct CurrencyData: Codable {
        let version: String
        let lastUpdated: String
        let currencies: [Currency]
    }

    /// Individual currency entry
    struct Currency: Codable {
        let code: String
        let symbol: String
        let displayName: String
        let shortName: String
        let localeIdentifier: String
        let isRTL: Bool
        let voiceKeywords: [String]
    }

    // MARK: - Currency Loading

    /// Load complete currency data from currencies.json
    /// - Parameters:
    ///   - bundle: Bundle to load from (defaults to main bundle)
    ///   - filename: JSON filename without extension (defaults to "currencies")
    /// - Returns: Parsed currency data, or nil if loading/parsing fails
    static func loadCurrencies(
        from bundle: Bundle = .main,
        filename: String = "currencies"
    ) -> CurrencyData? {
        // Find currencies.json in bundle
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            print("❌ JSONLoader: \(filename).json not found in bundle: \(bundle.bundlePath)")
            return nil
        }

        do {
            // Read file data
            let data = try Data(contentsOf: url)

            // Decode JSON
            let decoder = JSONDecoder()
            let currencyData = try decoder.decode(CurrencyData.self, from: data)

            print("✅ JSONLoader: Loaded \(currencyData.currencies.count) currencies (v\(currencyData.version))")
            return currencyData

        } catch let DecodingError.dataCorrupted(context) {
            print("❌ JSONLoader: Data corrupted - \(context.debugDescription)")
            return nil
        } catch let DecodingError.keyNotFound(key, context) {
            print("❌ JSONLoader: Key '\(key.stringValue)' not found - \(context.debugDescription)")
            return nil
        } catch let DecodingError.typeMismatch(type, context) {
            print("❌ JSONLoader: Type mismatch for \(type) - \(context.debugDescription)")
            return nil
        } catch {
            print("❌ JSONLoader: Failed to load \(filename).json - \(error.localizedDescription)")
            return nil
        }
    }

    /// Load just the currency codes (fast, minimal parsing)
    /// - Returns: Array of currency codes (e.g., ["AED", "USD", ...])
    static func loadCurrencyCodes(
        from bundle: Bundle = .main,
        filename: String = "currencies"
    ) -> [String] {
        guard let currencyData = loadCurrencies(from: bundle, filename: filename) else {
            print("⚠️ JSONLoader: Falling back to empty currency codes")
            return []
        }

        return currencyData.currencies.map { $0.code }
    }

    // MARK: - Generic JSON Loading (for future use)

    /// Load any Codable type from JSON file
    /// - Parameters:
    ///   - type: Type to decode (e.g., MyConfig.self)
    ///   - filename: JSON filename without extension
    ///   - bundle: Bundle to load from
    /// - Returns: Decoded object, or nil if loading/parsing fails
    static func load<T: Codable>(
        _ type: T.Type,
        from filename: String,
        bundle: Bundle = .main
    ) -> T? {
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            print("❌ JSONLoader: \(filename).json not found")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let result = try decoder.decode(T.self, from: data)
            print("✅ JSONLoader: Loaded \(filename).json as \(type)")
            return result
        } catch {
            print("❌ JSONLoader: Failed to load \(filename).json - \(error)")
            return nil
        }
    }
}
