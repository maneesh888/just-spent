//
//  SiriShortcutManager.swift
//  JustSpent
//
//  Created by Claude Code
//  Manages Siri Shortcuts donation for better intent recognition
//

import Foundation
import Intents
import CoreData

/// Manages Siri Shortcuts donation to help Siri learn user patterns
class SiriShortcutManager {

    static let shared = SiriShortcutManager()

    private init() {}

    // MARK: - Shortcut Donation

    /// Donate a LogExpense shortcut after user logs an expense
    /// This helps Siri learn the user's expense patterns
    func donateLogExpenseShortcut(
        amount: Decimal,
        currency: Currency,
        category: String,
        merchant: String? = nil
    ) {
        // Create the intent
        let intent = LogExpenseIntent()
        intent.amount = NSDecimalNumber(decimal: amount)
        intent.currency = currency.code

        // Map category string to enum
        if let categoryEnum = mapCategoryToEnum(category) {
            intent.category = categoryEnum
        }

        intent.merchant = merchant

        // Create suggested invocation phrase
        let phrase = generateInvocationPhrase(
            amount: amount,
            currency: currency,
            category: category,
            merchant: merchant
        )
        intent.suggestedInvocationPhrase = phrase

        // Create interaction
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = UUID().uuidString

        // Donate to system
        interaction.donate { error in
            if let error = error {
                print("❌ Failed to donate shortcut: \(error.localizedDescription)")
            } else {
                print("✅ Donated shortcut: \(phrase)")
            }
        }
    }

    /// Donate a ViewExpenses shortcut
    func donateViewExpensesShortcut(
        category: String? = nil,
        timePeriod: String? = nil
    ) {
        let intent = ViewExpensesIntent()

        if let category = category,
           let categoryEnum = mapCategoryToEnum(category) {
            intent.category = categoryEnum
        }

        intent.timePeriod = timePeriod

        let phrase = generateViewPhrase(category: category, timePeriod: timePeriod)
        intent.suggestedInvocationPhrase = phrase

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = UUID().uuidString

        interaction.donate { error in
            if let error = error {
                print("❌ Failed to donate view shortcut: \(error.localizedDescription)")
            } else {
                print("✅ Donated view shortcut: \(phrase)")
            }
        }
    }

    // MARK: - Shortcut Suggestions

    /// Create suggested shortcuts for the user based on common patterns
    func suggestCommonShortcuts() {
        // Morning coffee shortcut
        suggestShortcut(
            amount: 5.0,
            currency: .USD,
            category: "Food & Dining",
            phrase: "log my coffee"
        )

        // Lunch shortcut
        suggestShortcut(
            amount: 15.0,
            currency: .USD,
            category: "Food & Dining",
            phrase: "log my lunch"
        )

        // Gas fill-up
        suggestShortcut(
            amount: 50.0,
            currency: .USD,
            category: "Transportation",
            phrase: "log gas expense"
        )
    }

    private func suggestShortcut(
        amount: Decimal,
        currency: Currency,
        category: String,
        phrase: String
    ) {
        let intent = LogExpenseIntent()
        intent.amount = NSDecimalNumber(decimal: amount)
        intent.currency = currency.code

        if let categoryEnum = mapCategoryToEnum(category) {
            intent.category = categoryEnum
        }

        intent.suggestedInvocationPhrase = phrase

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate { _ in }
    }

    // MARK: - Delete Shortcuts

    /// Delete all donated shortcuts (e.g., when user logs out)
    func deleteAllShortcuts() {
        INInteraction.deleteAll { error in
            if let error = error {
                print("❌ Failed to delete shortcuts: \(error.localizedDescription)")
            } else {
                print("✅ Deleted all shortcuts")
            }
        }
    }

    /// Delete shortcuts with specific identifier
    func deleteShortcut(withIdentifier identifier: String) {
        INInteraction.delete(with: [identifier]) { error in
            if let error = error {
                print("❌ Failed to delete shortcut: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Helper Methods

    private func generateInvocationPhrase(
        amount: Decimal,
        currency: Currency,
        category: String,
        merchant: String?
    ) -> String {
        let formattedAmount = CurrencyFormatter.shared.format(
            amount: amount,
            currency: currency,
            showSymbol: false
        )

        if let merchant = merchant {
            return "I spent \(formattedAmount) \(currency.displayName) at \(merchant)"
        } else {
            return "I spent \(formattedAmount) \(currency.displayName) on \(category.lowercased())"
        }
    }

    private func generateViewPhrase(category: String?, timePeriod: String?) -> String {
        if let category = category, let timePeriod = timePeriod {
            return "Show my \(category.lowercased()) expenses for \(timePeriod)"
        } else if let category = category {
            return "Show my \(category.lowercased()) expenses"
        } else if let timePeriod = timePeriod {
            return "Show my expenses for \(timePeriod)"
        } else {
            return "Show my expenses"
        }
    }

    private func mapCategoryToEnum(_ category: String) -> ExpenseCategory? {
        switch category {
        case "Food & Dining":
            return .foodDining
        case "Grocery":
            return .grocery
        case "Transportation":
            return .transportation
        case "Shopping":
            return .shopping
        case "Entertainment":
            return .entertainment
        case "Bills & Utilities":
            return .billsUtilities
        case "Healthcare":
            return .healthcare
        case "Education":
            return .education
        default:
            return .other
        }
    }
}

// MARK: - Integration with ExpenseRepository

extension ExpenseRepository {

    /// Call this after successfully saving an expense
    func donateShortcutForExpense(_ expense: Expense) {
        guard let amount = expense.amount,
              let currencyCode = expense.currency,
              let category = expense.category,
              let currency = Currency.from(isoCode: currencyCode) else {
            return
        }

        SiriShortcutManager.shared.donateLogExpenseShortcut(
            amount: amount.decimalValue,
            currency: currency,
            category: category,
            merchant: expense.merchant
        )
    }
}
