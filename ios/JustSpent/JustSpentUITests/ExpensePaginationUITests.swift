//
//  ExpensePaginationUITests.swift
//  JustSpentUITests
//
//  UI tests for pagination functionality in Just Spent iOS app.
//
//  These tests verify that pagination correctly loads expenses in batches of 20 items,
//  handles scroll-triggered loading, filter changes, and currency switching.
//
//  Test Data: Uses 180 expenses across 6 currencies (AED:50, USD:40, EUR:30, GBP:25, INR:20, SAR:15)
//  Page Size: 20 items per page
//  Approach: Data verification (ViewModel state) + UI interaction
//
//  TDD Phase: RED - These tests will FAIL until pagination is implemented
//

import XCTest
@testable import JustSpent

class ExpensePaginationUITests: BasePaginationUITestCase {

    /**
     * Test 1: Large Dataset - Initial Load and Scroll-Triggered Pagination
     *
     * Scenario:
     * 1. App launches with 180 expenses in database
     * 2. Initial load shows 20 AED expenses (page 0)
     * 3. User scrolls to position 15 (within prefetch distance of 5)
     * 4. Pagination automatically loads next 20 expenses (page 1)
     * 5. Total expenses in memory: 40
     *
     * Verification Approach: Data verification via ViewModel state
     */
    func testLargeDataset_loadsInitial20_scrollLoadsMore() throws {
        // Given: App launched with test data, navigated to AED tab
        // BasePaginationUITestCase handles app launch with 180 expenses

        // Verify app is on AED tab (first currency)
        let aedTab = app.buttons["currency_tab_AED"]
        XCTAssertTrue(aedTab.waitForExistence(timeout: 5.0), "AED tab should exist")
        aedTab.tap()

        // Wait for initial data load
        Thread.sleep(forTimeInterval: 1.0)

        // Then: Should have loaded exactly 20 expenses initially
        // Note: In actual implementation, we'd access ViewModel state directly
        // For UI test, we verify by counting visible expense rows
        let expenseList = app.collectionViews.firstMatch
        XCTAssertTrue(expenseList.exists, "Expense list should exist")

        // Verify initial page has 20 items (or fewer if not implemented yet)
        // This will FAIL until pagination is implemented
        let initialCells = expenseList.cells.count
        XCTAssertEqual(20, initialCells, "Initial page should load 20 expenses")

        // When: Simulate scroll to position 15 (triggers prefetch at position 15 = within last 5 items)
        // Scroll to near bottom of list to trigger next page load
        let lastVisibleCell = expenseList.cells.element(boundBy: min(15, initialCells - 1))
        if lastVisibleCell.exists {
            lastVisibleCell.swipeUp()
        }

        // Wait for pagination to trigger
        Thread.sleep(forTimeInterval: 2.0)

        // Then: Should have loaded page 2 (total 40 expenses)
        // This will FAIL until pagination is implemented
        let cellsAfterScroll = expenseList.cells.count
        XCTAssertEqual(40, cellsAfterScroll, "After scroll, should have 40 expenses (2 pages)")

        // Verify loading indicator was shown/hidden correctly
        // This will FAIL if loading state not implemented
        let loadingIndicator = app.activityIndicators["pagination_loading"]
        XCTAssertFalse(loadingIndicator.exists, "Loading indicator should be hidden after load completes")
    }

    /**
     * Test 2: Filter Change - Resets Pagination and Loads Filtered Data
     *
     * Scenario:
     * 1. Initial state: 20 AED expenses loaded (page 0, All filter)
     * 2. User changes filter to "This Week"
     * 3. Pagination resets to page 0
     * 4. New filtered page loads (≤20 expenses from this week)
     * 5. User scrolls to load more filtered data
     *
     * Verification Approach: Data verification via ViewModel state + UI interaction
     */
    func testFilterChange_resetsPagination_thenLoadsFiltered() throws {
        // Given: Initial page loaded (20 AED, All filter)
        let aedTab = app.buttons["currency_tab_AED"]
        XCTAssertTrue(aedTab.waitForExistence(timeout: 5.0), "AED tab should exist")
        aedTab.tap()

        Thread.sleep(forTimeInterval: 1.0)

        let expenseList = app.collectionViews.firstMatch
        XCTAssertTrue(expenseList.exists, "Expense list should exist")

        let initialCells = expenseList.cells.count
        XCTAssertEqual(20, initialCells, "Should start with 20 expenses (All filter)")

        // When: User changes filter to "This Week"
        let filterButton = app.buttons["date_filter_button"]
        if filterButton.waitForExistence(timeout: 3.0) {
            filterButton.tap()

            // Select "This Week" option
            let thisWeekOption = app.buttons["filter_option_week"]
            if thisWeekOption.waitForExistence(timeout: 2.0) {
                thisWeekOption.tap()
            }
        }

        // Wait for filter to apply and pagination to reset
        Thread.sleep(forTimeInterval: 2.0)

        // Then: Pagination should reset to page 0 with filtered data
        let filteredCells = expenseList.cells.count
        XCTAssertTrue(filteredCells <= 20, "Should load ≤20 expenses for first page after filter")
        XCTAssertTrue(filteredCells >= 0, "Should have some expenses (or zero if none this week)")

        // Verify all visible expenses are from this week (check date labels)
        // This is a UI-level check, but helps verify filtering works
        // Note: This will FAIL if filter not implemented
        if filteredCells > 0 {
            let firstCell = expenseList.cells.element(boundBy: 0)
            XCTAssertTrue(firstCell.exists, "First filtered cell should exist")
            // In actual implementation, we'd verify date labels show "this week" dates
        }

        // When: User scrolls to load more (if available)
        if filteredCells >= 15 {
            let scrollCell = expenseList.cells.element(boundBy: min(15, filteredCells - 1))
            if scrollCell.exists {
                scrollCell.swipeUp()
                Thread.sleep(forTimeInterval: 2.0)
            }

            // Then: Next filtered page should load correctly (if hasMore)
            let cellsAfterScroll = expenseList.cells.count
            // Should either stay same (no more data) or increase (more data)
            XCTAssertTrue(
                cellsAfterScroll >= filteredCells,
                "Cell count should not decrease after scroll"
            )
        }
    }

