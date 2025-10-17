import XCTest
import CoreData
import Combine
@testable import JustSpent

final class ExpenseRepositoryTests: XCTestCase {
    
    var repository: ExpenseRepository!
    var testContext: NSManagedObjectContext!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory Core Data stack for testing
        let persistentContainer = NSPersistentContainer(name: "JustSpent")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }
        
        testContext = persistentContainer.viewContext
        let testPersistenceController = TestPersistenceController(container: persistentContainer)
        repository = ExpenseRepository(persistenceController: testPersistenceController)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        repository = nil
        testContext = nil
        cancellables = nil
        try super.tearDownWithError()
    }
    
    func testAddExpenseSuccess() async throws {
        // Given
        let expenseData = ExpenseData(
            amount: NSDecimalNumber(value: 25.50),
            currency: AppConstants.Currency.usd,
            category: "Food & Dining",
            merchant: "Coffee Shop",
            notes: "Morning coffee",
            transactionDate: Date(),
            source: AppConstants.ExpenseSource.manual,
            voiceTranscript: nil
        )
        
        // When
        let result = try await repository.addExpense(expenseData)
        
        // Then
        XCTAssertEqual(result.amount, NSDecimalNumber(value: 25.50))
        XCTAssertEqual(result.currency, AppConstants.Currency.usd)
        XCTAssertEqual(result.category, "Food & Dining")
        XCTAssertEqual(result.merchant, "Coffee Shop")
        XCTAssertEqual(result.source, AppConstants.ExpenseSource.manual)
    }
    
    func testGetAllExpensesReturnsEmptyInitially() throws {
        // Given
        let expectation = XCTestExpectation(description: "Get all expenses")
        
        // When
        repository.getAllExpenses()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { expenses in
                XCTAssertTrue(expenses.isEmpty)
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteExpenseSuccess() async throws {
        // Given
        let expenseData = ExpenseData(
            amount: NSDecimalNumber(value: 15.00),
            currency: AppConstants.Currency.usd,
            category: "Transport",
            merchant: nil,
            notes: nil,
            transactionDate: Date(),
            source: AppConstants.ExpenseSource.manual,
            voiceTranscript: nil
        )
        
        let addedExpense = try await repository.addExpense(expenseData)
        
        // When
        try await repository.deleteExpense(addedExpense)
        
        // Then
        let expectation = XCTestExpectation(description: "Expense deleted")
        repository.getAllExpenses()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { expenses in
                XCTAssertTrue(expenses.isEmpty)
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGetExpensesByCategoryFiltersCorrectly() async throws {
        // Given
        let foodExpense = ExpenseData(
            amount: NSDecimalNumber(value: 20.00),
            currency: AppConstants.Currency.usd,
            category: "Food & Dining",
            merchant: "Restaurant",
            notes: nil,
            transactionDate: Date(),
            source: AppConstants.ExpenseSource.manual,
            voiceTranscript: nil
        )

        let transportExpense = ExpenseData(
            amount: NSDecimalNumber(value: 50.00),
            currency: AppConstants.Currency.usd,
            category: "Transport",
            merchant: "Gas Station",
            notes: nil,
            transactionDate: Date(),
            source: AppConstants.ExpenseSource.manual,
            voiceTranscript: nil
        )
        
        _ = try await repository.addExpense(foodExpense)
        _ = try await repository.addExpense(transportExpense)
        
        // When
        let expectation = XCTestExpectation(description: "Get food expenses")
        repository.getExpensesByCategory("Food & Dining")
            .sink(receiveCompletion: { _ in },
                  receiveValue: { expenses in
                XCTAssertEqual(expenses.count, 1)
                XCTAssertEqual(expenses.first?.category, "Food & Dining")
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAddExpenseWithVoiceTranscript() async throws {
        // Given
        let expenseData = ExpenseData(
            amount: NSDecimalNumber(value: 30.00),
            currency: AppConstants.Currency.aed,
            category: "Grocery",
            merchant: "Supermarket",
            notes: "Weekly shopping",
            transactionDate: Date(),
            source: AppConstants.ExpenseSource.voiceSiri,
            voiceTranscript: "I just spent 30 dirhams on groceries at the supermarket"
        )

        // When
        let result = try await repository.addExpense(expenseData)

        // Then
        XCTAssertEqual(result.source, AppConstants.ExpenseSource.voiceSiri)
        XCTAssertEqual(result.voiceTranscript, "I just spent 30 dirhams on groceries at the supermarket")
        XCTAssertEqual(result.currency, AppConstants.Currency.aed)
    }
}

// MARK: - Test Helpers

class TestPersistenceController: PersistenceController {
    init(container: NSPersistentContainer) {
        super.init()
        self.container = container
    }
}