import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = ExpenseListViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Just Spent")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Voice-enabled expense tracker")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.formattedTotalSpending)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                
                // Content
                if viewModel.expenses.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "mic.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 12) {
                            Text("No expenses yet")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            Text("Say \"Hey Siri, I just spent...\" to get started")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button(action: {
                            Task {
                                await viewModel.addSampleExpense()
                            }
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Sample Expense")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.expenses, id: \.id) { expense in
                            ExpenseRowView(expense: expense)
                        }
                        .onDelete(perform: deleteExpenses)
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func deleteExpenses(offsets: IndexSet) {
        for index in offsets {
            let expense = viewModel.expenses[index]
            Task {
                await viewModel.deleteExpense(expense)
            }
        }
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(expense.category ?? "Unknown")
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
                    
                    if expense.source == "voice_siri" {
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

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
