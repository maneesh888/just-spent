//
//  CurrencyExpenseListView.swift
//  JustSpent
//
//  Created by Claude Code on 2025-10-20.
//  Shared expense list component for displaying expenses in a specific currency
//

import SwiftUI
import CoreData

/// Reusable expense list view filtered by currency
/// Used by both SingleCurrencyView and MultiCurrencyTabbedView
struct CurrencyExpenseListView: View {
    let currency: Currency
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch expenses for this specific currency
    @FetchRequest private var expenses: FetchedResults<Expense>

    // User preferences
    @StateObject private var userPreferences = UserPreferences.shared

    // Date filter state
    @Binding var dateFilter: DateFilter

    // Filtered expenses based on date filter
    private var filteredExpenses: [Expense] {
        let dateFilterUtils = DateFilterUtils.shared
        return expenses.filter { expense in
            guard let transactionDate = expense.transactionDate else { return true }
            return dateFilterUtils.isDate(transactionDate, inFilter: dateFilter)
        }
    }

    // Computed total for filtered expenses
    private var totalSpending: Double {
        filteredExpenses.reduce(0) { total, expense in
            total + (expense.amount?.doubleValue ?? 0)
        }
    }

    private var formattedTotal: String {
        let amount = Decimal(totalSpending)
        return CurrencyFormatter.shared.format(
            amount: amount,
            currency: currency,
            showSymbol: true,
            showCode: false
        )
    }

    init(currency: Currency, dateFilter: Binding<DateFilter>) {
        self.currency = currency
        self._dateFilter = dateFilter

        // Initialize FetchRequest with currency filter
        let predicate = NSPredicate(format: "currency == %@", currency.code)
        _expenses = FetchRequest<Expense>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Expense.transactionDate, ascending: false)],
            predicate: predicate,
            animation: .default
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Show filter strip only when there are expenses
            if !expenses.isEmpty {
                FilterStripView(selectedFilter: $dateFilter)
                    .accessibilityIdentifier("expense_filter_strip")
            }

            // Expense List
            if expenses.isEmpty {
                // Empty state for this currency (no expenses at all)
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)

                    VStack(spacing: 8) {
                        Text("No \(currency.displayName) Expenses")
                            .font(.title3)
                            .foregroundColor(.secondary)

                        Text("Tap the microphone button to add an expense")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                }
                .padding()
            } else if filteredExpenses.isEmpty {
                // Empty state for filtered results
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)

                    VStack(spacing: 8) {
                        Text("No Expenses for \(dateFilter.displayName)")
                            .font(.title3)
                            .foregroundColor(.secondary)

                        Text("Try selecting a different time period")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                }
                .padding()
                .accessibilityIdentifier("empty_filter_state")
            } else {
                List {
                    ForEach(filteredExpenses, id: \.id) { expense in
                        CurrencyExpenseRowView(expense: expense, currency: currency)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    .onDelete(perform: deleteFilteredExpenses)
                }
                .listStyle(.plain)
            }
        }
    }

    // Public computed property for parent views to display the total
    var totalSpendingFormatted: String {
        formattedTotal
    }

    private func deleteFilteredExpenses(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredExpenses[$0] }.forEach { expense in
                viewContext.delete(expense)
            }

            do {
                try viewContext.save()
            } catch {
                print("❌ Error deleting expense: \(error.localizedDescription)")
            }
        }
    }
}

/// Expense row view without currency badge (currency is known from context)
struct CurrencyExpenseRowView: View {
    let expense: Expense
    let currency: Currency

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Category and Amount Row
            HStack {
                Text(expense.category ?? LocalizedStrings.categoryUnknown)
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
                Text(formatAmount(expense.amount))
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            // Merchant (if available)
            if let merchant = expense.merchant {
                Text(merchant)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Date and Voice Indicator Row
            HStack {
                Text(formatDate(expense.transactionDate))
                    .font(.caption)
                    .foregroundColor(.secondary)

                if expense.source == AppConstants.ExpenseSource.voiceSiri ||
                   expense.source == AppConstants.ExpenseSource.voiceRecognition {
                    Image(systemName: "mic.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                Spacer()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }

    private func formatAmount(_ amount: NSDecimalNumber?) -> String {
        guard let amount = amount else { return "0.00" }
        let decimalAmount = Decimal(string: amount.stringValue) ?? 0
        return CurrencyFormatter.shared.formatCompact(amount: decimalAmount, currency: currency)
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct CurrencyExpenseListView_Previews: PreviewProvider {
    @State static var dateFilter: DateFilter = .all

    static var previews: some View {
        CurrencyExpenseListView(currency: .aed, dateFilter: $dateFilter)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
