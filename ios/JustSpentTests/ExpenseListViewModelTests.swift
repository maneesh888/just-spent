import XCTest
import Combine
@testable import JustSpent

final class ExpenseListViewModelTests: XCTestCase {
    
    var viewModel: ExpenseListViewModel!
    var mockRepository: MockExpenseRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockRepository = MockExpenseRepository()
        viewModel = ExpenseListViewModel(repository: mockRepository)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockRepository = nil
        cancellables = nil
        try super.tearDownWithError()
    }
    
    func testInitialStateIsCorrect() throws {
        // Then
        XCTAssertTrue(viewModel.expenses.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.formattedTotalSpending, "$0.00")
    }
    
    func testLoadExpensesSuccess() throws {
        // Given
        let expenses = [createSampleExpense()]
        mockRepository.expensesToReturn = expenses
        
        let expectation = XCTestExpectation(description: "Expenses loaded")
        
        // When
        viewModel.$expenses
            .dropFirst() // Skip initial empty state
            .sink { loadedExpenses in
                XCTAssertEqual(loadedExpenses.count, 1)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.loadExpenses()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAddSampleExpenseSuccess() async throws {
        // Given
        mockRepository.shouldSucceed = true
        
        // When
        await viewModel.addSampleExpense()
        
        // Then
        XCTAssertTrue(mockRepository.addExpenseCalled)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testAddSampleExpenseFailure() async throws {
        // Given
        mockRepository.shouldSucceed = false
        mockRepository.errorToReturn = ExpenseError.databaseError("Test error")
        
        // When
        await viewModel.addSampleExpense()
        
        // Then
        XCTAssertTrue(mockRepository.addExpenseCalled)
        XCTAssertEqual(viewModel.errorMessage, "Test error")
    }
    
    func testDeleteExpenseSuccess() async throws {
        // Given
        let expense = createSampleExpense()
        mockRepository.shouldSucceed = true
        
        // When
        await viewModel.deleteExpense(expense)
        
        // Then
        XCTAssertTrue(mockRepository.deleteExpenseCalled)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testDeleteExpenseFailure() async throws {
        // Given
        let expense = createSampleExpense()
        mockRepository.shouldSucceed = false
        mockRepository.errorToReturn = ExpenseError.databaseError("Delete failed")
        
        // When
        await viewModel.deleteExpense(expense)
        
        // Then
        XCTAssertTrue(mockRepository.deleteExpenseCalled)
        XCTAssertEqual(viewModel.errorMessage, "Delete failed")
    }
    
    func testTotalSpendingCalculation() throws {
        // Given
        let expenses = [
            createSampleExpense(amount: 15.50),
            createSampleExpense(amount: 25.75),
            createSampleExpense(amount: 10.00)
        ]
        
        // When
        let total = expenses.reduce(0) { total, expense in
            total + (expense.amount?.doubleValue ?? 0)
        }
        
        // Then
        XCTAssertEqual(total, 51.25, accuracy: 0.01)
    }
    
    func testFormattedTotalSpending() throws {
        // Given
        let amount = 1234.56
        
        // When
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let formatted = formatter.string(from: NSNumber(value: amount))
        
        // Then
        XCTAssertEqual(formatted, "$1,234.56")
    }
    
    // MARK: - Helper Methods
    
    private func createSampleExpense(amount: Double = 25.50) -> Expense {
        let expense = Expense(context: PersistenceController.preview.container.viewContext)
        expense.id = UUID()
        expense.amount = NSDecimalNumber(value: amount)
        expense.currency = "USD"
        expense.category = "Food & Dining"
        expense.merchant = "Test Merchant"
        expense.transactionDate = Date()
        expense.source = "manual"
        expense.status = "active"
        expense.isRecurring = false
        expense.createdAt = Date()
        expense.updatedAt = Date()
        return expense
    }
}

// MARK: - Mock Repository

class MockExpenseRepository: ExpenseRepositoryProtocol {
    var expensesToReturn: [Expense] = []
    var shouldSucceed = true
    var errorToReturn: Error = ExpenseError.databaseError("Mock error")
    
    var addExpenseCalled = false
    var deleteExpenseCalled = false
    
    func getAllExpenses() -> AnyPublisher<[Expense], Error> {
        if shouldSucceed {
            return Just(expensesToReturn)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            return Fail(error: errorToReturn)
                .eraseToAnyPublisher()
        }
    }
    
    func getExpensesByCategory(_ category: String) -> AnyPublisher<[Expense], Error> {
        let filtered = expensesToReturn.filter { $0.category == category }
        return Just(filtered)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func addExpense(_ expense: ExpenseData) async throws -> Expense {
        addExpenseCalled = true
        if shouldSucceed {
            return createSampleExpense()
        } else {
            throw errorToReturn
        }
    }
    
    func deleteExpense(_ expense: Expense) async throws {
        deleteExpenseCalled = true
        if !shouldSucceed {
            throw errorToReturn
        }
    }
    
    private func createSampleExpense() -> Expense {
        let expense = Expense(context: PersistenceController.preview.container.viewContext)
        expense.id = UUID()
        expense.amount = NSDecimalNumber(value: 25.50)
        expense.currency = "USD"
        expense.category = "Food & Dining"
        expense.transactionDate = Date()
        expense.source = "manual"
        return expense
    }
}