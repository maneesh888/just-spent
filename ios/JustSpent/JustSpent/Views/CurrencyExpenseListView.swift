//
//  CurrencyExpenseListView.swift
//  JustSpent
//
//  Created by Claude Code on 2025-10-20.
//  Shared expense list component for displaying expenses in a specific currency
//  WITH LAZY LOADING PAGINATION SUPPORT
//

import SwiftUI
import CoreData

/// Reusable expense list view filtered by currency with pagination
/// Used by both SingleCurrencyView and MultiCurrencyTabbedView
///
/// Implements lazy loading pagination:
/// - Loads 20 items per page
/// - Automatically loads more when scrolling near bottom
/// - Shows loading indicator while fetching
struct CurrencyExpenseListView: View {
    let currency: Currency
    @Environment(\.managedObjectContext) private var viewContext

    // ViewModel for pagination
    @StateObject private var viewModel: ExpenseListViewModel

    // Date filter state
    @Binding var dateFilter: DateFilter

    // Delete confirmation state
    @State private var showDeleteConfirmation = false
    @State private var expenseToDelete: Expense?

    // Edit state
    @State private var showEditSheet = false
    @State private var expenseToEdit: Expense?

    // Track last visible expense ID for scroll detection
    @State private var lastVisibleExpenseId: UUID?

    // Computed total for paginated expenses
    private var totalSpending: Double {
        viewModel.paginationState.loadedExpenses.reduce(0) { total, expense in
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

        // Initialize ViewModel with repository
        _viewModel = StateObject(wrappedValue: ExpenseListViewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            // Show filter strip only when there are expenses
            if !viewModel.paginationState.loadedExpenses.isEmpty {
                FilterStripView(selectedFilter: $dateFilter)
                    .accessibilityIdentifier("expense_filter_strip")
            }

            // Expense List
            if viewModel.paginationState.loadedExpenses.isEmpty && !viewModel.paginationState.isLoading {
                // Empty state (no expenses loaded)
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
                // Paginated expense list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.paginationState.loadedExpenses, id: \.id) { expense in
                            CurrencyExpenseRowView(expense: expense, currency: currency)
                                .padding(.horizontal, 16)
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        expenseToEdit = expense
                                        showEditSheet = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        expenseToDelete = expense
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .onAppear {
                                    // Detect when scrolling near bottom (prefetch distance = 5)
                                    checkAndLoadMore(for: expense)
                                }
                        }

                        // Loading indicator at bottom when fetching more
                        if viewModel.paginationState.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .onAppear {
            // Load first page when view appears
            loadFirstPage()
        }
        .onChange(of: dateFilter) { _ in
            // Reload when filter changes
            loadFirstPage()
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
        .sheet(isPresented: $showEditSheet) {
            if let expense = expenseToEdit {
                EditExpenseSheet(expense: expense, currency: currency)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    // Public computed property for parent views to display the total
    var totalSpendingFormatted: String {
        formattedTotal
    }

    /// Load first page of expenses
    private func loadFirstPage() {
        Task {
            await viewModel.loadFirstPage(currency: currency.code, dateFilter: dateFilter)
        }
    }

    /// Check if we need to load more expenses (scroll detection)
    /// Triggers when within 5 items of the end (prefetch distance)
    private func checkAndLoadMore(for expense: Expense) {
        let expenses = viewModel.paginationState.loadedExpenses
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else {
            return
        }

        // Load next page when within 5 items of the end
        let thresholdIndex = expenses.count - 5
        if index >= thresholdIndex && viewModel.paginationState.hasMore && !viewModel.paginationState.isLoading {
            Task {
                await viewModel.loadNextPage()
            }
        }
    }

    /// Perform the actual delete after confirmation
    private func performDelete(_ expense: Expense) {
        withAnimation {
            viewContext.delete(expense)

            do {
                try viewContext.save()
                // Reload first page to reflect deletion
                loadFirstPage()
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
