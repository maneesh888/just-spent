//
//  LogExpenseIntent.swift
//  JustSpent
//
//  App Intent for logging expenses via Siri
//

import AppIntents
import Foundation
import CoreData

struct LogExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Expense"
    static var description = IntentDescription("Log an expense with amount and category")

    // Enable this intent to be discovered and run
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = true

    // Parameters
    @Parameter(
        title: "Amount",
        description: "The expense amount",
        requestValueDialog: IntentDialog("How much did you spend?")
    )
    var amount: Double

    @Parameter(
        title: "Currency",
        description: "Currency code like AED, USD, EUR",
        default: "AED"
    )
    var currency: String

    @Parameter(
        title: "Category",
        description: "Expense category like food, groceries, transport, shopping",
        requestValueDialog: IntentDialog("What category is this expense for?")
    )
    var category: String?

    @Parameter(
        title: "Merchant",
        description: "Merchant or vendor name",
        requestValueDialog: IntentDialog("Where did you make this purchase?")
    )
    var merchant: String?

    @Parameter(title: "Note", description: "Additional notes")
    var note: String?

    // Phrase suggestions for Siri
    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) \(\.$currency) for \(\.$category)") {
            \.$merchant
            \.$note
        }
    }

    // Static suggestions to help Siri understand natural language
    static var suggestedInvocationPhrase: String {
        "Just Spent"
    }

    // Main execution logic
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Validate amount
        guard amount > 0 else {
            throw IntentError.invalidAmount
        }

        // Get or create Core Data context
        let context = PersistenceController.shared.container.viewContext

        // Create new expense
        let expense = Expense(context: context)
        expense.id = UUID()
        expense.amount = NSDecimalNumber(value: amount)
        expense.currency = currency.uppercased()
        expense.category = parseCategory(category)
        expense.merchant = merchant
        expense.notes = note
        expense.transactionDate = Date()
        expense.createdAt = Date()
        expense.updatedAt = Date()
        expense.source = "voice_siri"
        expense.status = "active"
        expense.isRecurring = false

        // Save to Core Data
        do {
            try context.save()

            // Format response message
            let categoryText = expense.category ?? "Other"
            let amountText = formatAmount(amount, currency: currency)
            let message = merchant != nil
                ? "Logged \(amountText) at \(merchant!) for \(categoryText)"
                : "Logged \(amountText) for \(categoryText)"

            return .result(dialog: IntentDialog(stringLiteral: message))
        } catch {
            throw IntentError.saveFailed
        }
    }

    // MARK: - Helper Methods

    private func parseCategory(_ categoryInput: String?) -> String {
        guard let input = categoryInput?.lowercased() else {
            return "Other"
        }

        // Category keyword mapping
        let categoryMap: [String: String] = [
            "food": "Food & Dining",
            "dining": "Food & Dining",
            "restaurant": "Food & Dining",
            "lunch": "Food & Dining",
            "dinner": "Food & Dining",
            "breakfast": "Food & Dining",

            "grocery": "Grocery",
            "groceries": "Grocery",
            "supermarket": "Grocery",

            "transport": "Transportation",
            "transportation": "Transportation",
            "taxi": "Transportation",
            "uber": "Transportation",
            "gas": "Transportation",
            "fuel": "Transportation",
            "petrol": "Transportation",

            "shopping": "Shopping",
            "clothes": "Shopping",
            "clothing": "Shopping",

            "entertainment": "Entertainment",
            "movie": "Entertainment",
            "cinema": "Entertainment",
            "concert": "Entertainment",

            "bills": "Bills & Utilities",
            "utilities": "Bills & Utilities",
            "electricity": "Bills & Utilities",
            "water": "Bills & Utilities",
            "internet": "Bills & Utilities",

            "healthcare": "Healthcare",
            "health": "Healthcare",
            "doctor": "Healthcare",
            "hospital": "Healthcare",
            "medicine": "Healthcare",
            "pharmacy": "Healthcare",

            "education": "Education",
            "school": "Education",
            "course": "Education",
            "training": "Education"
        ]

        // Try to match category
        for (keyword, category) in categoryMap {
            if input.contains(keyword) {
                return category
            }
        }

        return "Other"
    }

    private func formatAmount(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        let amountString = formatter.string(from: NSNumber(value: amount)) ?? "0.00"

        // Currency symbol mapping
        let currencySymbols: [String: String] = [
            "AED": "د.إ",
            "USD": "$",
            "EUR": "€",
            "GBP": "£",
            "INR": "₹",
            "SAR": "﷼"
        ]

        let symbol = currencySymbols[currency.uppercased()] ?? currency
        return "\(symbol) \(amountString)"
    }
}

// MARK: - Error Handling

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case invalidAmount
    case saveFailed
    case invalidCategory

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidAmount:
            return "Please provide a valid amount greater than zero"
        case .saveFailed:
            return "Failed to save expense. Please try again"
        case .invalidCategory:
            return "Invalid category specified"
        }
    }
}
