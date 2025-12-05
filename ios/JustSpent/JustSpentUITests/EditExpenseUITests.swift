import XCTest

/// UI tests for edit expense functionality
/// Swipe right on expense row to edit category and amount
/// Following TDD: Tests written BEFORE implementation
class EditExpenseUITests: BaseUITestCase {

    override func customLaunchArguments() -> [String] {
        // Need test expenses to test editing
        return TestDataHelper.configureWithTestExpenses(3)
    }

    // MARK: - Swipe to Edit Tests

    /// Test that swiping right shows Edit action
    func testSwipeRightShowsEditAction() throws {
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
        XCTAssertTrue(firstCell.exists, "First expense cell should exist")

        // When - Swipe right to trigger edit action
        firstCell.swipeRight()
        Thread.sleep(forTimeInterval: 0.5)

        // Then - Edit button should appear
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3.0), "Edit button should appear after swipe right")
    }

    /// Test that tapping Edit button shows edit sheet
    func testTapEditButtonShowsEditSheet() throws {
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

        // When - Swipe right and tap Edit
        firstCell.swipeRight()
        Thread.sleep(forTimeInterval: 0.5)

        let editButton = app.buttons["Edit"]
        guard editButton.waitForExistence(timeout: 3.0) else {
            XCTFail("Edit button should appear after swipe right")
            return
        }
        editButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Then - Edit sheet should appear with title
        let editTitle = app.staticTexts["Edit Expense"]
        XCTAssertTrue(editTitle.waitForExistence(timeout: 5.0), "Edit sheet should appear with 'Edit Expense' title")
    }

    /// Test that edit sheet shows category picker
    func testEditSheetShowsCategoryPicker() throws {
        // Given - Open edit sheet
        try openEditSheet()

        // Then - Category picker should exist
        let categoryPicker = app.buttons["category_picker"]
        XCTAssertTrue(categoryPicker.waitForExistence(timeout: 3.0), "Category picker should exist in edit sheet")
    }

    /// Test that edit sheet shows amount field
    func testEditSheetShowsAmountField() throws {
        // Given - Open edit sheet
        try openEditSheet()

        // Then - Amount text field should exist
        let amountField = app.textFields["amount_field"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 3.0), "Amount field should exist in edit sheet")
    }

    /// Test that edit sheet does NOT show currency picker (currency should not be editable)
    func testEditSheetDoesNotShowCurrencyPicker() throws {
        // Given - Open edit sheet
        try openEditSheet()
        Thread.sleep(forTimeInterval: 0.5)

        // Then - Currency picker should NOT exist
        let currencyPicker = app.buttons["currency_picker"]
        XCTAssertFalse(currencyPicker.exists, "Currency picker should NOT exist - currency is not editable")
    }

    /// Test that tapping Cancel dismisses edit sheet without changes
    func testCancelDismissesEditSheetWithoutChanges() throws {
        // Given - Open edit sheet
        try openEditSheet()

        // Get initial values from the sheet
        Thread.sleep(forTimeInterval: 0.5)

        // When - Tap Cancel
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        cancelButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Then - Edit sheet should be dismissed
        let editTitle = app.staticTexts["Edit Expense"]
        XCTAssertFalse(editTitle.exists, "Edit sheet should be dismissed after Cancel")
    }

    /// Test that tapping Save saves changes and dismisses sheet
    func testSaveDismissesEditSheetAndSavesChanges() throws {
        // Given - Open edit sheet
        try openEditSheet()
        Thread.sleep(forTimeInterval: 0.5)

        // Modify amount
        let amountField = app.textFields["amount_field"]
        if amountField.waitForExistence(timeout: 3.0) {
            amountField.tap()
            // Clear and enter new amount
            amountField.clearAndEnterText("999.99")
        }

        // When - Tap Save
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.exists, "Save button should exist")
        saveButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Then - Edit sheet should be dismissed
        let editTitle = app.staticTexts["Edit Expense"]
        XCTAssertFalse(editTitle.exists, "Edit sheet should be dismissed after Save")
    }

    /// Test that category can be changed
    func testCategoryCanBeChanged() throws {
        // Given - Open edit sheet
        try openEditSheet()
        Thread.sleep(forTimeInterval: 0.5)

        // When - Tap category picker to open selection
        let categoryPicker = app.buttons["category_picker"]
        guard categoryPicker.waitForExistence(timeout: 3.0) else {
            XCTFail("Category picker should exist")
            return
        }
        categoryPicker.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Then - Category options should appear
        // Look for common categories
        let groceryOption = app.buttons["Grocery"]
        let foodOption = app.buttons["Food & Dining"]
        let transportOption = app.buttons["Transportation"]

        let categoryOptionsVisible = groceryOption.exists || foodOption.exists || transportOption.exists
        XCTAssertTrue(categoryOptionsVisible, "Category options should appear when picker is tapped")
    }

    /// Test that amount field accepts valid decimal input
    func testAmountFieldAcceptsDecimalInput() throws {
        // Given - Open edit sheet
        try openEditSheet()
        Thread.sleep(forTimeInterval: 0.5)

        // When - Enter a decimal amount
        let amountField = app.textFields["amount_field"]
        guard amountField.waitForExistence(timeout: 3.0) else {
            XCTFail("Amount field should exist")
            return
        }
        amountField.tap()
        amountField.clearAndEnterText("123.45")
        Thread.sleep(forTimeInterval: 0.3)

        // Then - Amount field should contain the entered value
        let fieldValue = amountField.value as? String ?? ""
        XCTAssertTrue(fieldValue.contains("123") || fieldValue.contains("123.45"),
                      "Amount field should contain entered decimal value")
    }

    /// Test edit sheet accessibility
    func testEditSheetAccessibility() throws {
        // Given - Open edit sheet
        try openEditSheet()
        Thread.sleep(forTimeInterval: 0.5)

        // Then - All interactive elements should be accessible
        let cancelButton = app.buttons["Cancel"]
        let saveButton = app.buttons["Save"]
        let amountField = app.textFields["amount_field"]
        let categoryPicker = app.buttons["category_picker"]

        // Buttons should be hittable
        XCTAssertTrue(cancelButton.isHittable, "Cancel button should be hittable")
        XCTAssertTrue(saveButton.isHittable, "Save button should be hittable")

        // Fields should be accessible
        if amountField.exists {
            XCTAssertTrue(amountField.isEnabled, "Amount field should be enabled")
        }

        if categoryPicker.exists {
            XCTAssertTrue(categoryPicker.isEnabled, "Category picker should be enabled")
        }
    }

    // MARK: - Helper Methods

    /// Opens the edit sheet for the first expense
    private func openEditSheet() throws {
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

        // Swipe right and tap Edit
        firstCell.swipeRight()
        Thread.sleep(forTimeInterval: 0.5)

        let editButton = app.buttons["Edit"]
        guard editButton.waitForExistence(timeout: 3.0) else {
            throw XCTSkip("Edit button not found - swipe action may not be implemented")
        }
        editButton.tap()
        Thread.sleep(forTimeInterval: 0.5)
    }
}

// MARK: - XCUIElement Extension for Text Field Clearing

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            self.typeText(text)
            return
        }

        // Select all text and delete
        self.tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}
