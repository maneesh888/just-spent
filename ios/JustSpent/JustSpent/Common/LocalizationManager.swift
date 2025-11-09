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

        // 1. Try from current working directory and relative paths (works in tests and CI)
        let currentDirPath = fileManager.currentDirectoryPath
        let possiblePaths = [
            "\(currentDirPath)/shared/localizations.json",        // From project root
            "\(currentDirPath)/../shared/localizations.json",     // From ios/ directory
            "\(currentDirPath)/../../shared/localizations.json"   // From ios/JustSpent/ directory
        ]

        for path in possiblePaths {
            if fileManager.fileExists(atPath: path) {
                jsonURL = URL(fileURLWithPath: path)
                print("📍 Found localizations.json in shared folder (from current dir: \(path))")
                break
            }
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
        let bundlePath = Bundle.main.bundlePath

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

    // App General
    var appTitle: String { get { return get("app.title") } }
    var appSubtitle: String { get { return get("app.subtitle") } }
    var appTotalLabel: String { get { return get("app.totalLabel") } }

    // Empty State
    var emptyStateNoExpenses: String { get { return get("emptyState.noExpenses") } }
    var emptyStateTapVoiceButton: String { get { return get("emptyState.tapVoiceButton") } }
    var emptyStatePermissionsNeeded: String { get { return get("emptyState.permissionsNeeded") } }
    var emptyStateRecognitionUnavailable: String { get { return get("emptyState.recognitionUnavailable") } }
    var emptyStateGrantPermissions: String { get { return get("emptyState.grantPermissions") } }

    // Buttons
    var buttonGrantPermissions: String { get { return get("buttons.grantPermissions") } }
    var buttonOK: String { get { return get("buttons.ok") } }
    var buttonCancel: String { get { return get("buttons.cancel") } }
    var buttonRetry: String { get { return get("buttons.retry") } }
    var buttonProcess: String { get { return get("buttons.process") } }
    var buttonGoToSettings: String { get { return get("buttons.goToSettings") } }
    var buttonDelete: String { get { return get("buttons.delete") } }
    var buttonSave: String { get { return get("buttons.save") } }

    // Voice
    var voiceListening: String { get { return get("voice.listening") } }
    var voiceProcessing: String { get { return get("voice.processing") } }
    var voiceWillStopAuto: String { get { return get("voice.willStopAuto") } }
    var voiceEnterExpense: String { get { return get("voice.enterExpense") } }
    var voiceEnterNaturally: String { get { return get("voice.enterNaturally") } }

    // Categories
    var categoryFoodDining: String { get { return get("categories.foodDining") } }
    var categoryGrocery: String { get { return get("categories.grocery") } }
    var categoryTransportation: String { get { return get("categories.transportation") } }
    var categoryShopping: String { get { return get("categories.shopping") } }
    var categoryEntertainment: String { get { return get("categories.entertainment") } }
    var categoryBills: String { get { return get("categories.bills") } }
    var categoryHealthcare: String { get { return get("categories.healthcare") } }
    var categoryEducation: String { get { return get("categories.education") } }
    var categoryOther: String { get { return get("categories.other") } }
    var categoryUnknown: String { get { return get("categories.unknown") } }

    // Settings
    var settingsTitle: String { get { return get("settings.title") } }
    var settingsCurrencySettings: String { get { return get("settings.currencySettings") } }
    var settingsCurrencyFooter: String { get { return get("settings.currencyFooter") } }
    var settingsUserInformation: String { get { return get("settings.userInformation") } }
    var settingsAbout: String { get { return get("settings.about") } }
    var settingsVersion: String { get { return get("settings.version") } }
    var settingsBuild: String { get { return get("settings.build") } }
    var settingsName: String { get { return get("settings.name") } }
    var settingsEmail: String { get { return get("settings.email") } }
    var settingsMemberSince: String { get { return get("settings.memberSince") } }
    var settingsDefaultCurrency: String { get { return get("settings.defaultCurrency") } }
    var settingsResetToDefaults: String { get { return get("settings.resetToDefaults") } }
    var settingsDone: String { get { return get("settings.done") } }
}
