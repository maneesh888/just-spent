//
//  SingleCurrencyView.swift
//  JustSpent
//
//  Created by Claude Code on 2025-10-20.
//  Simple view for single currency expense tracking (no tabs)
//

import SwiftUI
import CoreData

/// Simple expense list view for when only one currency exists
/// No tabs needed - just shows the single currency list with voice button
struct SingleCurrencyView: View {
    let currency: Currency
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var userPreferences = UserPreferences.shared

    // Fetch expenses for total calculation
    @FetchRequest private var expenses: FetchedResults<Expense>

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

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom header with title and total
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStrings.appTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text(LocalizedStrings.appSubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(LocalizedStrings.totalLabel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formattedTotal)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Color(.systemBackground))

                // Expense list
                CurrencyExpenseListView(currency: currency)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Preview

#Preview("Empty State") {
    NavigationView {
        VStack {
            // Header with title and total
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Just Spent")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Voice-enabled expense tracker")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("د.إ 0.00")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(Color(.systemBackground))

            // Empty state content
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "tray")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)

                VStack(spacing: 12) {
                    Text("No Expenses Yet")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Text("Tap the microphone button to add an expense")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview("Single Currency") {
    SingleCurrencyView(currency: .aed)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
