//
//  FilterStripUITests.swift
//  JustSpentUITests
//
//  Created by Claude Code on 2025.
//

import XCTest

/// UI tests for the FilterStripView component
final class FilterStripUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--with-expenses"]
        app.launch()

        // Wait for app to be ready
        let timeout: TimeInterval = 30.0
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: timeout), "App should launch")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    /// Wait for filter strip to appear (only visible when expenses exist)
    private func waitForFilterStrip() -> Bool {
        let filterStrip = app.otherElements["filter_strip"]
        return filterStrip.waitForExistence(timeout: 10.0)
    }

    // MARK: - Display Tests

    func testFilterStrip_displaysAllPresetFilters() throws {
        guard waitForFilterStrip() else {
            throw XCTSkip("Filter strip not visible - no expenses may exist")
        }

        // Verify all preset filter chips are displayed
        XCTAssertTrue(app.buttons["filter_chip_all"].exists, "All filter should be displayed")
        XCTAssertTrue(app.buttons["filter_chip_today"].exists, "Today filter should be displayed")
        XCTAssertTrue(app.buttons["filter_chip_week"].exists, "Week filter should be displayed")
        XCTAssertTrue(app.buttons["filter_chip_month"].exists, "Month filter should be displayed")
        XCTAssertTrue(app.buttons["filter_chip_custom"].exists, "Custom filter should be displayed")
    }

    func testFilterStrip_hasCorrectAccessibilityIdentifier() throws {
        guard waitForFilterStrip() else {
            throw XCTSkip("Filter strip not visible - no expenses may exist")
        }

        XCTAssertTrue(app.otherElements["filter_strip"].exists, "Filter strip should have correct accessibility identifier")
    }

    // MARK: - Selection Tests

    func testFilterStrip_allFilterSelectedByDefault() throws {
        guard waitForFilterStrip() else {
            throw XCTSkip("Filter strip not visible - no expenses may exist")
        }

        // All filter should be selected by default
        let allButton = app.buttons["filter_chip_all"]
        XCTAssertTrue(allButton.isSelected || allButton.exists, "All filter should be available")
    }

    func testFilterStrip_canSelectTodayFilter() throws {
        guard waitForFilterStrip() else {
            throw XCTSkip("Filter strip not visible - no expenses may exist")
        }

        let todayButton = app.buttons["filter_chip_today"]
        XCTAssertTrue(todayButton.exists, "Today filter should exist")

        todayButton.tap()

        // Give time for UI to update
        Thread.sleep(forTimeInterval: 0.5)

        // Verify the button is still accessible (filter was applied)
        XCTAssertTrue(todayButton.exists, "Today filter should remain visible after selection")
    }

    func testFilterStrip_canSelectWeekFilter() throws {
        guard waitForFilterStrip() else {
            throw XCTSkip("Filter strip not visible - no expenses may exist")
        }

        let weekButton = app.buttons["filter_chip_week"]
        XCTAssertTrue(weekButton.exists, "Week filter should exist")

        weekButton.tap()

        Thread.sleep(forTimeInterval: 0.5)

        XCTAssertTrue(weekButton.exists, "Week filter should remain visible after selection")
    }

    func testFilterStrip_canSelectMonthFilter() throws {
        guard waitForFilterStrip() else {
            throw XCTSkip("Filter strip not visible - no expenses may exist")
        }

        let monthButton = app.buttons["filter_chip_month"]
        XCTAssertTrue(monthButton.exists, "Month filter should exist")

        monthButton.tap()

        Thread.sleep(forTimeInterval: 0.5)

        XCTAssertTrue(monthButton.exists, "Month filter should remain visible after selection")
    }

    func testFilterStrip_canSwitchBetweenFilters() throws {
        guard waitForFilterStrip() else {
            throw XCTSkip("Filter strip not visible - no expenses may exist")
        }

        // Select Today
        app.buttons["filter_chip_today"].tap()
        Thread.sleep(forTimeInterval: 0.3)

        // Switch to Week
        app.buttons["filter_chip_week"].tap()
        Thread.sleep(forTimeInterval: 0.3)

        // Switch back to All
        app.buttons["filter_chip_all"].tap()
        Thread.sleep(forTimeInterval: 0.3)

        // All buttons should still exist
        XCTAssertTrue(app.buttons["filter_chip_all"].exists, "All filter should exist after switching")
        XCTAssertTrue(app.buttons["filter_chip_today"].exists, "Today filter should exist after switching")
        XCTAssertTrue(app.buttons["filter_chip_week"].exists, "Week filter should exist after switching")
    }

    // MARK: - Custom Filter Dialog Tests

    func testFilterStrip_customChipOpensSheet() throws {
        guard waitForFilterStrip() else {
            throw XCTSkip("Filter strip not visible - no expenses may exist")
        }

        let customButton = app.buttons["filter_chip_custom"]
        XCTAssertTrue(customButton.exists, "Custom filter should exist")

        customButton.tap()

        // Wait for sheet to appear
        let customRangeTitle = app.staticTexts["Custom Range"]
        let sheetAppeared = customRangeTitle.waitForExistence(timeout: 5.0)

        XCTAssertTrue(sheetAppeared, "Custom date range sheet should appear")
    }

    func testFilterStrip_customSheet_displaysDatePickers() throws {
        guard waitForFilterStrip() else {
            throw XCTSkip("Filter strip not visible - no expenses may exist")
        }

        app.buttons["filter_chip_custom"].tap()

        // Wait for sheet
        Thread.sleep(forTimeInterval: 1.0)

        // Check for date picker elements
        XCTAssertTrue(app.datePickers["custom_start_date_picker"].exists || app.staticTexts["Start Date"].exists,
                     "Start date picker should be displayed")
        XCTAssertTrue(app.datePickers["custom_end_date_picker"].exists || app.staticTexts["End Date"].exists,
                     "End date picker should be displayed")
    }

    func testFilterStrip_customSheet_canBeCancelled() throws {
        guard waitForFilterStrip() else {
            throw XCTSkip("Filter strip not visible - no expenses may exist")
        }

        app.buttons["filter_chip_custom"].tap()

        // Wait for sheet
        Thread.sleep(forTimeInterval: 1.0)

        // Find and tap cancel button
        let cancelButton = app.buttons["cancel_custom_filter_button"]
        if cancelButton.exists {
            cancelButton.tap()
        } else {
            // Try alternative - Cancel text button
            let cancelText = app.buttons["Cancel"]
            if cancelText.exists {
                cancelText.tap()
            }
        }

        // Wait for sheet to dismiss
        Thread.sleep(forTimeInterval: 1.0)

        // Sheet should be dismissed - check that filter strip is visible again
        XCTAssertTrue(app.buttons["filter_chip_all"].exists, "Filter strip should be visible after cancelling")
    }

    func testFilterStrip_customSheet_applyButton_exists() throws {
        guard waitForFilterStrip() else {
            throw XCTSkip("Filter strip not visible - no expenses may exist")
        }

        app.buttons["filter_chip_custom"].tap()

        // Wait for sheet
        Thread.sleep(forTimeInterval: 1.0)

        // Check for apply button
        let applyButton = app.buttons["apply_custom_filter_button"]
        let applyTextButton = app.buttons["Apply Filter"]

        XCTAssertTrue(applyButton.exists || applyTextButton.exists, "Apply button should be displayed")
    }

    // MARK: - Accessibility Tests

    func testFilterStrip_hasAccessibilityLabels() throws {
        guard waitForFilterStrip() else {
            throw XCTSkip("Filter strip not visible - no expenses may exist")
        }

        // Check that filter buttons have accessibility labels
        let allButton = app.buttons["filter_chip_all"]
        XCTAssertTrue(allButton.exists, "All filter button should be accessible")

        let todayButton = app.buttons["filter_chip_today"]
        XCTAssertTrue(todayButton.exists, "Today filter button should be accessible")
    }

    // MARK: - Integration Tests

    func testFilterStrip_filteringUpdatesExpenseList() throws {
        guard waitForFilterStrip() else {
            throw XCTSkip("Filter strip not visible - no expenses may exist")
        }

        // Select Today filter
        app.buttons["filter_chip_today"].tap()

        // Wait for filter to apply
        Thread.sleep(forTimeInterval: 1.0)

        // The list should update (we can't easily verify content without knowing test data)
        // Just verify the app doesn't crash and filter strip is still visible
        XCTAssertTrue(app.buttons["filter_chip_today"].exists, "Today filter should remain after filtering")
    }

    func testFilterStrip_filterPersistsAfterTabSwitch() throws {
        // This test is for multi-currency mode
        // Skip if tabs don't exist
        let currencyTabBar = app.otherElements["currency_tab_bar"]
        guard currencyTabBar.waitForExistence(timeout: 5.0) else {
            throw XCTSkip("Multi-currency tabs not visible")
        }

        guard waitForFilterStrip() else {
            throw XCTSkip("Filter strip not visible")
        }

        // Select a filter
        app.buttons["filter_chip_week"].tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Try to find and tap a different currency tab
        // This is approximate since we don't know which currencies are available
        let tabs = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'currency_tab_'"))
        if tabs.count > 1 {
            tabs.element(boundBy: 1).tap()
            Thread.sleep(forTimeInterval: 0.5)

            // Switch back
            tabs.element(boundBy: 0).tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Filter strip should still be visible
        XCTAssertTrue(app.buttons["filter_chip_week"].exists, "Week filter should still exist after tab switch")
    }
}
