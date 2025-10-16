import Foundation
import Combine
import CoreData

@MainActor
class ExpenseListViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repository: ExpenseRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: ExpenseRepositoryProtocol = ExpenseRepository()) {
        self.repository = repository
        loadExpenses()
    }
    
    func loadExpenses() {
        isLoading = true
        errorMessage = nil
        
        repository.getAllExpenses()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] expenses in
                    self?.expenses = expenses
                }
            )
            .store(in: &cancellables)
    }
    
    func addSampleExpense() async {
        do {
            let expenseData = ExpenseData(
                amount: NSDecimalNumber(value: Double.random(in: 5.0...50.0)),
                currency: "USD",
                category: ["Food & Dining", "Grocery", "Transport", "Shopping"].randomElement()!,
                merchant: ["Coffee Shop", "Supermarket", "Gas Station", "Store"].randomElement()!,
                notes: "Sample expense",
                transactionDate: Date(),
                source: "manual",
                voiceTranscript: nil
            )
            
            _ = try await repository.addExpense(expenseData)
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteExpense(_ expense: Expense) async {
        do {
            try await repository.deleteExpense(expense)
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    var totalSpending: Double {
        expenses.reduce(0) { total, expense in
            total + (expense.amount?.doubleValue ?? 0)
        }
    }
    
    var formattedTotalSpending: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalSpending)) ?? "$0.00"
    }
}