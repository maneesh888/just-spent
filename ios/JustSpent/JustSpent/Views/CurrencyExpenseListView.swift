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

    // Delete confirmation state
    @State private var showDeleteConfirmation = false
    @State private var expenseToDelete: Expense?

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
        let predicate = NSPredicate(format: "currency == %@", currency.code)
        _expenses = FetchRequest<Expense>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Expense.transactionDate, ascending: false)],
            predicate: predicate,
            animation: .default
        )
    }

    var body: some View {
        Group {
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
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    .onDelete(perform: requestDelete)
                }
                .listStyle(.plain)
            }
        }
        .alert("Delete Expense", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                expenseToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let expense = expenseToDelete {
                    performDelete(expense)
                }
                expenseToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this expense?")
        }
    }

    // Public computed property for parent views to display the total
    var totalSpendingFormatted: String {
        formattedTotal
    }

    /// Request delete confirmation for the selected expense
    private func requestDelete(offsets: IndexSet) {
        // Get the expense to delete
        if let index = offsets.first {
            expenseToDelete = expenses[index]
            showDeleteConfirmation = true
        }
    }

    /// Perform the actual delete after confirmation
    private func performDelete(_ expense: Expense) {
        withAnimation {
            viewContext.delete(expense)

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

#Preview {
    CurrencyExpenseListView(currency: .aed)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
