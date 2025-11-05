//
//  MultiCurrencyTabbedView.swift
//  JustSpent
//
//  Created by Claude Code on 2025-10-20.
//  Tabbed interface for multiple currency expense tracking
//

import SwiftUI
import CoreData

/// Tabbed expense list view for when multiple currencies exist
/// Shows scrollable tabs at top for switching between currencies
struct MultiCurrencyTabbedView: View {
    let currencies: [Currency]
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var userPreferences = UserPreferences.shared
    @State private var selectedCurrency: Currency

    // Fetch expenses for selected currency
    @FetchRequest private var expenses: FetchedResults<Expense>

    init(currencies: [Currency]) {
        self.currencies = currencies.sorted { $0.displayName < $1.displayName }

        // Set initial selection to default currency if available, otherwise first
        let defaultCurrency = UserPreferences.shared.defaultCurrency
        let initialCurrency: Currency
        if let defaultIndex = currencies.firstIndex(of: defaultCurrency) {
            initialCurrency = currencies[defaultIndex]
        } else {
            initialCurrency = currencies.first ?? .aed
        }
        _selectedCurrency = State(initialValue: initialCurrency)

        // Initialize FetchRequest with initial currency filter
        let predicate = NSPredicate(format: "currency == %@", initialCurrency.rawValue)
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
            currency: selectedCurrency,
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
                            .accessibilityIdentifier("multi_currency_app_title")
                        Text(LocalizedStrings.appSubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("multi_currency_app_subtitle")
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(LocalizedStrings.totalLabel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("multi_currency_total_label")
                        Text(formattedTotal)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .accessibilityIdentifier("multi_currency_total_amount")
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Color(.systemBackground))

                // Currency tabs - scrollable horizontal selector
                CurrencyTabBar(
                    currencies: currencies,
                    selectedCurrency: $selectedCurrency
                )
                .padding(.top, 8)

                // Selected currency expense list
                CurrencyExpenseListView(currency: selectedCurrency)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Currency Tab Bar

/// Horizontal scrollable tab bar for currency selection
struct CurrencyTabBar: View {
    let currencies: [Currency]
    @Binding var selectedCurrency: Currency

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(currencies, id: \.self) { currency in
                    CurrencyTab(
                        currency: currency,
                        isSelected: currency == selectedCurrency
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCurrency = currency
                        }
                    }
                    .accessibilityIdentifier("currency_tab_\(currency.rawValue)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
        .accessibilityIdentifier("currency_tab_bar")
    }
}

// MARK: - Individual Currency Tab

/// Single currency tab button
struct CurrencyTab: View {
    let currency: Currency
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Text(currency.symbol)
                    .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                    .accessibilityIdentifier("tab_symbol_\(currency.rawValue)")

                Text(currency.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .accessibilityIdentifier("tab_code_\(currency.rawValue)")
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )

            // Selection indicator
            if isSelected {
                Rectangle()
                    .fill(Color.blue)
                    .frame(height: 3)
                    .cornerRadius(1.5)
                    .accessibilityIdentifier("tab_indicator_\(currency.rawValue)")
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 3)
            }
        }
    }
}

// MARK: - Preview

#Preview("Single Currency") {
    SingleCurrencyView(currency: .aed)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("Multiple Currencies") {
    MultiCurrencyTabbedView(currencies: [.aed, .usd, .eur, .gbp])
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
