//
//  UserPreferences.swift
//  JustSpent
//
//  Created by Claude Code on 2025-10-19.
//  User preferences management including currency settings
//

import Foundation
import CoreData
import Combine

/// Manages user preferences and settings
class UserPreferences: ObservableObject {

    // MARK: - Published Properties

    @Published var defaultCurrency: Currency {
        didSet {
            saveDefaultCurrency(defaultCurrency)
        }
    }

    @Published var currentUser: User?

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    // UserDefaults keys
    private enum Keys {
        static let defaultCurrency = "user_default_currency"
        static let hasCreatedDefaultUser = "user_has_created_default"
        static let hasCompletedOnboarding = "user_has_completed_onboarding"
    }

    // MARK: - Singleton

    static let shared = UserPreferences(context: PersistenceController.shared.container.viewContext)

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.context = context

        // Load default currency from UserDefaults or use system default
        if let currencyCode = UserDefaults.standard.string(forKey: Keys.defaultCurrency),
           let currency = Currency.from(isoCode: currencyCode) {
            self.defaultCurrency = currency
        } else {
            self.defaultCurrency = Currency.default
            UserDefaults.standard.set(Currency.default.code, forKey: Keys.defaultCurrency)
        }

        // Load or create default user
        loadOrCreateDefaultUser()
    }

    // MARK: - Public Methods

    /// Initialize default currency based on device locale if not already set.
    /// This ensures the app ALWAYS has a default currency, making modules independent.
    ///
    /// Should be called on app launch before checking onboarding state.
    ///
    /// - Returns: The initialized or existing default currency
    @discardableResult
    func initializeDefaultCurrency() -> Currency {
        // Check if default currency already exists in UserDefaults
        if let existingCode = UserDefaults.standard.string(forKey: Keys.defaultCurrency),
           let existingCurrency = Currency.from(isoCode: existingCode) {
            // Default currency already set - return existing
            print("UserPreferences: Using existing default currency: \(existingCurrency.code)")
            return existingCurrency
        }

        // No default currency set - detect from device locale
        let localeCurrency = Currency.default // Uses Locale.current.currencyCode

        // Save to UserDefaults
        UserDefaults.standard.set(localeCurrency.code, forKey: Keys.defaultCurrency)

        // Update published property
        self.defaultCurrency = localeCurrency

        print("UserPreferences: Initialized default currency from locale: \(localeCurrency.code)")
        return localeCurrency
    }

    /// Update the default currency for the current user
    /// - Parameter currency: New default currency
    func setDefaultCurrency(_ currency: Currency) {
        self.defaultCurrency = currency

        // Update the user entity
        if let user = currentUser {
            user.defaultCurrency = currency.code
            user.updatedAt = Date()
            saveContext()
        }
    }

    /// Get the current default currency
    /// - Returns: Current default currency
    func getCurrentCurrency() -> Currency {
        return defaultCurrency
    }

    /// Reset user preferences to defaults
    func resetToDefaults() {
        let systemDefault = Currency.default
        setDefaultCurrency(systemDefault)
    }

    /// Check if user has completed onboarding
    /// - Returns: true if onboarding is complete
    func hasCompletedOnboarding() -> Bool {
        return UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
    }

    /// Mark onboarding as complete
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Keys.hasCompletedOnboarding)
    }

    // MARK: - Private Methods

    /// Load existing user or create a new default user
    private func loadOrCreateDefaultUser() {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.fetchLimit = 1

        do {
            let users = try context.fetch(fetchRequest)

            if let existingUser = users.first {
                // Load existing user
                currentUser = existingUser

                // Sync currency from user entity
                if let currencyCode = existingUser.defaultCurrency,
                   let currency = Currency.from(isoCode: currencyCode) {
                    defaultCurrency = currency
                }
            } else {
                // Create new default user
                createDefaultUser()
            }
        } catch {
            print("Error loading user: \(error.localizedDescription)")
            createDefaultUser()
        }
    }

    /// Create a new default user
    private func createDefaultUser() {
        let user = User(context: context)
        user.id = UUID()
        user.name = "User"
        user.defaultCurrency = defaultCurrency.code
        user.createdAt = Date()
        user.updatedAt = Date()

        currentUser = user
        saveContext()

        UserDefaults.standard.set(true, forKey: Keys.hasCreatedDefaultUser)
    }

    /// Save default currency to UserDefaults
    /// - Parameter currency: Currency to save
    private func saveDefaultCurrency(_ currency: Currency) {
        UserDefaults.standard.set(currency.code, forKey: Keys.defaultCurrency)
    }

    /// Save Core Data context
    private func saveContext() {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
}

// MARK: - User Extension

extension User {
    /// Get the currency enum from the stored string
    var currency: Currency {
        get {
            guard let currencyCode = defaultCurrency,
                  let currency = Currency.from(isoCode: currencyCode) else {
                return Currency.default
            }
            return currency
        }
        set {
            defaultCurrency = newValue.code
        }
    }
}
