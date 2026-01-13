import Foundation
import Combine
import CoreData

// MARK: - Pagination State
struct PaginationState {
    let loadedExpenses: [Expense]
    let currentPage: Int
    let hasMore: Bool
    let isLoading: Bool
    let error: String?

    init(
        loadedExpenses: [Expense] = [],
        currentPage: Int = 0,
        hasMore: Bool = false,
        isLoading: Bool = false,
        error: String? = nil
    ) {
        self.loadedExpenses = loadedExpenses
        self.currentPage = currentPage
        self.hasMore = hasMore
        self.isLoading = isLoading
        self.error = error
    }
}

@MainActor
class ExpenseListViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Pagination state
    @Published var paginationState = PaginationState()

    private let repository: ExpenseRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    // Pagination properties
    private var currentCurrency: String = ""
    private var currentDateFilter: DateFilter = .all
    private let pageSize: Int = 20

    init(repository: ExpenseRepositoryProtocol = ExpenseRepository(), context: NSManagedObjectContext? = nil) {
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

    // MARK: - Pagination Methods
    func loadFirstPage(currency: String, dateFilter: DateFilter) async {
        currentCurrency = currency
        currentDateFilter = dateFilter

        paginationState = PaginationState(isLoading: true, error: nil)

        do {
            let expenses = try await repository.loadExpensesPage(
                currency: currency,
                dateFilter: dateFilter,
                page: 0,
                pageSize: pageSize
            )

            paginationState = PaginationState(
                loadedExpenses: expenses,
                currentPage: 0,
                hasMore: expenses.count == pageSize,
                isLoading: false,
                error: nil
            )
        } catch {
            paginationState = PaginationState(
                loadedExpenses: [],
                currentPage: 0,
                hasMore: false,
                isLoading: false,
                error: error.localizedDescription
            )
        }
    }

    func loadNextPage() async {
        // Don't load if already loading or no more data
        guard !paginationState.isLoading, paginationState.hasMore else {
            return
        }

        let nextPage = paginationState.currentPage + 1

        paginationState = PaginationState(
            loadedExpenses: paginationState.loadedExpenses,
            currentPage: paginationState.currentPage,
            hasMore: paginationState.hasMore,
            isLoading: true,
            error: nil
        )

        do {
            let newExpenses = try await repository.loadExpensesPage(
                currency: currentCurrency,
                dateFilter: currentDateFilter,
                page: nextPage,
                pageSize: pageSize
            )

            paginationState = PaginationState(
                loadedExpenses: paginationState.loadedExpenses + newExpenses,
                currentPage: nextPage,
                hasMore: newExpenses.count == pageSize,
                isLoading: false,
                error: nil
            )
        } catch {
            paginationState = PaginationState(
                loadedExpenses: paginationState.loadedExpenses,
                currentPage: paginationState.currentPage,
                hasMore: paginationState.hasMore,
                isLoading: false,
                error: error.localizedDescription
            )
        }
    }
}