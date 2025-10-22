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

    var body: some View {
        // Simple currency-filtered list view (no voice button - that's in ContentView's empty state)
        CurrencyExpenseListView(currency: currency)
            .navigationTitle(LocalizedStrings.appTitle)
            .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Preview

#Preview {
    SingleCurrencyView(currency: .aed)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
