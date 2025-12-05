//
//  TestDataManager.swift
//  JustSpent
//
//  Created for UI Testing Support
//  Handles test data setup based on launch arguments
//

import Foundation
import CoreData

/// Manages test data setup for UI testing
class TestDataManager {

    // MARK: - Shared Instance

    static let shared = TestDataManager()

    private init() {}

    // MARK: - Launch Argument Detection

    /// Check if app is running in UI testing mode
    static func isUITesting() -> Bool {
        return ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    /// Check if empty state should be shown
    static func shouldShowEmptyState() -> Bool {
        return ProcessInfo.processInfo.arguments.contains("--empty-state")
    }

    /// Check if onboarding should be forced
    static func shouldShowOnboarding() -> Bool {
        return ProcessInfo.processInfo.arguments.contains("--show-onboarding")
    }

    /// Check if onboarding should be skipped
    static func shouldSkipOnboarding() -> Bool {
        return ProcessInfo.processInfo.arguments.contains("--skip-onboarding")
    }

    /// Check if multi-currency test data should be populated
    static func shouldPopulateMultiCurrency() -> Bool {
        return ProcessInfo.processInfo.arguments.contains("--multi-currency")
    }

    // MARK: - Test Data Setup

    /// Setup test environment based on launch arguments
    func setupTestEnvironment(context: NSManagedObjectContext) {
        guard TestDataManager.isUITesting() else {
            print("ℹ️ Not in UI testing mode - skipping test data setup")
            return
        }

        print("🧪 Setting up UI test environment...")

        // Always clear existing data when in UI testing mode
        clearAllData(context: context)

        // Handle onboarding state
        if TestDataManager.shouldShowOnboarding() {
            print("🧪 Forcing onboarding to show")
            // Reset onboarding by setting UserDefaults key to false
            UserDefaults.standard.set(false, forKey: "user_has_completed_onboarding")
        } else if TestDataManager.shouldSkipOnboarding() || TestDataManager.isUITesting() {
            print("🧪 Skipping onboarding")
            UserPreferences.shared.completeOnboarding()
        }

        // Populate test data based on arguments
        if TestDataManager.shouldShowEmptyState() {
            print("🧪 Empty state - no test data populated")
            // No data needed, just cleared data is sufficient
        } else if TestDataManager.shouldPopulateMultiCurrency() {
            print("🧪 Populating multi-currency test data")
            populateMultiCurrencyData(context: context)
        } else {
            print("🧪 Populating default test data (single currency)")
            populateDefaultTestData(context: context)
        }

        // Save changes
        do {
            try context.save()
            print("✅ Test data saved to Core Data")

            // CRITICAL: Force context to refresh and merge changes
            // This ensures @FetchRequest in ContentView sees the new data immediately
            context.refreshAllObjects()
            print("✅ Context refreshed - @FetchRequest should now see test data")

            // Post notification to force SwiftUI views to update
            NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: context)
            print("✅ Test environment setup complete")
        } catch {
            print("❌ Failed to save test data: \(error)")
        }
    }

    // MARK: - Data Management

    /// Clear all existing expense data
    private func clearAllData(context: NSManagedObjectContext) {
        print("🧹 Clearing all existing expense data...")

        // Use regular fetch and delete instead of NSBatchDeleteRequest
        // This properly notifies @FetchRequest in SwiftUI to update
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()

        do {
            let expenses = try context.fetch(fetchRequest)
            for expense in expenses {
                context.delete(expense)
            }
            try context.save()

            print("✅ All expense data cleared (\(expenses.count) expenses deleted)")
        } catch {
            print("❌ Failed to clear data: \(error)")
        }
    }

