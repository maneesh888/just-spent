//
//  TestDataHelper+Pagination.swift
//  JustSpentUITests
//
//  Pagination test data helper extension
//  Documents the 180-expense test dataset for pagination testing
//

import XCTest

/// Extension to TestDataHelper for pagination-specific test setup
extension TestDataHelper {

    // MARK: - Pagination Test Configuration

    /// Configure app with pagination test dataset (180 expenses)
    ///
    /// Uses TestDataManager.populateMultiCurrencyData() which creates:
    /// - AED: 50 expenses
    /// - USD: 40 expenses
    /// - EUR: 30 expenses
    /// - GBP: 25 expenses
    /// - INR: 20 expenses
    /// - SAR: 15 expenses
    /// - **Total: 180 expenses**
    ///
    /// Expenses are distributed over 90 days with varied categories and merchants.
    ///
    /// Usage:
    /// ```swift
    /// app.launchArguments = TestDataHelper.configurePaginationTestData()
    /// app.launch()
    /// ```
    ///
    /// - Returns: Launch arguments for pagination test mode
    static func configurePaginationTestData() -> [String] {
        // Uses existing --multi-currency flag which triggers TestDataManager.populateMultiCurrencyData()
        return ["--uitesting", "--skip-onboarding", "--multi-currency"]
    }

    /// Pagination test dataset specifications
    struct PaginationTestData {
        /// Total number of expenses in pagination test dataset
        static let totalExpenses = 180

        /// Number of expenses per currency
        static let expensesPerCurrency: [String: Int] = [
            "AED": 50,
            "USD": 40,
            "EUR": 30,
            "GBP": 25,
            "INR": 20,
            "SAR": 15
        ]

        /// Expected page size (items per page)
        static let pageSize = 20

        /// Expected number of pages for AED (50 expenses ÷ 20 per page)
        static let aedPageCount = 3  // Pages: 20, 20, 10

        /// Expected number of pages for USD (40 expenses ÷ 20 per page)
        static let usdPageCount = 2  // Pages: 20, 20

        /// Expected number of pages for EUR (30 expenses ÷ 20 per page)
        static let eurPageCount = 2  // Pages: 20, 10

        /// Expected number of pages for GBP (25 expenses ÷ 20 per page)
        static let gbpPageCount = 2  // Pages: 20, 5

        /// Expected number of pages for INR (20 expenses ÷ 20 per page)
        static let inrPageCount = 1  // Pages: 20

        /// Expected number of pages for SAR (15 expenses ÷ 20 per page)
        static let sarPageCount = 1  // Pages: 15

        /// Prefetch distance (items from end before loading next page)
        static let prefetchDistance = 5

        /// Date range for test data (days in past)
        static let dateRangeDays = 90
    }
}

/// Base test case for pagination tests
class BasePaginationUITestCase: XCTestCase {

    var app: XCUIApplication!
    var testHelper: TestDataHelper!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = TestDataHelper.configurePaginationTestData()
        app.launch()

        testHelper = TestDataHelper(app: app)

        // Wait for app to fully load with test data
        // Pagination dataset (180 expenses) may take longer to load

        NSLog("🧪 ========================================")
        NSLog("🧪 TEST SETUP: Waiting for app to launch")
        NSLog("🧪 ========================================")

        // First, wait for app to launch (check for any state)
        let appIsReady = app.wait(for: .runningForeground, timeout: 30.0)
        XCTAssertTrue(appIsReady, "App should launch")
        NSLog("🧪 ✅ App is running in foreground")

        // Give time for Core Data to populate and @FetchRequest to update
        NSLog("🧪 Waiting 10 seconds for test data to populate...")
        Thread.sleep(forTimeInterval: 10.0)
        NSLog("🧪 10-second wait complete")

        // Check all possible states
        NSLog("🧪 Checking app states:")
        let emptyState = app.otherElements["test_state_empty"]
        let singleState = app.otherElements["test_state_single_currency"]
        let multiState = app.otherElements["test_state_multi_currency"]

        NSLog("🧪   - Empty state exists: %d", emptyState.exists)
        NSLog("🧪   - Single currency exists: %d", singleState.exists)
        NSLog("🧪   - Multi currency exists: %d", multiState.exists)

        // Now check for multi-currency view
        // The app should switch from empty/single to multi-currency after data loads
        NSLog("🧪 Waiting up to 30 seconds for multi-currency state...")
        let foundMultiCurrency = multiState.waitForExistence(timeout: 30.0)

        if !foundMultiCurrency {
            // Debug: print all accessibility identifiers
            NSLog("🧪 ❌ Multi-currency view NOT FOUND after 30s wait")
            NSLog("🧪 Current app states:")
            NSLog("🧪   - Empty state exists: %d", emptyState.exists)
            NSLog("🧪   - Single currency exists: %d", singleState.exists)
            NSLog("🧪   - Multi currency exists: %d", multiState.exists)

            // List all accessibility identifiers we can find
            NSLog("🧪 All otherElements identifiers:")
            for element in app.otherElements.allElementsBoundByIndex {
                if !element.identifier.isEmpty {
                    NSLog("🧪   - %@", element.identifier)
                }
            }

            // Provide detailed failure message
            let actualState = emptyState.exists ? "EMPTY STATE" : (singleState.exists ? "SINGLE CURRENCY" : "UNKNOWN")
            XCTFail("App should show multi-currency view with 180 test expenses across 6 currencies, but showing: \(actualState). Empty=\(emptyState.exists), Single=\(singleState.exists), Multi=\(multiState.exists)")
        } else {
            NSLog("🧪 ✅ Multi-currency view found!")
        }

        XCTAssertTrue(foundMultiCurrency, "Multi-currency view should appear with test data")

        // Additional wait for UI to stabilize
        NSLog("🧪 Waiting 2 seconds for UI to stabilize...")
        Thread.sleep(forTimeInterval: 2.0)
        NSLog("🧪 ========================================")
        NSLog("🧪 TEST SETUP COMPLETE")
        NSLog("🧪 ========================================")
    }

    override func tearDownWithError() throws {
        app = nil
        testHelper = nil
        try super.tearDownWithError()
    }
}

/// Helper extension for pagination-specific assertions
extension XCTestCase {

    /// Verify pagination state matches expected values
    ///
    /// - Parameters:
    ///   - currentPage: Expected current page number (0-based)
    ///   - loadedCount: Expected number of loaded expenses
    ///   - hasMore: Expected hasMore flag value
    func assertPaginationState(
        currentPage: Int,
        loadedCount: Int,
        hasMore: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Note: Actual implementation will depend on how pagination state is exposed in the UI
        // This is a placeholder for pagination state verification
        // Real implementation should query ViewModel state or UI elements that reflect pagination state

        // For data verification approach:
        // 1. Access ViewModel instance
        // 2. Check paginationState.currentPage
        // 3. Check paginationState.loadedExpenses.count
        // 4. Check paginationState.hasMore

        // For UI verification approach:
        // 1. Count visible expense rows
        // 2. Check for "Load More" button existence
        // 3. Check loading indicator state
    }

    /// Verify expense list contains expected number of items
    ///
    /// - Parameter expectedCount: Expected number of expense items in the list
    func assertExpenseListCount(
        _ expectedCount: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Note: This is a placeholder for expense list count verification
        // Real implementation should query the UI for expense row elements
        // Example: app.cells.matching(identifier: "expense_row").count
    }
}
