//
//  ExpensePaginationTests.swift
//  JustSpentTests
//
//  Unit tests for pagination functionality in Just Spent iOS app.
//
//  These tests verify that pagination correctly loads expenses in batches of 20 items,
//  respects filters, handles end-of-list scenarios, and maintains separate states for different currencies.
//
//  Test Data: Uses 180 expenses across 6 currencies (AED:50, USD:40, EUR:30, GBP:25, INR:20, SAR:15)
//  Page Size: 20 items per page
//  Approach: Data verification (not UI-dependent)
//
//  TDD Phase: RED - These tests will FAIL until pagination is implemented
//

import XCTest
import CoreData
@testable import JustSpent

class ExpensePaginationTests: XCTestCase {

    var viewContext: NSManagedObjectContext!
    var viewModel: ExpenseListViewModel!

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create in-memory Core Data stack for testing using PersistenceController
        let testPersistence = PersistenceController(inMemory: true)
        viewContext = testPersistence.container.viewContext

        // Clear any existing data
        clearAllExpenses()

        // Populate test data (180 expenses) in the same context the ViewModel will use
        populatePaginationTestData()

        // Initialize ViewModel with test repository using the SAME persistence controller
        let testRepository = ExpenseRepository(persistenceController: testPersistence)
        viewModel = ExpenseListViewModel(repository: testRepository)
    }

    override func tearDownWithError() throws {
        viewContext = nil
        viewModel = nil
        try super.tearDownWithError()
    }

    // MARK: - Test Data Setup

    /// Clear all expenses from test database
    private func clearAllExpenses() {
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()

        do {
            let expenses = try viewContext.fetch(fetchRequest)
            for expense in expenses {
                viewContext.delete(expense)
            }
            try viewContext.save()
        } catch {
            XCTFail("Failed to clear expenses: \(error)")
        }
    }

    /// Populate test data with 180 expenses across 6 currencies
    /// Matches TestDataManager.populateMultiCurrencyData() distribution
    private func populatePaginationTestData() {
        let calendar = Calendar.current
        let today = Date()

        // Categories and merchants for varied data
        let categories = ["Grocery", "Food & Dining", "Transportation", "Shopping", "Entertainment",
                         "Bills & Utilities", "Healthcare", "Education"]
        let merchantsByCategory: [String: [String]] = [
            "Grocery": ["Carrefour", "Lulu", "Spinneys", "Waitrose", "Choithrams"],
            "Food & Dining": ["Starbucks", "McDonald's", "KFC", "Shake Shack", "Five Guys", "Costa Coffee"],
            "Transportation": ["Uber", "Careem", "RTA", "ENOC", "ADNOC", "Shell"],
            "Shopping": ["Amazon", "Mall", "H&M", "Zara", "Noon", "Souq"],
            "Entertainment": ["VOX Cinemas", "Reel Cinemas", "Dubai Parks", "IMG Worlds", "Ski Dubai"],
            "Bills & Utilities": ["DEWA", "ADDC", "Du", "Etisalat", "Netflix", "Spotify"],
            "Healthcare": ["Pharmacy", "Clinic", "Hospital", "Lab", "Dentist"],
            "Education": ["School", "Course", "Books", "Tuition", "University"]
        ]

        // Currency configurations
        let currencyConfigs: [(code: String, minAmount: Double, maxAmount: Double, count: Int)] = [
            ("AED", 10.0, 500.0, 50),   // 50 AED expenses
            ("USD", 5.0, 200.0, 40),     // 40 USD expenses
            ("EUR", 5.0, 150.0, 30),     // 30 EUR expenses
            ("GBP", 3.0, 120.0, 25),     // 25 GBP expenses
            ("INR", 100.0, 5000.0, 20),  // 20 INR expenses
            ("SAR", 10.0, 400.0, 15)     // 15 SAR expenses
        ]

        for config in currencyConfigs {
            for i in 0..<config.count {
                let expense = Expense(context: viewContext)
                expense.id = UUID()

                // Random amount within range
                let amount = Double.random(in: config.minAmount...config.maxAmount)
                expense.amount = NSDecimalNumber(value: round(amount * 100) / 100)
                expense.currency = config.code

                // Random category
                let category = categories.randomElement()!
                expense.category = category

                // Random merchant from category
                let merchants = merchantsByCategory[category] ?? ["Merchant"]
                expense.merchant = merchants.randomElement()

                // Varied dates over past 90 days
                let daysAgo = Int.random(in: 0...90)
                expense.transactionDate = calendar.date(byAdding: .day, value: -daysAgo, to: today)

                expense.createdAt = Date()
                expense.updatedAt = Date()
                expense.source = "manual"
                expense.status = "active"
                expense.isRecurring = false
            }
        }

        do {
            try viewContext.save()
        } catch {
            XCTFail("Failed to save pagination test data: \(error)")
        }
    }

    // MARK: - Pagination Tests

    /**
     * Test 1: Initial page load returns exactly 20 expenses
     *
     * Verifies:
     * - First page contains 20 items
     * - hasMore flag is true (more pages available)
     * - currentPage is 0
     */
    @MainActor
    func testInitialPageLoad_loads20Expenses() async throws {
        // Given: 180 AED expenses in database (50 AED from test data)

        // When: Load first page for AED currency
        await viewModel.loadFirstPage(currency: "AED", dateFilter: .all)

        // Then: Should load exactly 20 expenses
        XCTAssertEqual(20, viewModel.paginationState.loadedExpenses.count, "First page should contain 20 expenses")
        XCTAssertTrue(viewModel.paginationState.hasMore, "Should have more pages available")
        XCTAssertEqual(0, viewModel.paginationState.currentPage, "Current page should be 0")
    }

    /**
     * Test 2: Loading next page appends additional 20 expenses
     *
     * Verifies:
     * - Total count increases to 40 after loading second page
     * - No duplicate expenses
     * - Expenses are in correct order (newest first)
     */
    @MainActor
    func testLoadNextPage_appendsNextPageExpenses() async throws {
        // Given: Initial page loaded (20 expenses)
        await viewModel.loadFirstPage(currency: "AED", dateFilter: .all)

        let initialState = viewModel.paginationState
        let page1Ids = Set(initialState.loadedExpenses.map { $0.id })

        // When: Load next page
        await viewModel.loadNextPage()

        // Then: Should have 40 total expenses
        let updatedState = viewModel.paginationState
        XCTAssertEqual(40, updatedState.loadedExpenses.count, "Should have 40 expenses after loading page 2")

        // Verify no duplicates
        let uniqueIds = Set(updatedState.loadedExpenses.map { $0.id })
        XCTAssertEqual(40, uniqueIds.count, "All expenses should be unique (no duplicates)")

        // Verify expenses from page 2 are new
        let page2Expenses = Array(updatedState.loadedExpenses.dropFirst(20))
        let page2Ids = Set(page2Expenses.map { $0.id })
        XCTAssertEqual(0, page1Ids.intersection(page2Ids).count, "Page 2 should not contain expenses from page 1")

        // Verify correct order (newest first)
        for i in 0..<(updatedState.loadedExpenses.count - 1) {
            let current = updatedState.loadedExpenses[i]
            let next = updatedState.loadedExpenses[i + 1]
            XCTAssertTrue(
                current.transactionDate ?? Date() >= next.transactionDate ?? Date(),
                "Expenses should be ordered by date (newest first)"
            )
        }
    }

    /**
     * Test 3: Pagination loads all 50 AED expenses across 3 pages
     *
     * Note: Test data creates 50 AED expenses (3 pages: 20+20+10)
     */
    @MainActor
    func testPagination_loads50AEDExpenses_inThreePages() async throws {
        // Given: 50 AED expenses (from test data generator)
        await viewModel.loadFirstPage(currency: "AED", dateFilter: .all)

        // When: Load all pages for AED
        while viewModel.paginationState.hasMore {
            await viewModel.loadNextPage()
        }

        // Then: Should have loaded all 50 AED expenses
        let finalState = viewModel.paginationState
        XCTAssertEqual(50, finalState.loadedExpenses.count, "Should load all 50 AED expenses")
        XCTAssertFalse(finalState.hasMore, "Should have no more pages after loading all expenses")

        // Verify all are AED currency
        XCTAssertTrue(
            finalState.loadedExpenses.allSatisfy { $0.currency == "AED" },
            "All loaded expenses should be AED currency"
        )

        // Verify no duplicates
        let uniqueIds = Set(finalState.loadedExpenses.map { $0.id })
        XCTAssertEqual(50, uniqueIds.count, "All 50 expenses should be unique")
    }

    /**
     * Test 4: Pagination respects currency filter
     *
     * Verifies:
     * - Only USD expenses loaded when filtering by USD
     * - Correct page count for filtered set (40 USD = 2 pages)
     * - No expenses from other currencies
     */
    @MainActor
    func testPagination_respectsCurrencyFilter() async throws {
        // Given: 180 expenses across 6 currencies (USD has 40 expenses)

        // When: Load pages filtered by USD
        await viewModel.loadFirstPage(currency: "USD", dateFilter: .all)

        // Load all USD pages
        while viewModel.paginationState.hasMore {
            await viewModel.loadNextPage()
        }

        // Then: Should have exactly 40 USD expenses (2 pages)
        let finalState = viewModel.paginationState
        XCTAssertEqual(40, finalState.loadedExpenses.count, "Should load all 40 USD expenses")

        // Verify all are USD currency
        XCTAssertTrue(
            finalState.loadedExpenses.allSatisfy { $0.currency == "USD" },
            "All expenses should be USD currency"
        )

        // Verify no other currencies present
        let currencies = Set(finalState.loadedExpenses.map { $0.currency })
        XCTAssertEqual(Set(["USD"]), currencies, "Only USD currency should be present")

        // Verify pagination worked (should have been 2 pages: 20+20)
        XCTAssertFalse(finalState.hasMore, "Should have no more pages after loading all USD expenses")
    }

    /**
     * Test 5: Pagination respects date filter (Today)
     *
     * Verifies:
     * - Only today's expenses loaded when filtering by "Today"
     * - Pagination works with filtered subset
     * - Date filter + pagination combined correctly
     */
    @MainActor
    func testPagination_respectsDateFilter_todayFilter() async throws {
        // Given: 180 expenses spread over 90 days

        // When: Apply "Today" filter and load pages for AED
        await viewModel.loadFirstPage(currency: "AED", dateFilter: .today)

        // Load all pages (may be less than 20 if few expenses today)
        while viewModel.paginationState.hasMore {
            await viewModel.loadNextPage()
        }

        // Then: All expenses should be from today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let finalState = viewModel.paginationState

        XCTAssertTrue(
            finalState.loadedExpenses.allSatisfy { expense in
                guard let expenseDate = expense.transactionDate else { return false }
                return calendar.isDate(expenseDate, inSameDayAs: today)
            },
            "All expenses should be from today"
        )

        // Verify pagination stopped correctly
        XCTAssertFalse(finalState.hasMore, "Should have no more pages")

        // Note: Count may vary depending on how many expenses fall on today's date
        // Just verify we got a list (may be empty if no expenses today in test data)
        XCTAssertNotNil(finalState.loadedExpenses, "Should return a list (may be empty if no expenses today)")
    }

    /**
     * Test 6: End of list does not attempt to load more
     *
     * Verifies:
     * - Last page may have fewer than 20 items
     * - hasMore becomes false after last page
     * - Attempting to load beyond end returns empty result
     */
    @MainActor
    func testEndOfList_doesNotLoadMore() async throws {
        // Given: 50 AED expenses (3 pages: 20+20+10)
        await viewModel.loadFirstPage(currency: "AED", dateFilter: .all)
        var pageCount = 1

        // When: Load all pages until end
        while viewModel.paginationState.hasMore {
            await viewModel.loadNextPage()
            pageCount += 1
        }

        // Then: Should have loaded 3 pages (20+20+10 = 50 total)
        XCTAssertEqual(3, pageCount, "Should have loaded exactly 3 pages")
        XCTAssertEqual(50, viewModel.paginationState.loadedExpenses.count, "Should have all 50 expenses")
        XCTAssertFalse(viewModel.paginationState.hasMore, "Should have no more pages")

        // When: Attempt to load another page beyond end
        let initialSize = viewModel.paginationState.loadedExpenses.count
        await viewModel.loadNextPage()

        // Then: Size should not change (no new expenses loaded)
        XCTAssertEqual(initialSize, viewModel.paginationState.loadedExpenses.count, "Should not load more expenses beyond end")
        XCTAssertFalse(viewModel.paginationState.hasMore, "Should still have no more pages")
    }

    /**
     * Test 7: Empty list handles gracefully
     *
     * Verifies:
     * - Empty database returns empty list
     * - hasMore is false
     * - No errors thrown
     */
    @MainActor
    func testEmptyList_handlesGracefully() async throws {
        // Given: Empty database (no expenses)
        clearAllExpenses()

        // When: Load first page
        await viewModel.loadFirstPage(currency: "AED", dateFilter: .all)

        // Then: Should return empty list without errors
        XCTAssertEqual(0, viewModel.paginationState.loadedExpenses.count, "Should return empty list")
        XCTAssertFalse(viewModel.paginationState.hasMore, "Should have no more pages")
        XCTAssertEqual(0, viewModel.paginationState.currentPage, "Current page should be 0")
    }

    /**
     * Test 8: Multi-currency pagination maintains independent states
     *
     * Verifies:
     * - AED pagination state is separate from USD
     * - Switching currency starts fresh pagination
     * - Returning to previous currency preserves its state
     */
    @MainActor
    func testMultiCurrency_paginationIndependent() async throws {
        // Given: Expenses in multiple currencies

        // When: Load AED page 1
        await viewModel.loadFirstPage(currency: "AED", dateFilter: .all)
        let aedState1 = viewModel.paginationState
        let aedPage1Ids = Set(aedState1.loadedExpenses.map { $0.id })

        XCTAssertEqual(20, aedState1.loadedExpenses.count, "AED should load 20 expenses")
        XCTAssertTrue(
            aedState1.loadedExpenses.allSatisfy { $0.currency == "AED" },
            "All expenses should be AED"
        )

        // When: Switch to USD and load page 1
        await viewModel.loadFirstPage(currency: "USD", dateFilter: .all)
        let usdState1 = viewModel.paginationState

        // Then: USD should show fresh data (not AED data)
        XCTAssertEqual(20, usdState1.loadedExpenses.count, "USD should load 20 expenses")
        XCTAssertTrue(
            usdState1.loadedExpenses.allSatisfy { $0.currency == "USD" },
            "All expenses should be USD"
        )

        // Verify no overlap with AED expenses
        let usdPage1Ids = Set(usdState1.loadedExpenses.map { $0.id })
        XCTAssertEqual(
            0,
            aedPage1Ids.intersection(usdPage1Ids).count,
            "USD expenses should not overlap with AED expenses"
        )

        // When: Switch back to AED
        await viewModel.loadFirstPage(currency: "AED", dateFilter: .all)
        let aedState2 = viewModel.paginationState

        // Then: AED should show same data as before (state could be preserved or reloaded)
        // Note: Depending on implementation, state may be preserved or fetched fresh
        // Both behaviors are acceptable, just verify we get AED data
        XCTAssertTrue(
            aedState2.loadedExpenses.allSatisfy { $0.currency == "AED" },
            "Should show AED expenses when switching back"
        )

        XCTAssertEqual(20, aedState2.loadedExpenses.count, "Should load 20 AED expenses")
    }
}

// MARK: - Pagination State Model

/// Data class representing pagination state
/// Note: This should match the actual PaginationState in your ViewModel
/// Adjust properties as needed to match your implementation
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
