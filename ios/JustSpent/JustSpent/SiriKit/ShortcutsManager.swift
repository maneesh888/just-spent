import Foundation
import Intents
import IntentsUI

class ShortcutsManager {
    static let shared = ShortcutsManager()
    
    private init() {}
    
    // MARK: - Donate Shortcuts
    
    /// Donate a log expense shortcut to Siri after successful expense logging
    func donateLogExpenseShortcut(amount: NSDecimalNumber, category: ExpenseCategory, merchant: String?) {
        let intent = LogExpenseIntent()
        intent.amount = amount
        intent.category = category
        intent.merchant = merchant
        intent.currency = "USD" // Default, should be user's preferred currency
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = "logExpense_\(amount)_\(category.rawValue)"
        interaction.groupIdentifier = "logExpense"
        
        interaction.donate { error in
            if let error = error {
                print("Failed to donate interaction: \(error.localizedDescription)")
            } else {
                print("Successfully donated log expense shortcut")
            }
        }
    }
    
    /// Donate a view expenses shortcut to Siri after viewing expenses
    func donateViewExpensesShortcut(category: ExpenseCategory?, timePeriod: String?) {
        let intent = ViewExpensesIntent()
        intent.category = category
        intent.timePeriod = timePeriod
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = "viewExpenses_\(category?.rawValue ?? "all")_\(timePeriod ?? "allTime")"
        interaction.groupIdentifier = "viewExpenses"
        
        interaction.donate { error in
            if let error = error {
                print("Failed to donate interaction: \(error.localizedDescription)")
            } else {
                print("Successfully donated view expenses shortcut")
            }
        }
    }
    
    // MARK: - Quick Add Shortcuts
    
    /// Create frequently used expense shortcuts
    func createQuickAddShortcuts() {
        // Common expense patterns
        let commonExpenses = [
            (amount: NSDecimalNumber(value: 5.0), category: ExpenseCategory.foodDining, phrase: "Morning coffee"),
            (amount: NSDecimalNumber(value: 15.0), category: ExpenseCategory.foodDining, phrase: "Lunch expense"),
            (amount: NSDecimalNumber(value: 50.0), category: ExpenseCategory.transportation, phrase: "Gas fill up"),
            (amount: NSDecimalNumber(value: 100.0), category: ExpenseCategory.grocery, phrase: "Weekly groceries")
        ]
        
        for expense in commonExpenses {
            donateLogExpenseShortcut(
                amount: expense.amount,
                category: expense.category,
                merchant: nil
            )
        }
    }
    
    // MARK: - Shortcut Suggestions
    
    /// Get relevant shortcut suggestions based on user patterns
    func getRelevantShortcuts(for context: ShortcutContext) -> [INShortcut] {
        var shortcuts: [INShortcut] = []
        
        switch context {
        case .mealTime:
            shortcuts.append(createFoodShortcut())
        case .commuting:
            shortcuts.append(createTransportShortcut())
        case .shopping:
            shortcuts.append(createShoppingShortcut())
        case .endOfDay:
            shortcuts.append(createViewShortcut())
        }
        
        return shortcuts
    }
    
    // MARK: - Context-Aware Shortcuts
    
    private func createFoodShortcut() -> INShortcut {
        let intent = LogExpenseIntent()
        intent.category = .foodDining
        intent.currency = "USD"
        intent.suggestedInvocationPhrase = "Log my meal expense"
        
        return INShortcut(intent: intent)!
    }
    
    private func createTransportShortcut() -> INShortcut {
        let intent = LogExpenseIntent()
        intent.category = .transportation
        intent.currency = "USD"
        intent.suggestedInvocationPhrase = "Log transport expense"
        
        return INShortcut(intent: intent)!
    }
    
    private func createShoppingShortcut() -> INShortcut {
        let intent = LogExpenseIntent()
        intent.category = .shopping
        intent.currency = "USD"
        intent.suggestedInvocationPhrase = "Log shopping expense"
        
        return INShortcut(intent: intent)!
    }
    
    private func createViewShortcut() -> INShortcut {
        let intent = ViewExpensesIntent()
        intent.timePeriod = "today"
        intent.suggestedInvocationPhrase = "Show today's expenses"
        
        return INShortcut(intent: intent)!
    }
    
    // MARK: - Shortcut Management
    
    /// Delete old shortcuts to keep suggestions relevant
    func cleanupOldShortcuts() {
        INInteraction.delete(with: []) { error in
            if let error = error {
                print("Failed to delete interactions: \(error.localizedDescription)")
            }
        }
    }
    
    /// Update shortcuts based on user behavior
    func updateShortcutsBasedOnUsage() {
        // This would analyze user patterns and suggest relevant shortcuts
        // Implementation would depend on usage analytics
    }
}

// MARK: - Supporting Types

enum ShortcutContext {
    case mealTime
    case commuting
    case shopping
    case endOfDay
}

// MARK: - Intent Response Handling

extension ShortcutsManager {
    
    /// Handle successful expense logging for shortcut donation
    func handleExpenseLogged(expense: Expense) {
        // Convert expense to intent parameters for donation
        if let amount = expense.amount,
           let categoryString = expense.category {
            
            let category = mapStringToCategory(categoryString)
            donateLogExpenseShortcut(
                amount: amount,
                category: category,
                merchant: expense.merchant
            )
        }
    }
    
    /// Handle expense viewing for shortcut donation
    func handleExpensesViewed(category: String?, timePeriod: String?) {
        let expenseCategory = category.flatMap(mapStringToCategory)
        donateViewExpensesShortcut(category: expenseCategory, timePeriod: timePeriod)
    }
    
    private func mapStringToCategory(_ categoryString: String) -> ExpenseCategory {
        switch categoryString {
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

// MARK: - Shortcut Voice Training

extension ShortcutsManager {
    
    /// Provide voice training phrases for better recognition
    func getVoiceTrainingPhrases() -> [String] {
        return [
            "I just spent 25 dollars on food",
            "I just spent 50 AED at the supermarket",
            "Log 15 dollars for lunch",
            "I paid 30 dollars for gas",
            "Show me my expenses for today",
            "What did I spend on groceries this week?",
            "I just bought coffee for 5 dollars",
            "Add 100 dollars shopping expense",
            "I spent 20 dollars on entertainment"
        ]
    }
    
    /// Get localized phrases for different regions
    func getLocalizedPhrases(for locale: Locale) -> [String] {
        switch locale.identifier {
        case "en_AE", "ar_AE":
            return [
                "I just spent 50 dirhams on groceries",
                "I paid 25 AED for lunch",
                "Log 100 dirhams for shopping"
            ]
        case "en_GB":
            return [
                "I just spent 20 pounds on petrol",
                "I paid 15 pounds for lunch",
                "Log 50 pounds for shopping"
            ]
        default:
            return getVoiceTrainingPhrases()
        }
    }
}