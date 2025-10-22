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

    // Computed total for this currency
    private var totalSpending: Double {
        expenses.reduce(0) { total, expense in
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

    init(currency: Currency) {
        self.currency = currency

        // Initialize FetchRequest with currency filter
        let predicate = NSPredicate(format: "currency == %@", currency.rawValue)
        _expenses = FetchRequest<Expense>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Expense.transactionDate, ascending: false)],
            predicate: predicate,
            animation: .default
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Total Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStrings.totalLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedTotal)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))

            // Expense List
            if expenses.isEmpty {
                // Empty state for this currency
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
            } else {
                List {
                    ForEach(expenses, id: \.id) { expense in
                        CurrencyExpenseRowView(expense: expense, currency: currency)
                    }
                    .onDelete(perform: deleteExpenses)
                }
                .listStyle(.plain)
            }
        }
    }

    private func deleteExpenses(offsets: IndexSet) {
        withAnimation {
            offsets.map { expenses[$0] }.forEach { expense in
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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(expense.category ?? LocalizedStrings.categoryUnknown)
                        .font(.headline)
                    Spacer()
                    Text(formatAmount(expense.amount))
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                if let merchant = expense.merchant {
                    Text(merchant)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

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
        }
        .padding(.vertical, 4)
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

#Preview {
    CurrencyExpenseListView(currency: .aed)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
