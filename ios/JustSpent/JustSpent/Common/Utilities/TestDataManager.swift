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
            print("✅ Test environment setup complete")
        } catch {
            print("❌ Failed to save test data: \(error)")
        }
    }

    // MARK: - Data Management

    /// Clear all existing expense data
    private func clearAllData(context: NSManagedObjectContext) {
        print("🧹 Clearing all existing expense data...")

        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Expense.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            try context.save()
            print("✅ All expense data cleared")
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

    /// Populate multi-currency test data
    private func populateMultiCurrencyData(context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let today = Date()

        // Create test expenses across multiple currencies
        let testExpenses: [(amount: Double, currency: String, category: String, merchant: String?, daysAgo: Int)] = [
            // AED expenses
            (150.00, "AED", "Grocery", "Carrefour", 0),
            (50.00, "AED", "Food & Dining", "Starbucks", 1),
            (200.00, "AED", "Transportation", "Uber", 2),

            // USD expenses
            (25.00, "USD", "Food & Dining", "McDonald's", 0),
            (100.00, "USD", "Shopping", "Amazon", 1),
            (45.00, "USD", "Entertainment", "Cinema", 3),

            // EUR expenses
            (20.00, "EUR", "Food & Dining", "Cafe", 0),
            (80.00, "EUR", "Shopping", "Store", 2),

            // GBP expenses
            (15.00, "GBP", "Food & Dining", "Pub", 1),
            (60.00, "GBP", "Transportation", "Train", 3),

            // INR expenses
            (500.00, "INR", "Grocery", "Local Market", 0),
            (200.00, "INR", "Food & Dining", "Restaurant", 1),

            // SAR expenses
            (75.00, "SAR", "Shopping", "Mall", 2),
            (30.00, "SAR", "Food & Dining", "Fast Food", 3)
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

        print("✅ Created \(testExpenses.count) test expenses across 6 currencies (AED, USD, EUR, GBP, INR, SAR)")
    }
}
