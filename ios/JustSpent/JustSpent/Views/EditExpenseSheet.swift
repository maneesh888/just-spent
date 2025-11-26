//
//  EditExpenseSheet.swift
//  JustSpent
//
//  Created by Claude Code on 2025-11-24.
//  Sheet view for editing expense category and amount
//

import SwiftUI
import CoreData

/// Sheet view for editing an expense's category and amount
/// Currency is NOT editable (displayed as read-only)
struct EditExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    let expense: Expense
    let currency: Currency

    // Editable fields
    @State private var selectedCategory: String
    @State private var amountText: String

    // Available categories (matching data-models-spec.md)
    private let categories = [
        "Food & Dining",
        "Grocery",
        "Transportation",
        "Shopping",
        "Entertainment",
        "Bills & Utilities",
        "Healthcare",
        "Education",
        "Other"
    ]

    init(expense: Expense, currency: Currency) {
        self.expense = expense
        self.currency = currency

        // Initialize state with current values
        _selectedCategory = State(initialValue: expense.category ?? "Other")
        _amountText = State(initialValue: expense.amount?.stringValue ?? "0.00")
    }

    var body: some View {
        NavigationView {
            Form {
                // Currency Section (Read-only)
                Section(header: Text("Currency")) {
                    HStack {
                        Text(currency.symbol)
                            .font(.title2)
                        Text(currency.displayName)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Not editable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Amount Section
                Section(header: Text("Amount")) {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("amount_field")
                }

                // Category Section
                Section(header: Text("Category")) {
                    Menu {
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                HStack {
                                    Text(category)
                                    if selectedCategory == category {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            .accessibilityIdentifier(category)
                        }
                    } label: {
                        HStack {
                            Text(selectedCategory)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityIdentifier("category_picker")
                }

                // Info Section
                Section(footer: Text("Only category and amount can be edited. Currency cannot be changed after expense is created.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValidAmount)
                }
            }
        }
    }

    /// Validate that amount is a valid decimal number
    private var isValidAmount: Bool {
        guard let amount = Decimal(string: amountText) else { return false }
        return amount > 0
    }

    /// Save the changes to Core Data
    private func saveChanges() {
        guard let newAmount = Decimal(string: amountText) else { return }

        // Update expense properties
        expense.category = selectedCategory
        expense.amount = NSDecimalNumber(decimal: newAmount)
        expense.updatedAt = Date()

        // Save context
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("❌ Error saving expense changes: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

struct EditExpenseSheet_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock expense for preview
        let context = PersistenceController.preview.container.viewContext
        let expense = Expense(context: context)
        expense.id = UUID()
        expense.amount = NSDecimalNumber(value: 150.00)
        expense.currency = "AED"
        expense.category = "Grocery"
        expense.merchant = "Carrefour"
        expense.transactionDate = Date()
        expense.createdAt = Date()
        expense.updatedAt = Date()
        expense.source = "manual"

        return EditExpenseSheet(expense: expense, currency: .aed)
            .environment(\.managedObjectContext, context)
    }
}
