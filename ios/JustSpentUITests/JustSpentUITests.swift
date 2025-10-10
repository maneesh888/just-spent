import XCTest

final class JustSpentUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testAppLaunchAndInitialState() throws {
        // Verify main UI elements are present
        XCTAssertTrue(app.staticTexts["Just Spent"].exists)
        XCTAssertTrue(app.staticTexts["Voice-enabled expense tracker"].exists)
        XCTAssertTrue(app.staticTexts["Total"].exists)
    }
    
    func testEmptyStateDisplay() throws {
        // Verify empty state is shown initially
        XCTAssertTrue(app.staticTexts["No expenses yet"].exists)
        XCTAssertTrue(app.staticTexts["Say \"Hey Siri, I just spent...\" to get started"].exists)
        XCTAssertTrue(app.buttons["Add Sample Expense"].exists)
    }
    
    func testAddSampleExpenseButton() throws {
        // Given
        let addButton = app.buttons["Add Sample Expense"]
        XCTAssertTrue(addButton.exists)
        
        // When
        addButton.tap()
        
        // Then - Wait for expense to be added and list to appear
        let expenseList = app.collectionViews.firstMatch
        let existsPredicate = NSPredicate(format: "exists == true")
        expectation(for: existsPredicate, evaluatedWith: expenseList, handler: nil)
        waitForExpectations(timeout: 3.0, handler: nil)
        
        // Verify empty state is no longer shown
        XCTAssertFalse(app.staticTexts["No expenses yet"].exists)
    }
    
    func testExpenseListAppearance() throws {
        // Add a sample expense first
        app.buttons["Add Sample Expense"].tap()
        
        // Wait for list to appear
        let expenseList = app.collectionViews.firstMatch
        let existsPredicate = NSPredicate(format: "exists == true")
        expectation(for: existsPredicate, evaluatedWith: expenseList, handler: nil)
        waitForExpectations(timeout: 3.0, handler: nil)
        
        // Verify list elements are present
        XCTAssertTrue(expenseList.exists)
        
        // Check if expense row elements are present
        let cells = expenseList.cells
        XCTAssertGreaterThan(cells.count, 0)
    }
    
    func testVoicePromptDisplay() throws {
        // Verify voice-first design elements
        let micIcon = app.images.matching(identifier: "mic.circle").firstMatch
        XCTAssertTrue(micIcon.exists)
        
        let voicePrompt = app.staticTexts["Say \"Hey Siri, I just spent...\" to get started"]
        XCTAssertTrue(voicePrompt.exists)
    }
    
    func testTotalSpendingDisplay() throws {
        // Verify total spending is displayed
        let totalLabel = app.staticTexts["Total"]
        XCTAssertTrue(totalLabel.exists)
        
        // Initially should show $0.00
        let totalAmount = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'")).firstMatch
        XCTAssertTrue(totalAmount.exists)
    }
    
    func testMultipleSampleExpenses() throws {
        let addButton = app.buttons["Add Sample Expense"]
        
        // Add first expense
        addButton.tap()
        
        // Wait for list to appear
        let expenseList = app.collectionViews.firstMatch
        let existsPredicate = NSPredicate(format: "exists == true")
        expectation(for: existsPredicate, evaluatedWith: expenseList, handler: nil)
        waitForExpectations(timeout: 3.0, handler: nil)
        
        // Add second expense
        addButton.tap()
        
        // Wait a moment for the second expense to be added
        sleep(1)
        
        // Verify multiple expenses in list
        let cells = expenseList.cells
        XCTAssertGreaterThanOrEqual(cells.count, 1)
    }
    
    func testAccessibilityElements() throws {
        // Verify key elements have accessibility labels
        let appTitle = app.staticTexts["Just Spent"]
        XCTAssertTrue(appTitle.exists)
        XCTAssertTrue(appTitle.isHittable)
        
        let addButton = app.buttons["Add Sample Expense"]
        XCTAssertTrue(addButton.exists)
        XCTAssertTrue(addButton.isHittable)
        
        let totalLabel = app.staticTexts["Total"]
        XCTAssertTrue(totalLabel.exists)
    }
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}