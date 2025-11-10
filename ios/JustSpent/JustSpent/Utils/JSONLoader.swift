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

    // MARK: - JSON File Types Enum

    /// Enum representing different JSON file types in the app
    enum JSONFileType {
        case currencies
        case localizations

        /// Filename without extension
        var filename: String {
            switch self {
            case .currencies:
                return "currencies"
            case .localizations:
                return "localizations"
            }
        }

        /// Associated Codable type for this file
        var dataType: Any.Type {
            switch self {
            case .currencies:
                return CurrencyData.self
            case .localizations:
                return LocalizationData.self
            }
        }
    }

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

    // MARK: - Localization Models

    /// Root structure of localizations.json
    struct LocalizationData: Codable {
        let version: String
        let lastUpdated: String
        let app: AppLocalizations
        let emptyState: EmptyStateLocalizations
        let buttons: ButtonLocalizations
        let voiceConfirmation: VoiceConfirmationLocalizations
        let voice: VoiceLocalizations
        let errors: ErrorLocalizations
        let permissions: PermissionLocalizations
        let categories: CategoryLocalizations
        let onboarding: OnboardingLocalizations
        let settings: SettingsLocalizations
        let currency: CurrencyLocalizations
    }

    struct AppLocalizations: Codable {
        let title: String
        let subtitle: String
        let totalLabel: String
    }

    struct EmptyStateLocalizations: Codable {
        let noExpenses: String
        let noCurrencyExpenses: String
        let tapVoiceButton: PlatformString
        let trySaying: String
        let exampleCommand: String
        let googleAssistantPrompt: PlatformValue<String>
        let permissionsNeeded: String
        let recognitionUnavailable: String
        let grantPermissions: String
    }

    struct ButtonLocalizations: Codable {
        let grantPermissions: String
        let ok: String
        let cancel: String
        let retry: String
        let process: String
        let goToSettings: String
        let delete: String
        let save: String
        let addSampleExpense: String
    }

    struct VoiceConfirmationLocalizations: Codable {
        let title: String
        let amount: String
        let category: String
        let merchant: String
        let notes: String
        let confidence: String
        let trySayingExample: String
    }

    struct VoiceLocalizations: Codable {
        let listening: String
        let processing: String
        let willStopAuto: String
        let enterExpense: String
        let enterNaturally: String
    }

    struct ErrorLocalizations: Codable {
        let noMicrophonePermission: String
        let noSpeechPermission: String
        let speechRecognitionFailed: String
        let couldNotParseExpense: String
        let invalidAmount: String
        let categoryNotRecognized: String
        let tryAgain: String
        let goToSettingsToEnable: String
        let recognitionNotAvailable: String
    }

    struct PermissionLocalizations: Codable {
        let microphoneTitle: String
        let microphoneMessage: String
        let speechRecognitionTitle: String
        let speechRecognitionMessage: String
        let bothPermissionsTitle: String
        let bothPermissionsMessage: String
    }

    struct CategoryLocalizations: Codable {
        let foodDining: String
        let grocery: String
        let transportation: String
        let shopping: String
        let entertainment: String
        let billsUtilities: String
        let healthcare: String
        let education: String
        let other: String
    }

    struct OnboardingLocalizations: Codable {
        let welcomeTitle: String
        let welcomeMessage: String
        let permissionsTitle: String
        let permissionsMessage: String
        let currencyTitle: String
        let currencyMessage: String
        let continueButton: String
        let skipButton: String
        let getStarted: String
    }

    struct SettingsLocalizations: Codable {
        let title: String
        let voiceSettings: String
        let defaultCurrency: String
        let language: String
        let theme: String
        let notifications: String
        let about: String
        let version: String
    }

    struct CurrencyLocalizations: Codable {
        let selectCurrency: String
        let searchCurrencies: String
        let noCurrenciesFound: String
    }

    /// Platform-specific string (iOS/Android)
    struct PlatformString: Codable {
        let ios: String
        let android: String
    }

    /// Platform-specific value (only one platform may have the value)
    struct PlatformValue<T: Codable>: Codable {
        let ios: T?
        let android: T?
    }

    // MARK: - Cached Data

    private static var currencyDataCache: CurrencyData?
    private static var localizationDataCache: LocalizationData?

    // MARK: - Generic JSON Loading

    /// Load JSON file using enum type
    /// - Parameters:
    ///   - fileType: Type of JSON file to load
    ///   - bundle: Bundle to load from (defaults to main bundle)
    ///   - filename: Optional custom filename (uses fileType.filename by default)
    /// - Returns: Decoded object of type T, or nil if loading/parsing fails
    static func load<T: Codable>(
        _ fileType: JSONFileType,
        from bundle: Bundle = .main,
        filename: String? = nil
    ) -> T? {
        let actualFilename = filename ?? fileType.filename

        // Find JSON file in bundle
        guard let url = bundle.url(forResource: actualFilename, withExtension: "json") else {
            print("❌ JSONLoader: \(actualFilename).json not found in bundle: \(bundle.bundlePath)")
            return nil
        }

        do {
            // Read file data
            let data = try Data(contentsOf: url)

            // Decode JSON
            let decoder = JSONDecoder()
            let result = try decoder.decode(T.self, from: data)

            print("✅ JSONLoader: Loaded \(actualFilename).json")
            return result

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
            print("❌ JSONLoader: Failed to load \(actualFilename).json - \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Convenience Methods for Currencies

    /// Load complete currency data from currencies.json (with caching)
    /// - Parameters:
    ///   - bundle: Bundle to load from (defaults to main bundle)
    ///   - filename: JSON filename without extension (defaults to "currencies")
    /// - Returns: Parsed currency data, or nil if loading/parsing fails
    static func loadCurrencies(
        from bundle: Bundle = .main,
        filename: String = "currencies"
    ) -> CurrencyData? {
        // Return cached data if available and using main bundle with default filename
        if bundle == .main && filename == "currencies", let cached = currencyDataCache {
            return cached
        }

        // Load from file
        guard let data: CurrencyData = load(.currencies, from: bundle, filename: filename) else {
            return nil
        }

        // Cache for main bundle with default filename
        if bundle == .main && filename == "currencies" {
            currencyDataCache = data
        }

        return data
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

    // MARK: - Convenience Methods for Localizations

    /// Load complete localization data from localizations.json (with caching)
    /// - Parameters:
    ///   - bundle: Bundle to load from (defaults to main bundle)
    ///   - filename: JSON filename without extension (defaults to "localizations")
    /// - Returns: Parsed localization data, or nil if loading/parsing fails
    static func loadLocalizations(
        from bundle: Bundle = .main,
        filename: String = "localizations"
    ) -> LocalizationData? {
        // Return cached data if available and using main bundle with default filename
        if bundle == .main && filename == "localizations", let cached = localizationDataCache {
            return cached
        }

        // Load from file
        guard let data: LocalizationData = load(.localizations, from: bundle, filename: filename) else {
            return nil
        }

        // Cache for main bundle with default filename
        if bundle == .main && filename == "localizations" {
            localizationDataCache = data
        }

        return data
    }

    /// Get localized string by key path (e.g., "app.title", "buttons.ok")
    /// - Parameter key: Dot-separated key path (e.g., "app.title")
    /// - Returns: Localized string, or the key itself if not found
    static func getLocalizedString(key: String) -> String {
        guard let localizationData = loadLocalizations() else {
            print("⚠️ JSONLoader: Could not load localizations, returning key")
            return key
        }

        // Parse key path
        let components = key.split(separator: ".").map(String.init)
        guard components.count == 2 else {
            print("⚠️ JSONLoader: Invalid key format '\(key)', expected 'section.key'")
            return key
        }

        let section = components[0]
        let keyName = components[1]

        // Route to appropriate section
        switch section {
        case "app":
            return getValue(from: localizationData.app, key: keyName) ?? key
        case "emptyState":
            return getValue(from: localizationData.emptyState, key: keyName) ?? key
        case "buttons":
            return getValue(from: localizationData.buttons, key: keyName) ?? key
        case "voiceConfirmation":
            return getValue(from: localizationData.voiceConfirmation, key: keyName) ?? key
        case "voice":
            return getValue(from: localizationData.voice, key: keyName) ?? key
        case "errors":
            return getValue(from: localizationData.errors, key: keyName) ?? key
        case "permissions":
            return getValue(from: localizationData.permissions, key: keyName) ?? key
        case "categories":
            return getValue(from: localizationData.categories, key: keyName) ?? key
        case "onboarding":
            return getValue(from: localizationData.onboarding, key: keyName) ?? key
        case "settings":
            return getValue(from: localizationData.settings, key: keyName) ?? key
        case "currency":
            return getValue(from: localizationData.currency, key: keyName) ?? key
        default:
            print("⚠️ JSONLoader: Unknown section '\(section)'")
            return key
        }
    }

    /// Get value from a Codable struct using key name
    private static func getValue<T: Codable>(from object: T, key: String) -> String? {
        let mirror = Mirror(reflecting: object)
        for child in mirror.children {
            if child.label == key {
                if let value = child.value as? String {
                    return value
                } else if let platformString = child.value as? PlatformString {
                    // Return iOS-specific string
                    return platformString.ios
                }
            }
        }
        return nil
    }

    // MARK: - Cache Management

    /// Clear all cached JSON data
    static func clearCache() {
        currencyDataCache = nil
        localizationDataCache = nil
        print("🗑️ JSONLoader: Cache cleared")
    }
}
