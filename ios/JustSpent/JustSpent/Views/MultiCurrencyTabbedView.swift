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

    init(currencies: [Currency]) {
        self.currencies = currencies.sorted { $0.displayName < $1.displayName }

        // Set initial selection to default currency if available, otherwise first
        let defaultCurrency = UserPreferences.shared.defaultCurrency
        if let defaultIndex = currencies.firstIndex(of: defaultCurrency) {
            _selectedCurrency = State(initialValue: currencies[defaultIndex])
        } else {
            _selectedCurrency = State(initialValue: currencies.first ?? .aed)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Currency tabs - scrollable horizontal selector
                CurrencyTabBar(
                    currencies: currencies,
                    selectedCurrency: $selectedCurrency
                )
                .padding(.top, 8)

                // Selected currency expense list
                CurrencyExpenseListView(currency: selectedCurrency)
            }
            .navigationTitle(LocalizedStrings.appTitle)
            .navigationBarTitleDisplayMode(.large)
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
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
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

                Text(currency.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
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
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 3)
            }
        }
    }
}

// MARK: - Preview

#Preview("Multiple Currencies") {
    MultiCurrencyTabbedView(currencies: [.aed, .usd, .eur, .gbp])
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("Two Currencies") {
    MultiCurrencyTabbedView(currencies: [.aed, .usd])
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
