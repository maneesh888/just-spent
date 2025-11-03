import XCTest

/// Helper class for managing test data in UI tests
/// Mirrors functionality from Android TestDataHelper.kt
class TestDataHelper {

    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Launch Argument Helpers

    /// Configure app to skip onboarding for tests
    static func configureSkipOnboarding() -> [String] {
        return ["--uitesting", "--skip-onboarding"]
    }

    /// Configure app to show onboarding for tests
    static func configureShowOnboarding() -> [String] {
        return ["--uitesting", "--show-onboarding"]
    }

    /// Configure app with test expenses
    static func configureWithTestExpenses(_ count: Int = 5) -> [String] {
        return ["--uitesting", "--test-expenses=\(count)"]
    }

    /// Configure app with multiple currencies
    static func configureWithMultiCurrency() -> [String] {
        return ["--uitesting", "--multi-currency"]
    }

    /// Configure app with empty state
    static func configureWithEmptyState() -> [String] {
        return ["--uitesting", "--empty-state"]
    }

    // MARK: - Wait Helpers

    /// Wait for element with custom timeout
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 10.0) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    /// Wait for element to disappear
    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 10.0) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    /// Wait for app to be idle
    func waitForAppIdle() {
        Thread.sleep(forTimeInterval: 0.5)
    }

    // MARK: - Query Helpers

    /// Find button by accessibility identifier with fallback
    func findButton(identifier: String, fallbackLabel: String? = nil) -> XCUIElement {
        let button = app.buttons[identifier]
        if button.exists {
            return button
        }

        if let label = fallbackLabel {
            return app.buttons[label]
        }

        return button
    }

    /// Find text element by substring
    func findText(containing substring: String) -> XCUIElement? {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", substring)
        let matches = app.staticTexts.matching(predicate)
        return matches.firstMatch
    }

    /// Check if any alert is visible
    func isAlertVisible() -> Bool {
        return app.alerts.firstMatch.exists
    }

    /// Dismiss any visible alerts
    func dismissAlerts() {
        let alert = app.alerts.firstMatch
        if alert.exists {
            let cancelButton = alert.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            } else {
                alert.buttons.firstMatch.tap()
            }
        }
    }

    // MARK: - Currency Helpers

    /// Get currency symbols for testing
    static let currencySymbols: [String: String] = [
        "AED": "د.إ",
        "USD": "$",
        "EUR": "€",
        "GBP": "£",
        "INR": "₹",
        "SAR": "﷼"
    ]

    /// Get currency display name
    static let currencyNames: [String: String] = [
        "AED": "UAE Dirham",
        "USD": "US Dollar",
        "EUR": "Euro",
        "GBP": "British Pound",
        "INR": "Indian Rupee",
        "SAR": "Saudi Riyal"
    ]

    /// All supported currency codes
    static let allCurrencyCodes = ["AED", "USD", "EUR", "GBP", "INR", "SAR"]

    // MARK: - Common Test Actions

    /// Navigate to a specific screen (if needed in future)
    func navigateTo(screen: String) {
        // Placeholder for navigation logic
        // Can be expanded as app grows
    }

    /// Tap voice recording button
    func tapVoiceButton() -> Bool {
        let button = findButton(identifier: "voice_recording_button", fallbackLabel: "Start voice recording")
        if button.exists && button.isHittable {
            button.tap()
            return true
        }
        return false
    }

    /// Verify element exists and is visible
    func verifyElementVisible(_ element: XCUIElement, timeout: TimeInterval = 5.0) -> Bool {
        return waitForElement(element, timeout: timeout) && element.isHittable
    }

    // MARK: - Scroll Helpers

    /// Scroll to make an element visible and return it (works with Lists)
    /// This handles dynamic currency lists that might have off-screen elements
    @discardableResult
    func scrollToElement(withIdentifier identifier: String, in container: XCUIElement? = nil) -> XCUIElement? {
        let searchContainer = container ?? app

        // First try to find as button
        var element = searchContainer.buttons[identifier]
        if element.exists && element.isHittable {
            return element
        }

        // Try as static text
        element = searchContainer.staticTexts[identifier]
        if element.exists && element.isHittable {
            return element
        }

        // Try scrolling the container to find it
        if !element.exists {
            // Find the scrollable list
            let lists = searchContainer.collectionViews.allElementsBoundByIndex +
                       searchContainer.scrollViews.allElementsBoundByIndex

            for list in lists {
                if list.exists {
                    // Scroll down to find element
                    var attempts = 0
                    while attempts < 10 { // Max 10 scroll attempts
                        // Check if element is now visible
                        if searchContainer.buttons[identifier].exists {
                            return searchContainer.buttons[identifier]
                        }
                        if searchContainer.staticTexts[identifier].exists {
                            return searchContainer.staticTexts[identifier]
                        }

                        // Scroll down
                        list.swipeUp()
                        Thread.sleep(forTimeInterval: 0.2)
                        attempts += 1
                    }
                }
            }
        }

        // Return what we found (might not be hittable)
        if searchContainer.buttons[identifier].exists {
            return searchContainer.buttons[identifier]
        }
        if searchContainer.staticTexts[identifier].exists {
            return searchContainer.staticTexts[identifier]
        }

        return nil
    }

    /// Check if currency button/option exists (with scrolling support)
    func findCurrencyOption(_ currencyCode: String) -> XCUIElement? {
        return scrollToElement(withIdentifier: currencyCode)
    }
}

/// Base test case with common setup
class BaseUITestCase: XCTestCase {

    var app: XCUIApplication!
    var testHelper: TestDataHelper!

    /// Override this in subclasses to customize launch arguments
    func customLaunchArguments() -> [String] {
        return TestDataHelper.configureSkipOnboarding()
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = customLaunchArguments()
        app.launch()

        testHelper = TestDataHelper(app: app)

        // Wait for app to fully load
        let appTitle = app.staticTexts["Just Spent"]
        XCTAssertTrue(appTitle.waitForExistence(timeout: 10.0), "App should launch and show title")
    }

    override func tearDownWithError() throws {
        app = nil
        testHelper = nil
        try super.tearDownWithError()
    }
}
