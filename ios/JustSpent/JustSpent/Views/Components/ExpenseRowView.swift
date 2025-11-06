import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(expense.category ?? LocalizedStrings.categoryUnknown)
                        .font(.headline)
                    Spacer()
                    Text(formatAmount(expense.amount) + " " + (expense.currency ?? ""))
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

                    if expense.source == AppConstants.ExpenseSource.voiceSiri {
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
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount) ?? "0.00"
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
