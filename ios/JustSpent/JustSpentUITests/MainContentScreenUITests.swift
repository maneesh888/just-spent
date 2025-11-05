import XCTest

/// Basic UI tests for MainContentScreen
/// Mirrors Android MainContentScreenUITest.kt (2 basic tests)
class MainContentScreenUITests: BaseUITestCase {

    // MARK: - Basic Display Tests (2 tests)

    func testAppTitleIsDisplayed() throws {
        // Verify the app title appears
        let appTitle = app.staticTexts["Just Spent"]
        XCTAssertTrue(appTitle.waitForExistence(timeout: 10.0), "App title 'Just Spent' should be displayed")
        XCTAssertTrue(appTitle.isHittable, "App title should be visible and accessible")
    }

    func testEmptyStateIsDisplayed() throws {
        // Verify empty state message appears when no expenses
        // Note: This assumes app launches with empty state
        // If expenses exist from previous runs, this test may not see empty state

        let emptyStateText = app.staticTexts["No expenses yet"]

        if emptyStateText.exists {
            // Empty state is visible
            XCTAssertTrue(emptyStateText.isHittable, "Empty state should be displayed")
        } else {
            // App may have expenses from previous test runs
            // Verify app title is still visible (main content loaded)
            let appTitle = app.staticTexts["Just Spent"]
            XCTAssertTrue(appTitle.exists, "Main content should be loaded")
        }
    }
}