    /// Populate default test data (single currency - AED)
    private func populateDefaultTestData(context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let today = Date()

        // Create 5 test expenses in AED
        let testExpenses: [(amount: Double, currency: String, category: String, merchant: String?, daysAgo: Int)] = [
            (150.00, "AED", "Grocery", "Carrefour", 0),
            (50.00, "AED", "Food & Dining", "Starbucks", 1),
            (200.00, "AED", "Transportation", "Uber", 2),
            (75.00, "AED", "Shopping", "Mall", 3),
            (100.00, "AED", "Bills & Utilities", "DEWA", 5)
        ]

        for expenseData in testExpenses {
            let expense = Expense(context: context)
            expense.id = UUID()
            expense.amount = NSDecimalNumber(value: expenseData.amount)
            expense.currency = expenseData.currency
            expense.category = expenseData.category
            expense.merchant = expenseData.merchant
            expense.transactionDate = calendar.date(byAdding: .day, value: -expenseData.daysAgo, to: today)
            expense.createdAt = Date()
            expense.updatedAt = Date()
            expense.source = AppConstants.ExpenseSource.manual
            expense.status = "active"
        }

        print("✅ Created 5 test expenses in AED")
    }

    /// Populate multi-currency test data with extensive entries for pagination testing
    private func populateMultiCurrencyData(context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let today = Date()

        // Categories and merchants for varied data
        let categories = ["Grocery", "Food & Dining", "Transportation", "Shopping", "Entertainment",
                         "Bills & Utilities", "Healthcare", "Education"]
        let merchantsByCategory: [String: [String]] = [
            "Grocery": ["Carrefour", "Lulu", "Spinneys", "Waitrose", "Choithrams"],
            "Food & Dining": ["Starbucks", "McDonald's", "KFC", "Shake Shack", "Five Guys", "Costa Coffee"],
            "Transportation": ["Uber", "Careem", "RTA", "ENOC", "ADNOC", "Shell"],
            "Shopping": ["Amazon", "Mall", "H&M", "Zara", "Noon", "Souq"],
            "Entertainment": ["VOX Cinemas", "Reel Cinemas", "Dubai Parks", "IMG Worlds", "Ski Dubai"],
            "Bills & Utilities": ["DEWA", "ADDC", "Du", "Etisalat", "Netflix", "Spotify"],
            "Healthcare": ["Pharmacy", "Clinic", "Hospital", "Lab", "Dentist"],
            "Education": ["School", "Course", "Books", "Tuition", "University"]
        ]

        // Currency configurations with realistic amount ranges
        let currencyConfigs: [(code: String, minAmount: Double, maxAmount: Double, count: Int)] = [
            ("AED", 10.0, 500.0, 50),   // 50 AED expenses
            ("USD", 5.0, 200.0, 40),     // 40 USD expenses
            ("EUR", 5.0, 150.0, 30),     // 30 EUR expenses
            ("GBP", 3.0, 120.0, 25),     // 25 GBP expenses
            ("INR", 100.0, 5000.0, 20),  // 20 INR expenses
            ("SAR", 10.0, 400.0, 15)     // 15 SAR expenses
        ]

        var totalExpenses = 0

        for config in currencyConfigs {
            for i in 0..<config.count {
                let expense = Expense(context: context)
                expense.id = UUID()

                // Random amount within range
                let amount = Double.random(in: config.minAmount...config.maxAmount)
                expense.amount = NSDecimalNumber(value: round(amount * 100) / 100)
                expense.currency = config.code

                // Random category
                let category = categories.randomElement()!
                expense.category = category

                // Random merchant from category
                if let merchants = merchantsByCategory[category] {
                    expense.merchant = merchants.randomElement()
                } else {
                    expense.merchant = "Merchant \(i + 1)"
                }

                // Varied dates over past 90 days
                let daysAgo = Int.random(in: 0...90)
                expense.transactionDate = calendar.date(byAdding: .day, value: -daysAgo, to: today)
                expense.createdAt = Date()
                expense.updatedAt = Date()

                // Mix of manual and voice sources
                expense.source = i % 3 == 0 ? AppConstants.ExpenseSource.voiceSiri : AppConstants.ExpenseSource.manual
                expense.status = "active"

                totalExpenses += 1
            }
        }

        print("✅ Created \(totalExpenses) test expenses across 6 currencies (50 AED, 40 USD, 30 EUR, 25 GBP, 20 INR, 15 SAR)")
        print("ℹ️  Data spans 90 days with varied categories and merchants for pagination testing")
    }
}