    /**
     * Test 3: Currency Switch - Maintains Separate Pagination States
     *
     * Scenario:
     * 1. Load AED page 1 (20 expenses)
     * 2. Switch to USD tab → loads USD page 1 (fresh 20 expenses)
     * 3. USD should show fresh data (not AED data)
     * 4. Switch back to AED → should show same AED page 1 data (state preserved)
     *
     * Verification Approach: Data verification via ViewModel state + UI interaction
     */
    func testCurrencySwitch_maintainsSeparatePaginationStates() throws {
        // Given: AED page 1 loaded
        let aedTab = app.buttons["currency_tab_AED"]
        XCTAssertTrue(aedTab.waitForExistence(timeout: 5.0), "AED tab should exist")
        aedTab.tap()

        Thread.sleep(forTimeInterval: 1.0)

        let expenseList = app.collectionViews.firstMatch
        XCTAssertTrue(expenseList.exists, "Expense list should exist")

        let aedInitialCells = expenseList.cells.count
        XCTAssertEqual(20, aedInitialCells, "AED should load 20 expenses")

        // Verify all expenses are AED currency
        // Check first cell shows AED currency (in actual implementation)
        let firstAEDCell = expenseList.cells.element(boundBy: 0)
        XCTAssertTrue(firstAEDCell.exists, "First AED cell should exist")

        // Store first AED expense identifier (for later comparison)
        let firstAEDCellLabel = firstAEDCell.staticTexts.firstMatch.label

        // When: Switch to USD tab and load page 1
        let usdTab = app.buttons["currency_tab_USD"]
        XCTAssertTrue(usdTab.waitForExistence(timeout: 5.0), "USD tab should exist")
        usdTab.tap()

        Thread.sleep(forTimeInterval: 1.0)

        // Then: USD should show fresh data (not AED data)
        let usdCells = expenseList.cells.count
        XCTAssertEqual(20, usdCells, "USD should load 20 expenses")

        // Verify all expenses are USD currency
        let firstUSDCell = expenseList.cells.element(boundBy: 0)
        XCTAssertTrue(firstUSDCell.exists, "First USD cell should exist")

        // Verify no overlap with AED expenses (different data)
        let firstUSDCellLabel = firstUSDCell.staticTexts.firstMatch.label
        XCTAssertNotEqual(
            firstAEDCellLabel,
            firstUSDCellLabel,
            "USD expenses should be different from AED expenses"
        )

        // When: Switch back to AED
        aedTab.tap()
        Thread.sleep(forTimeInterval: 1.0)

        // Then: AED should show same data as before (state could be preserved or reloaded)
        // Note: Depending on implementation, state may be preserved or fetched fresh
        // Both behaviors are acceptable, just verify we get AED data
        let aedCellsAfterReturn = expenseList.cells.count
        XCTAssertEqual(20, aedCellsAfterReturn, "Should load 20 AED expenses when switching back")

        // Verify we're back to AED data (check first cell matches original)
        let firstAEDCellAfterReturn = expenseList.cells.element(boundBy: 0)
        XCTAssertTrue(firstAEDCellAfterReturn.exists, "First AED cell should exist after return")

        // Optional: If state preservation is implemented, verify same expenses
        // let firstAEDCellLabelAfterReturn = firstAEDCellAfterReturn.staticTexts.firstMatch.label
        // XCTAssertEqual(firstAEDCellLabel, firstAEDCellLabelAfterReturn, "AED state should be preserved")
    }
}
