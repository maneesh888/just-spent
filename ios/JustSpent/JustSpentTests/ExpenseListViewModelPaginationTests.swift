//
//  ExpenseListViewModelPaginationTests.swift
//  JustSpentTests
//
//  Integration tests for ExpenseListViewModel pagination functionality.
//  Tests the ViewModel's loadFirstPage() and loadNextPage() methods with real Core Data.
//
//  Success Scenario: Verify scrolling triggers pagination and loads data from database
//

import XCTest
import CoreData
@testable import JustSpent

@MainActor
class ExpenseListViewModelPaginationTests: XCTestCase {

    var viewModel: ExpenseListViewModel!
    var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create a fresh in-memory Core Data stack for each test
        let persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext

        // Create repository with test persistence controller
        let testRepository = ExpenseRepository(persistenceController: persistenceController)

        // Create ViewModel with test repository
        viewModel = ExpenseListViewModel(repository: testRepository, context: context)
    }

    override func tearDownWithError() throws {
        clearAllExpenses()
        viewModel = nil
        context = nil
        try super.tearDownWithError()
    }

    // MARK: - Helper Methods

    private func clearAllExpenses() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Expense.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        _ = try? context.execute(deleteRequest)
    }

    private func createTestExpenses(currency: String, count: Int) {
        context.performAndWait {
            let now = Date()
            for i in 0..<count {
                let expense = Expense(context: context)
                expense.id = UUID()
                expense.amount = NSDecimalNumber(value: Double(i + 1) * 10)
                expense.currency = currency
                expense.category = "Food"
                expense.merchant = "Test Merchant \(i)"
                expense.transactionDate = Date().addingTimeInterval(TimeInterval(-i * 3600))
                expense.createdAt = now
                expense.updatedAt = now
                expense.source = "test"
                expense.status = "active"
                expense.isRecurring = false
            }

            // Save and ensure it succeeds
            do {
                try context.save()
            } catch {
                XCTFail("Failed to save test expenses: \(error)")
            }
        }
    }

    // MARK: - Test Cases

    /// Test 1: Initial page load returns first 20 expenses
    ///
    /// Success Scenario:
    /// 1. Create 50 AED expenses in database
    /// 2. Call loadFirstPage(currency: "AED")
    /// 3. Verify: loadedExpenses.count == 20
    /// 4. Verify: currentPage == 0
    /// 5. Verify: hasMore == true (because 50 > 20)
    func testLoadFirstPage_loads20Expenses_fromDatabase() async throws {
        // Given: 50 AED expenses in database
        createTestExpenses(currency: "AED", count: 50)

        // When: Load first page
        await viewModel.loadFirstPage(currency: "AED", dateFilter: .all)

        // Then: Should load 20 expenses
        XCTAssertEqual(viewModel.paginationState.loadedExpenses.count, 20,
                       "First page should load 20 expenses")
        XCTAssertEqual(viewModel.paginationState.currentPage, 0,
                       "Current page should be 0")
        XCTAssertTrue(viewModel.paginationState.hasMore,
                      "Should have more pages available (50 total, 20 loaded)")
        XCTAssertFalse(viewModel.paginationState.isLoading,
                       "Should not be loading after completion")
        XCTAssertNil(viewModel.paginationState.error,
                     "Should not have error")

        // Verify expenses are sorted by date descending (most recent first)
        guard let firstExpense = viewModel.paginationState.loadedExpenses.first,
              let lastExpense = viewModel.paginationState.loadedExpenses.last else {
            XCTFail("Expected expenses to be loaded, but loadedExpenses is empty")
            return
        }

        XCTAssertGreaterThan(firstExpense.transactionDate!, lastExpense.transactionDate!,
                            "Expenses should be sorted by date descending")
    }

    /// Test 2: Loading next page appends 20 more expenses
    ///
    /// Success Scenario (simulates scrolling):
    /// 1. Create 50 AED expenses
    /// 2. Load first page → 20 expenses
    /// 3. User scrolls to bottom (simulated by calling loadNextPage)
    /// 4. Load next page → 40 total expenses
    /// 5. Verify data came from database
    func testLoadNextPage_appendsNext20_whenScrolling() async throws {
        // Given: 50 AED expenses, first page loaded
        createTestExpenses(currency: "AED", count: 50)
        await viewModel.loadFirstPage(currency: "AED", dateFilter: .all)

        let firstPageCount = viewModel.paginationState.loadedExpenses.count
        XCTAssertEqual(firstPageCount, 20, "First page should have 20 expenses")

        // When: User scrolls to bottom, triggering loadNextPage
        await viewModel.loadNextPage()

        // Then: Should append 20 more expenses (total 40)
        XCTAssertEqual(viewModel.paginationState.loadedExpenses.count, 40,
                       "After loading page 2, should have 40 total expenses")
        XCTAssertEqual(viewModel.paginationState.currentPage, 1,
                       "Current page should be 1")
        XCTAssertTrue(viewModel.paginationState.hasMore,
                      "Should still have more pages (50 total, 40 loaded)")
        XCTAssertFalse(viewModel.paginationState.isLoading,
                       "Should not be loading after completion")

        // Verify no duplicates (all expenses have unique IDs)
        let uniqueIds = Set(viewModel.paginationState.loadedExpenses.map { $0.id })
        XCTAssertEqual(uniqueIds.count, 40,
                       "All 40 expenses should have unique IDs (no duplicates)")
    }

    /// Test 3: Loading all pages until end
    ///
    /// Success Scenario:
    /// 1. Create 50 AED expenses
    /// 2. Load page 0 → 20 expenses, hasMore=true
    /// 3. Load page 1 → 40 expenses, hasMore=true
    /// 4. Load page 2 → 50 expenses, hasMore=false
    /// 5. Verify hasMore becomes false at end
    func testLoadAllPages_untilEnd_hasMoreBecomesFalse() async throws {
        // Given: 50 AED expenses
        createTestExpenses(currency: "AED", count: 50)

        // Load page 0
        await viewModel.loadFirstPage(currency: "AED", dateFilter: .all)
        XCTAssertEqual(viewModel.paginationState.loadedExpenses.count, 20)
        XCTAssertTrue(viewModel.paginationState.hasMore, "Should have more after page 0")

        // Load page 1
        await viewModel.loadNextPage()
        XCTAssertEqual(viewModel.paginationState.loadedExpenses.count, 40)
        XCTAssertTrue(viewModel.paginationState.hasMore, "Should have more after page 1")

        // Load page 2 (final page)
        await viewModel.loadNextPage()
        XCTAssertEqual(viewModel.paginationState.loadedExpenses.count, 50)
        XCTAssertFalse(viewModel.paginationState.hasMore,
                       "Should NOT have more after loading all 50 expenses")

        // Verify attempting to load more does nothing
        let countBeforeExtraLoad = viewModel.paginationState.loadedExpenses.count
        await viewModel.loadNextPage()
        XCTAssertEqual(viewModel.paginationState.loadedExpenses.count, countBeforeExtraLoad,
                       "Should not load more when hasMore is false")
    }

    /// Test 4: Pagination respects currency filter
    ///
    /// Success Scenario:
    /// 1. Create 30 AED + 30 USD expenses
    /// 2. Load AED expenses → should only get AED, not USD
    /// 3. Verify database filtering works
    func testPagination_respectsCurrencyFilter() async throws {
        // Given: 30 AED expenses and 30 USD expenses
        createTestExpenses(currency: "AED", count: 30)
        createTestExpenses(currency: "USD", count: 30)

        // When: Load first page of AED expenses
        await viewModel.loadFirstPage(currency: "AED", dateFilter: .all)

        // Then: Should only load AED expenses
        XCTAssertEqual(viewModel.paginationState.loadedExpenses.count, 20)

        for expense in viewModel.paginationState.loadedExpenses {
            XCTAssertEqual(expense.currency, "AED",
                          "All loaded expenses should be AED currency")
        }

        // Verify hasMore is true (30 AED total, 20 loaded)
        XCTAssertTrue(viewModel.paginationState.hasMore,
                      "Should have more AED expenses")
    }

    /// Test 5: Different currencies maintain independent pagination
    ///
    /// Success Scenario:
    /// 1. Load AED page 0 → 20 AED expenses
    /// 2. Switch to USD, load page 0 → 20 USD expenses
    /// 3. Verify each currency maintains separate pagination state
    func testSwitchingCurrencies_resetsPagination() async throws {
        // Given: 30 AED and 30 USD expenses
        createTestExpenses(currency: "AED", count: 30)
        createTestExpenses(currency: "USD", count: 30)

        // Load AED first page
        await viewModel.loadFirstPage(currency: "AED", dateFilter: .all)
        XCTAssertEqual(viewModel.paginationState.loadedExpenses.count, 20)
        XCTAssertEqual(viewModel.paginationState.loadedExpenses.first?.currency, "AED")

        // When: Switch to USD currency
        await viewModel.loadFirstPage(currency: "USD", dateFilter: .all)

        // Then: Should reset to page 0 with USD expenses
        XCTAssertEqual(viewModel.paginationState.currentPage, 0,
                       "Should reset to page 0 when switching currencies")
        XCTAssertEqual(viewModel.paginationState.loadedExpenses.count, 20,
                       "Should load 20 USD expenses")

        for expense in viewModel.paginationState.loadedExpenses {
            XCTAssertEqual(expense.currency, "USD",
                          "All expenses should be USD after currency switch")
        }
    }

    /// Test 6: Prevent duplicate loading while already loading
    ///
    /// Success Scenario:
    /// 1. Start loading next page
    /// 2. Try to load again while first load is in progress
    /// 3. Verify second call is ignored (prevents duplicates)
    func testLoadNextPage_preventsMultipleConcurrentLoads() async throws {
        // Given: 50 expenses
        createTestExpenses(currency: "AED", count: 50)
        await viewModel.loadFirstPage(currency: "AED", dateFilter: .all)

        // When: Trigger two loadNextPage calls concurrently
        async let load1 = viewModel.loadNextPage()
        async let load2 = viewModel.loadNextPage()

        await load1
        await load2

        // Then: Should only load one page (no duplicates)
        // If both loaded, we'd have 60 expenses (20 + 20 + 20)
        // But with guard, we should have 40 (20 + 20)
        XCTAssertEqual(viewModel.paginationState.loadedExpenses.count, 40,
                       "Should only load one page even with concurrent calls")
        XCTAssertEqual(viewModel.paginationState.currentPage, 1,
                       "Should only advance to page 1")
    }
}
