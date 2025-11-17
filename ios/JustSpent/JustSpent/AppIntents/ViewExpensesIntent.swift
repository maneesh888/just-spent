//
//  ViewExpensesIntent.swift
//  JustSpent
//
//  App Intent for viewing expenses via Siri
//

import AppIntents
import Foundation
import CoreData

struct ViewExpensesIntent: AppIntent {
    static var title: LocalizedStringResource = "View Expenses"
    static var description = IntentDescription("View your expense history")

    // Enable this intent to be discovered and run
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = true

    // Parameters
    @Parameter(title: "Category", description: "Filter by category")
    var category: String?

    @Parameter(title: "Time Period", description: "Filter by time period (today, week, month)")
    var timePeriod: String?

    // Phrase suggestions for Siri
    static var parameterSummary: some ParameterSummary {
        Summary("Show my expenses") {
            \.$category
            \.$timePeriod
        }
    }

    // Main execution logic
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Get Core Data context
        let context = PersistenceController.shared.container.viewContext

        // Build fetch request
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        var predicates: [NSPredicate] = []

        // Filter by category if specified
        if let category = category {
            let parsedCategory = parseCategory(category)
            predicates.append(NSPredicate(format: "category == %@", parsedCategory))
        }

        // Filter by time period
        if let period = timePeriod {
            let dateRange = getDateRange(for: period)
            predicates.append(NSPredicate(format: "transactionDate >= %@", dateRange.start as NSDate))
            predicates.append(NSPredicate(format: "transactionDate <= %@", dateRange.end as NSDate))
        } else {
            // Default to current month if no period specified
            let dateRange = getDateRange(for: "month")
            predicates.append(NSPredicate(format: "transactionDate >= %@", dateRange.start as NSDate))
        }

        // Active expenses only
        predicates.append(NSPredicate(format: "status == %@", "active"))

        // Combine predicates
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "transactionDate", ascending: false)]

        // Fetch expenses
        do {
            let expenses = try context.fetch(fetchRequest)

            // Generate summary
            let summary = generateSummary(expenses: expenses, category: category, timePeriod: timePeriod)
            return .result(dialog: IntentDialog(stringLiteral: summary))
        } catch {
            return .result(dialog: IntentDialog(stringLiteral: "Failed to retrieve expenses"))
        }
    }

    // MARK: - Helper Methods

    private func parseCategory(_ categoryInput: String) -> String {
        let input = categoryInput.lowercased()

        let categoryMap: [String: String] = [
            "food": "Food & Dining",
            "dining": "Food & Dining",
            "grocery": "Grocery",
            "groceries": "Grocery",
            "transport": "Transportation",
            "transportation": "Transportation",
            "shopping": "Shopping",
            "entertainment": "Entertainment",
            "bills": "Bills & Utilities",
            "utilities": "Bills & Utilities",
            "healthcare": "Healthcare",
            "health": "Healthcare",
            "education": "Education"
        ]

        for (keyword, category) in categoryMap {
            if input.contains(keyword) {
                return category
            }
        }

        return categoryInput.capitalized
    }

    private func getDateRange(for period: String) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let endOfToday = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)

        switch period.lowercased() {
        case "today":
            let startOfToday = calendar.startOfDay(for: now)
            return (startOfToday, endOfToday)

        case "week", "this week":
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return (startOfWeek, endOfToday)

        case "month", "this month":
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return (startOfMonth, endOfToday)

        default:
            // Default to current month
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return (startOfMonth, endOfToday)
        }
    }

    private func generateSummary(expenses: [Expense], category: String?, timePeriod: String?) -> String {
        guard !expenses.isEmpty else {
            let periodText = timePeriod ?? "this month"
            let categoryText = category != nil ? " on \(category!)" : ""
            return "You have no expenses\(categoryText) for \(periodText)"
        }

        // Group by currency
        var currencyTotals: [String: Decimal] = [:]
        for expense in expenses {
            let currency = expense.currency ?? "AED"
            let amount = expense.amount?.decimalValue ?? 0
            currencyTotals[currency, default: 0] += amount
        }

        // Format summary
        var summaryParts: [String] = []

        let periodText = timePeriod?.lowercased() ?? "this month"
        let categoryText = category != nil ? " on \(category!)" : ""

        summaryParts.append("You spent")

        for (currency, total) in currencyTotals.sorted(by: { $0.key < $1.key }) {
            let formattedAmount = formatAmount(total, currency: currency)
            summaryParts.append(formattedAmount)
        }

        summaryParts.append("\(categoryText) for \(periodText)")

        let expenseCount = expenses.count
        summaryParts.append("(\(expenseCount) \(expenseCount == 1 ? "expense" : "expenses"))")

        return summaryParts.joined(separator: " ")
    }

    private func formatAmount(_ amount: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        let amountString = formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "0.00"

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
