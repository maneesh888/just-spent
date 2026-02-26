import XCTest

/// Helper class for managing test data in UI tests
/// Mirrors functionality from Android TestDataHelper.kt
class TestDataHelper {

    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Simulator Detection

    /// Check if running in simulator at runtime (not compile-time)
    /// Use this instead of #if targetEnvironment(simulator) to ensure tests are counted
    static var isRunningInSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// Skip test if running in simulator (use instead of compile-time #if)
    /// This ensures the test is still counted even when skipped
    static func skipIfSimulator(_ reason: String = "This test requires hardware features not available in iOS Simulator") throws {
        if isRunningInSimulator {
            throw XCTSkip(reason)
        }
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
        return ["--uitesting", "--skip-onboarding", "--empty-state"]
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
    /// Supports SwiftUI .onTapGesture buttons that appear as "other" element types
    /// Also searches within cells for SwiftUI List buttons
    func findButton(identifier: String, fallbackLabel: String? = nil) -> XCUIElement {
        // First, check within cells (SwiftUI List context)
        let cells = app.cells.allElementsBoundByIndex
        for cell in cells {
            let cellButton = cell.buttons[identifier]
            if cellButton.exists {
                return cellButton
            }

            let cellOther = cell.otherElements[identifier]
            if cellOther.exists {
                return cellOther
            }
        }

        // Try as button (direct)
        var button = app.buttons[identifier]
        if button.exists {
            return button
        }

        // Try as "other" element type (SwiftUI .onTapGesture)
        let otherElement = app.otherElements[identifier]
        if otherElement.exists {
            return otherElement
        }

        // Try fallback label as button
        if let label = fallbackLabel {
            // Check in cells first
            for cell in cells {
                let cellButton = cell.buttons[label]
                if cellButton.exists {
                    return cellButton
                }

                let cellOther = cell.otherElements[label]
                if cellOther.exists {
                    return cellOther
                }
            }

            button = app.buttons[label]
            if button.exists {
                return button
            }

            // Try fallback label as "other" element type
            let otherElementByLabel = app.otherElements[label]
            if otherElementByLabel.exists {
                return otherElementByLabel
            }
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
        "SAR": "﷼",
        "JPY": "¥"
    ]

    /// Get currency display name
    static let currencyNames: [String: String] = [
        "AED": "UAE Dirham",
        "USD": "US Dollar",
        "EUR": "Euro",
        "GBP": "British Pound",
        "INR": "Indian Rupee",
        "SAR": "Saudi Riyal",
        "JPY": "Japanese Yen"
    ]

    // MARK: - Currency Data Loading

    /// Load all currency codes from shared/currencies.json using JSONLoader
    /// Returns array of currency codes dynamically loaded from JSON
    static func loadCurrencyCodesFromJSON() -> [String] {
        // Use JSONLoader (works in both main app and test bundles)
        let codes = JSONLoader.loadCurrencyCodes(from: Bundle(for: TestDataHelper.self))

        if codes.isEmpty {
            print("⚠️ TestDataHelper: JSONLoader returned empty, falling back to hardcoded")
            return allCurrencyCodes
        }

        print("✅ TestDataHelper: Loaded \(codes.count) currencies via JSONLoader")
        return codes
    }

    /// All supported currency codes (DEPRECATED - use loadCurrencyCodesFromJSON())
    /// Kept for backward compatibility, but tests should migrate to JSON loading
    static let allCurrencyCodes = [
        "AED", "AUD", "BHD", "BRL", "CAD", "CHF", "CNY", "CZK", "DKK", "EUR",
        "GBP", "HKD", "HUF", "IDR", "INR", "JPY", "KRW", "KWD", "MXN", "MYR",
        "NOK", "NZD", "OMR", "PHP", "PLN", "QAR", "RON", "RUB", "SAR", "SEK",
        "SGD", "THB", "TRY", "USD", "VND", "ZAR"
    ]

    /// Currencies that have test data in multi-currency mode
    /// Matches TestDataManager.populateMultiCurrencyData()
    static let multiCurrencyTestDataCodes = [
        "AED", "USD", "EUR", "GBP", "INR", "SAR"
    ]

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

        // CRITICAL: SwiftUI List buttons with .buttonStyle(.plain) are embedded in cells
        // We need to search through the cell hierarchy, not just top-level elements

        // First, try to find within cells (most common for SwiftUI List)
        let cells = searchContainer.cells.allElementsBoundByIndex
        for cell in cells {
            // Check if this cell contains our identifier
            let cellButton = cell.buttons[identifier]
            if cellButton.exists && cellButton.isHittable {
                return cellButton
            }

            let cellOther = cell.otherElements[identifier]
            if cellOther.exists && cellOther.isHittable {
                return cellOther
            }
        }

        // Try direct queries as fallback
        var element = searchContainer.otherElements[identifier]
        if element.exists && element.isHittable {
            return element
        }

        element = searchContainer.buttons[identifier]
        if element.exists && element.isHittable {
            return element
        }

        element = searchContainer.staticTexts[identifier]
        if element.exists && element.isHittable {
            return element
        }

        // Try scrolling to find the element
        let lists = searchContainer.tables.allElementsBoundByIndex +
                   searchContainer.collectionViews.allElementsBoundByIndex +
                   searchContainer.scrollViews.allElementsBoundByIndex

        for list in lists where list.exists {
            var attempts = 0
            var previousCellCount = 0
            var stuckAttempts = 0

            while attempts < 10 { // Max 10 scroll attempts
                // Check within cells first after each scroll
                let cellsAfterScroll = searchContainer.cells.allElementsBoundByIndex
                for cell in cellsAfterScroll {
                    let cellButton = cell.buttons[identifier]
                    if cellButton.exists && cellButton.isHittable {
                        return cellButton
                    }

                    let cellOther = cell.otherElements[identifier]
                    if cellOther.exists && cellOther.isHittable {
                        return cellOther
                    }
                }

                // Also check direct queries
                if searchContainer.otherElements[identifier].exists {
                    return searchContainer.otherElements[identifier]
                }
                if searchContainer.buttons[identifier].exists {
                    return searchContainer.buttons[identifier]
                }
                if searchContainer.staticTexts[identifier].exists {
                    return searchContainer.staticTexts[identifier]
                }

                // Track cell count to detect when we've reached the end
                let currentCellCount = cellsAfterScroll.count

                // If cell count hasn't changed after scrolling, we're stuck at the end
                if currentCellCount == previousCellCount {
                    stuckAttempts += 1
                    // If stuck for 2 consecutive attempts, stop
                    if stuckAttempts >= 2 {
                        break
                    }
                } else {
                    stuckAttempts = 0
                }

                previousCellCount = currentCellCount

                // Scroll down
                list.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
                attempts += 1
            }
        }

        // Final attempt - return what we found even if not hittable
        // Check cells first
        for cell in cells {
            if cell.buttons[identifier].exists {
                return cell.buttons[identifier]
            }
            if cell.otherElements[identifier].exists {
                return cell.otherElements[identifier]
            }
        }

        // Then check direct
        if searchContainer.otherElements[identifier].exists {
            return searchContainer.otherElements[identifier]
        }
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
        return scrollToElement(withIdentifier: "currency_option_\(currencyCode)")
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

        // Wait for app to fully load (increased timeout for simulator boot time)
        // Use "Just Spent" title which appears in ALL view states (empty, single-currency, multi-currency)
        let appTitle = app.staticTexts["Just Spent"]
        XCTAssertTrue(appTitle.waitForExistence(timeout: 30.0), "App should launch and show title")
    }

    override func tearDownWithError() throws {
        app = nil
        testHelper = nil
        try super.tearDownWithError()
    }
}
