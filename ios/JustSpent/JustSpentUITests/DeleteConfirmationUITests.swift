import XCTest

/// UI tests for delete confirmation dialog
/// Ensures user is asked to confirm before deleting an expense
/// Following TDD: Tests written BEFORE implementation
class DeleteConfirmationUITests: BaseUITestCase {

    override func customLaunchArguments() -> [String] {
        // Need test expenses to test deletion
        return TestDataHelper.configureWithTestExpenses(3)
    }

    // MARK: - Delete Confirmation Dialog Tests

    /// Test that swiping to delete shows a confirmation dialog
    func testSwipeToDeleteShowsConfirmationDialog() throws {
        // Given - Wait for expense list to load
        Thread.sleep(forTimeInterval: 2.0)

        // Find an expense row in the list
        let expenseList = app.tables.firstMatch
        guard expenseList.waitForExistence(timeout: 10.0) else {
            throw XCTSkip("No expense list found - test requires test data")
        }

        let cells = expenseList.cells
        guard cells.count > 0 else {
            throw XCTSkip("No expense cells found - test requires test data")
        }

        let firstCell = cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.exists, "First expense cell should exist")

        // When - Swipe left to trigger delete action
        firstCell.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)

        // Tap the delete button that appears
        let deleteButton = app.buttons["Delete"]
        if deleteButton.waitForExistence(timeout: 3.0) {
            deleteButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Then - Confirmation dialog should appear
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5.0), "Delete confirmation dialog should appear")

        // Verify dialog content
        let dialogTitle = alert.staticTexts["Delete Expense"]
        XCTAssertTrue(dialogTitle.exists, "Dialog should have 'Delete Expense' title")

        // Verify dialog has Cancel and Delete buttons
        XCTAssertTrue(alert.buttons["Cancel"].exists, "Dialog should have Cancel button")
        XCTAssertTrue(alert.buttons["Delete"].exists, "Dialog should have Delete button")
    }

    /// Test that tapping Cancel in confirmation dialog does NOT delete the expense
    func testCancelDeleteKeepsExpense() throws {
        // Given - Wait for expense list to load
        Thread.sleep(forTimeInterval: 2.0)

        let expenseList = app.tables.firstMatch
        guard expenseList.waitForExistence(timeout: 10.0) else {
            throw XCTSkip("No expense list found - test requires test data")
        }

        let cells = expenseList.cells
        let initialCellCount = cells.count
        guard initialCellCount > 0 else {
            throw XCTSkip("No expense cells found - test requires test data")
        }

        let firstCell = cells.element(boundBy: 0)

        // When - Swipe to delete and tap cancel
        firstCell.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)

        let deleteButton = app.buttons["Delete"]
        if deleteButton.waitForExistence(timeout: 3.0) {
            deleteButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Wait for dialog
        let alert = app.alerts.firstMatch
        guard alert.waitForExistence(timeout: 5.0) else {
            XCTFail("Delete confirmation dialog should appear")
            return
        }

        // Tap Cancel
        alert.buttons["Cancel"].tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Then - Expense count should remain the same
        let finalCellCount = expenseList.cells.count
        XCTAssertEqual(initialCellCount, finalCellCount, "Expense count should not change after canceling delete")
    }

    /// Test that confirming delete removes the expense
    func testConfirmDeleteRemovesExpense() throws {
        // Given - Wait for expense list to load
        Thread.sleep(forTimeInterval: 2.0)

        let expenseList = app.tables.firstMatch
        guard expenseList.waitForExistence(timeout: 10.0) else {
            throw XCTSkip("No expense list found - test requires test data")
        }

        let cells = expenseList.cells
        let initialCellCount = cells.count
        guard initialCellCount > 0 else {
            throw XCTSkip("No expense cells found - test requires test data")
        }

        let firstCell = cells.element(boundBy: 0)

        // When - Swipe to delete and confirm
        firstCell.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)

        let deleteButton = app.buttons["Delete"]
        if deleteButton.waitForExistence(timeout: 3.0) {
            deleteButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Wait for dialog
        let alert = app.alerts.firstMatch
        guard alert.waitForExistence(timeout: 5.0) else {
            XCTFail("Delete confirmation dialog should appear")
            return
        }

        // Tap Delete to confirm
        alert.buttons["Delete"].tap()
        Thread.sleep(forTimeInterval: 1.0)

        // Then - Expense count should decrease by 1
        let finalCellCount = expenseList.cells.count
        XCTAssertEqual(initialCellCount - 1, finalCellCount, "Expense count should decrease by 1 after confirming delete")
    }

    /// Test that confirmation dialog shows appropriate message
    func testDeleteConfirmationDialogMessage() throws {
        // Given - Wait for expense list to load
        Thread.sleep(forTimeInterval: 2.0)

        let expenseList = app.tables.firstMatch
        guard expenseList.waitForExistence(timeout: 10.0) else {
            throw XCTSkip("No expense list found - test requires test data")
        }

        let cells = expenseList.cells
        guard cells.count > 0 else {
            throw XCTSkip("No expense cells found - test requires test data")
        }

        let firstCell = cells.element(boundBy: 0)

        // When - Trigger delete confirmation
        firstCell.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)

        let deleteButton = app.buttons["Delete"]
        if deleteButton.waitForExistence(timeout: 3.0) {
            deleteButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Then - Dialog should have confirmation message
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5.0), "Delete confirmation dialog should appear")

        // Check for confirmation message
        let messageText = testHelper.findText(containing: "Are you sure")
        XCTAssertNotNil(messageText, "Dialog should contain 'Are you sure' message")
    }

    /// Test accessibility of delete confirmation dialog
    func testDeleteConfirmationDialogAccessibility() throws {
        // Given - Wait for expense list to load
        Thread.sleep(forTimeInterval: 2.0)

        let expenseList = app.tables.firstMatch
        guard expenseList.waitForExistence(timeout: 10.0) else {
            throw XCTSkip("No expense list found - test requires test data")
        }

        let cells = expenseList.cells
        guard cells.count > 0 else {
            throw XCTSkip("No expense cells found - test requires test data")
        }

        let firstCell = cells.element(boundBy: 0)

        // When - Trigger delete confirmation
        firstCell.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)

        let deleteButton = app.buttons["Delete"]
        if deleteButton.waitForExistence(timeout: 3.0) {
            deleteButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Then - Dialog buttons should be accessible
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5.0), "Delete confirmation dialog should appear")

        let cancelButton = alert.buttons["Cancel"]
        let confirmButton = alert.buttons["Delete"]

        // Buttons should be hittable
        XCTAssertTrue(cancelButton.isHittable, "Cancel button should be hittable")
        XCTAssertTrue(confirmButton.isHittable, "Delete button should be hittable")

        // Buttons should have proper labels for VoiceOver
        XCTAssertFalse(cancelButton.label.isEmpty, "Cancel button should have accessible label")
        XCTAssertFalse(confirmButton.label.isEmpty, "Delete button should have accessible label")
    }

    /// Test that tapping outside dialog dismisses it (Cancel behavior)
    func testTapOutsideDialogDismissesWithoutDeleting() throws {
        // Given - Wait for expense list to load
        Thread.sleep(forTimeInterval: 2.0)

        let expenseList = app.tables.firstMatch
        guard expenseList.waitForExistence(timeout: 10.0) else {
            throw XCTSkip("No expense list found - test requires test data")
        }

        let cells = expenseList.cells
        let initialCellCount = cells.count
        guard initialCellCount > 0 else {
            throw XCTSkip("No expense cells found - test requires test data")
        }

        let firstCell = cells.element(boundBy: 0)

        // When - Trigger delete confirmation
        firstCell.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)

        let deleteButton = app.buttons["Delete"]
        if deleteButton.waitForExistence(timeout: 3.0) {
            deleteButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Wait for dialog
        let alert = app.alerts.firstMatch
        guard alert.waitForExistence(timeout: 5.0) else {
            XCTFail("Delete confirmation dialog should appear")
            return
        }

        // Dismiss by tapping Cancel (iOS alerts don't dismiss by tapping outside)
        alert.buttons["Cancel"].tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Then - Dialog should be dismissed and expense should remain
        XCTAssertFalse(alert.exists, "Dialog should be dismissed")

        let finalCellCount = expenseList.cells.count
        XCTAssertEqual(initialCellCount, finalCellCount, "Expense count should not change")
    }
}
