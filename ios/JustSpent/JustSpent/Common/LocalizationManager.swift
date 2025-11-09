//
//  LocalizationManager.swift
//  JustSpent
//
//  Loads localization strings from shared localizations.json
//  Single source of truth for cross-platform consistency
//

import Foundation

/// Manages localized strings loaded from shared JSON file
class LocalizationManager {

    static let shared = LocalizationManager()

    private var localizations: [String: Any] = [:]
    private let platform = "ios"

    private init() {
        loadLocalizations()
    }

    // MARK: - Loading

    private func loadLocalizations() {
        let fileManager = FileManager.default
        var jsonURL: URL?

        // Try multiple paths to find the shared localization file

        // 1. Try from current working directory (works in tests)
        let currentDirPath = fileManager.currentDirectoryPath
        let sharedFromCurrent = "\(currentDirPath)/shared/localizations.json"
        if fileManager.fileExists(atPath: sharedFromCurrent) {
            jsonURL = URL(fileURLWithPath: sharedFromCurrent)
            print("📍 Found localizations.json in shared folder (from current dir)")
        }

        // 2. Try searching up from bundle path to find project root (works in simulator)
        if jsonURL == nil {
            jsonURL = findLocalizationFileFromBundle(fileManager: fileManager)
        }

        // 3. Fallback: load from bundle (production build with file added to Xcode)
        if jsonURL == nil {
            jsonURL = Bundle.main.url(forResource: "localizations", withExtension: "json")
            if jsonURL != nil {
                print("📍 Found localizations.json in app bundle")
            }
        }

        guard let url = jsonURL,
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to load localizations.json from any location")
            print("   Searched: current dir, bundle path, and app bundle")
            return
        }

        localizations = json
        print("✅ Loaded localizations.json version: \(json["version"] as? String ?? "unknown")")
    }

    /// Search for project root by looking for shared/localizations.json
    private func findLocalizationFileFromBundle(fileManager: FileManager) -> URL? {
        guard let bundlePath = Bundle.main.bundlePath else { return nil }

        var currentPath = (bundlePath as NSString).deletingLastPathComponent

        // Search up to 10 levels to find project root
        for _ in 0..<10 {
            let sharedPath = (currentPath as NSString).appendingPathComponent("shared/localizations.json")
            if fileManager.fileExists(atPath: sharedPath) {
                print("📍 Found localizations.json in shared folder (from bundle path)")
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

    // MARK: - String Access

    /// Get localized string by dot-notation path
    /// Example: get("app.title") returns "Just Spent"
    func get(_ key: String) -> String {
        let components = key.split(separator: ".").map(String.init)
        var current: Any? = localizations

        for component in components {
            guard let dict = current as? [String: Any] else {
                return "[\(key)]" // Return key in brackets if not found
            }
            current = dict[component]
        }

        // Handle platform-specific strings
        if let platformDict = current as? [String: String],
           let platformValue = platformDict[platform] {
            return platformValue
        }

        // Handle regular strings
        if let stringValue = current as? String {
            return stringValue
        }

        return "[\(key)]" // Return key in brackets if not found
    }

    // MARK: - Convenience Accessors

    var appTitle: String { get("app.title") }
    var appSubtitle: String { get("app.subtitle") }
    var appTotalLabel: String { get("app.totalLabel") }

    var emptyStateNoExpenses: String { get("emptyState.noExpenses") }
    var emptyStateTapVoiceButton: String { get("emptyState.tapVoiceButton") }

    var buttonOK: String { get("buttons.ok") }
    var buttonCancel: String { get("buttons.cancel") }
    var buttonRetry: String { get("buttons.retry") }

    var voiceListening: String { get("voice.listening") }
    var voiceProcessing: String { get("voice.processing") }

    var categoryFoodDining: String { get("categories.foodDining") }
    var categoryGrocery: String { get("categories.grocery") }
    var categoryTransportation: String { get("categories.transportation") }
    var categoryShopping: String { get("categories.shopping") }
    var categoryEntertainment: String { get("categories.entertainment") }
    var categoryBills: String { get("categories.bills") }
    var categoryHealthcare: String { get("categories.healthcare") }
    var categoryEducation: String { get("categories.education") }
    var categoryOther: String { get("categories.other") }
    var categoryUnknown: String { get("categories.unknown") }
}
