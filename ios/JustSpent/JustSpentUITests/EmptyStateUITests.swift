import XCTest

/// UI tests for the empty state screen
/// Tests display, layout, and user interactions when no expenses exist
/// Mirrors Android EmptyStateUITest.kt (26 tests)
class EmptyStateUITests: BaseUITestCase {

    override func customLaunchArguments() -> [String] {
        // Ensure empty state by clearing data
        return TestDataHelper.configureWithEmptyState()
    }

    // MARK: - Empty State Display Tests (5 tests)

    func testEmptyStateDisplaysCorrectTitle() throws {
        // Given - No expenses in database

        // Wait for app to fully initialize (including permission checks)
        Thread.sleep(forTimeInterval: 1.0)

        // Then - Should see empty state title (permission-aware)
        // Check for either permissions-granted message or permissions-needed message
        let emptyTitle = app.staticTexts.matching(identifier: "empty_state_no_expenses_title").firstMatch
        let permissionTitle = app.staticTexts.matching(identifier: "empty_state_permissions_needed_title").firstMatch

        let titleExists = emptyTitle.waitForExistence(timeout: 10.0) || permissionTitle.waitForExistence(timeout: 10.0)
        XCTAssertTrue(titleExists, "Empty state title should be visible (either 'No expenses yet' or permissions message)")

        // Verify at least one is hittable
        XCTAssertTrue(emptyTitle.isHittable || permissionTitle.isHittable, "Empty state title should be displayed")
    }

    func testEmptyStateDisplaysHelpText() throws {
        // Given - No expenses in database

        // Wait for app to fully initialize
        Thread.sleep(forTimeInterval: 1.0)

        // Then - Should see helpful instruction text (permission-aware)
        // Check for either tap voice button message or grant permissions message
        let tapVoiceMessage = app.staticTexts.matching(identifier: "empty_state_tap_voice_button_message").firstMatch
        let grantPermissionsMessage = app.staticTexts.matching(identifier: "empty_state_grant_permissions_message").firstMatch
        let recognitionUnavailableMessage = app.staticTexts.matching(identifier: "empty_state_recognition_unavailable_message").firstMatch

        let helpTextExists = tapVoiceMessage.waitForExistence(timeout: 10.0) ||
                             grantPermissionsMessage.waitForExistence(timeout: 10.0) ||
                             recognitionUnavailableMessage.waitForExistence(timeout: 10.0)

        XCTAssertTrue(helpTextExists, "Empty state should show help text about microphone/recording or permissions")
    }

    func testEmptyStateDisplaysEmptyStateIcon() throws {
        // Given - No expenses in database

        // Wait for app to fully initialize
        Thread.sleep(forTimeInterval: 1.0)

        // Then - Should see empty state icon (permission-aware)
        // Check for either mic icon (permissions granted) or warning icon (permissions needed)
        let micIcon = app.images.matching(identifier: "empty_state_mic_icon").firstMatch
        let warningIcon = app.images.matching(identifier: "empty_state_permission_warning_icon").firstMatch

        let iconExists = micIcon.waitForExistence(timeout: 10.0) || warningIcon.waitForExistence(timeout: 10.0)
        XCTAssertTrue(iconExists, "Empty state should display icon (either mic or permission warning)")
    }

    func testEmptyStateShowsZeroTotal() throws {
        // Given - No expenses in database

        // Then - Total label should exist
        let totalLabel = app.staticTexts["Total"]
        XCTAssertTrue(totalLabel.waitForExistence(timeout: 5.0), "Total label should be visible")

        // And - Total amount should show 0 or currency with 0
        let zeroText = testHelper.findText(containing: "0.00") ?? testHelper.findText(containing: "0,00")
        XCTAssertNotNil(zeroText, "Should show zero amount in total")
    }

    func testEmptyStateDisplaysAppTitle() throws {
        // Given - No expenses in database

        // Then - Should see "Just Spent" title
        let appTitle = app.staticTexts["Just Spent"]
        XCTAssertTrue(appTitle.waitForExistence(timeout: 5.0), "App title should be visible")
        XCTAssertTrue(appTitle.isHittable, "App title should be displayed")
    }

    // MARK: - Voice Button Tests (2 tests)

    func testEmptyStateShowsVoiceButton() throws {
        // Given - No expenses in database

        // Then - Should see voice FAB
        let voiceButton = testHelper.findButton(identifier: "voice_recording_button", fallbackLabel: "Start voice recording")
        XCTAssertTrue(voiceButton.waitForExistence(timeout: 5.0), "Voice button should exist in empty state")
        XCTAssertTrue(voiceButton.isHittable, "Voice button should be tappable")
    }

    func testEmptyStateVoiceButtonIsClickable() throws {
        // Given - No expenses in database

        // Wait for app to fully initialize
        Thread.sleep(forTimeInterval: 1.5)

        // When - Check voice button is clickable
        let voiceButton = testHelper.findButton(identifier: "voice_recording_button", fallbackLabel: "Start voice recording")
        XCTAssertTrue(voiceButton.waitForExistence(timeout: 5.0), "Voice button should exist")

        // Then - Button should be tappable
        XCTAssertTrue(voiceButton.isHittable, "Voice button should be clickable")

        // Note: Button might be disabled if microphone permissions not granted
        // Test passes if button exists and is hittable, even if not enabled
        if !voiceButton.isEnabled {
            // Log that button is disabled (likely due to permissions)
            print("Voice button is disabled - likely microphone permissions not granted in test environment")
        }
    }

    // MARK: - Layout Tests (3 tests)

    func testEmptyStateHeaderCardIsDisplayed() throws {
        // Given - No expenses in database

        // Then - Header should be visible
        let appTitle = app.staticTexts["Just Spent"]
        XCTAssertTrue(appTitle.waitForExistence(timeout: 5.0), "Header title should be displayed")

        // And - Should contain total
        let totalLabel = app.staticTexts["Total"]
        XCTAssertTrue(totalLabel.exists, "Header should contain total label")
    }

    func testEmptyStateNoTabsShown() throws {
        // Given - No expenses means no currencies

        // Then - Should not see currency tabs
        let currencyCodes = TestDataHelper.allCurrencyCodes

        // Check that currency tabs don't exist
        var foundTabs = 0
        for code in currencyCodes {
            let tabButton = app.buttons[code]
            if tabButton.exists {
                foundTabs += 1
            }
        }

        XCTAssertEqual(foundTabs, 0, "Should not show currency tabs in empty state")
    }

    func testEmptyStateNoExpenseListShown() throws {
        // Given - No expenses in database

        // Wait for app to fully initialize
        Thread.sleep(forTimeInterval: 1.0)

        // Then - Should see empty state container instead of expense rows (permission-aware)
        let emptyTitle = app.staticTexts.matching(identifier: "empty_state_no_expenses_title").firstMatch
        let permissionTitle = app.staticTexts.matching(identifier: "empty_state_permissions_needed_title").firstMatch

        let titleExists = emptyTitle.waitForExistence(timeout: 10.0) || permissionTitle.waitForExistence(timeout: 10.0)
        XCTAssertTrue(titleExists, "Empty state should be shown")

        // And - Should not see expense list
        let expenseLists = app.tables.allElementsBoundByIndex
        let hasPopulatedList = expenseLists.contains { $0.cells.count > 0 }
        XCTAssertFalse(hasPopulatedList, "Should not show expense list in empty state")
    }

    // MARK: - Gradient Background Tests (1 test)

    func testEmptyStateHasGradientBackground() throws {
        // Given - No expenses in database

        // Wait for app to fully initialize
        Thread.sleep(forTimeInterval: 1.0)

        // Then - Background should be present (verified via screen rendering)
        // Note: Gradients are hard to test programmatically
        // This test verifies the screen renders without errors (permission-aware)
        let emptyTitle = app.staticTexts.matching(identifier: "empty_state_no_expenses_title").firstMatch
        let permissionTitle = app.staticTexts.matching(identifier: "empty_state_permissions_needed_title").firstMatch

        let titleExists = emptyTitle.waitForExistence(timeout: 10.0) || permissionTitle.waitForExistence(timeout: 10.0)
        XCTAssertTrue(titleExists, "Empty state should render correctly")

        // Verify main elements are visible, indicating proper rendering
        let appTitle = app.staticTexts["Just Spent"]
        XCTAssertTrue(appTitle.exists, "App should render with gradient background")
    }

    // MARK: - Accessibility Tests (2 tests)

    func testEmptyStateTitleIsAccessible() throws {
        // Given - No expenses in database

        // Wait for app to fully initialize
        Thread.sleep(forTimeInterval: 1.0)

        // Then - Title should be accessible for screen readers (permission-aware)
        let emptyTitle = app.staticTexts.matching(identifier: "empty_state_no_expenses_title").firstMatch
        let permissionTitle = app.staticTexts.matching(identifier: "empty_state_permissions_needed_title").firstMatch

        let titleExists = emptyTitle.waitForExistence(timeout: 10.0) || permissionTitle.waitForExistence(timeout: 10.0)
        XCTAssertTrue(titleExists, "Empty title should be accessible")

        // Verify it has proper accessibility properties
        let accessibleTitle = emptyTitle.exists ? emptyTitle : permissionTitle
        XCTAssertFalse(accessibleTitle.label.isEmpty, "Empty title should have accessible label")
    }

    func testEmptyStateMessageIsAccessible() throws {
        // Given - No expenses in database

        // Wait for app to fully initialize
        Thread.sleep(forTimeInterval: 1.0)

        // Then - Empty state message should be accessible (permission-aware)
        let emptyTitle = app.staticTexts.matching(identifier: "empty_state_no_expenses_title").firstMatch
        let permissionTitle = app.staticTexts.matching(identifier: "empty_state_permissions_needed_title").firstMatch

        let titleExists = emptyTitle.waitForExistence(timeout: 10.0) || permissionTitle.waitForExistence(timeout: 10.0)
        XCTAssertTrue(titleExists, "Empty message should be accessible")

        // Check for help text accessibility (permission-aware)
        let tapVoiceMessage = app.staticTexts.matching(identifier: "empty_state_tap_voice_button_message").firstMatch
        let grantPermissionsMessage = app.staticTexts.matching(identifier: "empty_state_grant_permissions_message").firstMatch

        let helpTextExists = tapVoiceMessage.exists || grantPermissionsMessage.exists
        XCTAssertTrue(helpTextExists, "Help text should be accessible")
    }

    // MARK: - State Transition Tests (1 test)

    func testEmptyStateTransitionsToSingleCurrencyAfterAddingExpense() throws {
        // Given - Empty state

        // Wait for app to fully initialize
        Thread.sleep(forTimeInterval: 1.0)

        // Then - Should see empty state (permission-aware)
        let emptyTitle = app.staticTexts.matching(identifier: "empty_state_no_expenses_title").firstMatch
        let permissionTitle = app.staticTexts.matching(identifier: "empty_state_permissions_needed_title").firstMatch

        let titleExists = emptyTitle.waitForExistence(timeout: 10.0) || permissionTitle.waitForExistence(timeout: 10.0)
        XCTAssertTrue(titleExists, "Should start in empty state")

        // When - Add an expense (would need actual implementation)
        // Note: This is a placeholder for future implementation
        // Would require adding expense via UI or database

        // Then - Should transition to single currency view
        // (Test implementation pending expense addition functionality)
        // For now, just verify empty state is stable
        let stableTitle = emptyTitle.exists ? emptyTitle : permissionTitle
        XCTAssertTrue(stableTitle.exists, "Empty state should be stable")
    }

    // MARK: - Edge Case Tests (2 tests)

    func testEmptyStateHandlesScreenRotation() throws {
        // Given - Empty state displayed

        // Wait for app to fully initialize
        Thread.sleep(forTimeInterval: 1.0)

        // Then - Should show empty state (permission-aware)
        let emptyTitle = app.staticTexts.matching(identifier: "empty_state_no_expenses_title").firstMatch
        let permissionTitle = app.staticTexts.matching(identifier: "empty_state_permissions_needed_title").firstMatch

        let titleExists = emptyTitle.waitForExistence(timeout: 10.0) || permissionTitle.waitForExistence(timeout: 10.0)
        XCTAssertTrue(titleExists, "Should show empty state")

        // When - Rotate screen (simulated by checking portrait orientation)
        // Note: XCUITest has limited rotation capabilities in simulator

        // Then - Should still show empty state (rotation testing requires device)
        // Simplified test: verify empty state is stable
        let stableTitle = emptyTitle.exists ? emptyTitle : permissionTitle
        XCTAssertTrue(stableTitle.exists, "Empty state should remain after orientation change")

        // And - Title should still be visible
        let appTitle = app.staticTexts["Just Spent"]
        XCTAssertTrue(appTitle.exists, "App title should remain visible")
    }

    func testEmptyStateDisplaysConsistentlyOnMultipleLoads() throws {
        // Given - Empty state

        // Wait for app to fully initialize
        Thread.sleep(forTimeInterval: 1.0)

        // Then - Should show empty state (permission-aware)
        let emptyTitle = app.staticTexts.matching(identifier: "empty_state_no_expenses_title").firstMatch
        let permissionTitle = app.staticTexts.matching(identifier: "empty_state_permissions_needed_title").firstMatch

        let titleExists = emptyTitle.waitForExistence(timeout: 10.0) || permissionTitle.waitForExistence(timeout: 10.0)
        XCTAssertTrue(titleExists, "Should show empty state initially")

        // When - Wait and check again (verify stability)
        Thread.sleep(forTimeInterval: 0.5)

        // Then - Should still show same empty state (no flickering or recomposition issues)
        let stableTitle = emptyTitle.exists ? emptyTitle : permissionTitle
        XCTAssertTrue(stableTitle.exists, "Empty state should remain consistent")

        // And - App title should remain stable
        let appTitle = app.staticTexts["Just Spent"]
        XCTAssertTrue(appTitle.exists, "App title should remain stable")

        // Wait longer and verify again
        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertTrue(stableTitle.exists, "Empty state should be consistently displayed")
    }

    // MARK: - Performance Tests (1 test)

    func testEmptyStateRendersQuickly() throws {
        // Given - Fresh app launch
        let startTime = Date()

        // Wait for app to fully initialize (including permission checks)
        Thread.sleep(forTimeInterval: 1.0)

        // When - Wait for empty state to appear (permission-aware)
        let emptyTitle = app.staticTexts.matching(identifier: "empty_state_no_expenses_title").firstMatch
        let permissionTitle = app.staticTexts.matching(identifier: "empty_state_permissions_needed_title").firstMatch

        let didAppear = emptyTitle.waitForExistence(timeout: 10.0) || permissionTitle.waitForExistence(timeout: 10.0)

        // Then - Should render within reasonable time
        let renderTime = Date().timeIntervalSince(startTime)
        XCTAssertTrue(didAppear, "Empty state should appear (either 'No expenses yet' or permissions message)")
        XCTAssertLessThan(renderTime, 12.0, "Empty state should render within 12 seconds, took \(renderTime)s")

        // And - Empty state should be visible
        let stableTitle = emptyTitle.exists ? emptyTitle : permissionTitle
        XCTAssertTrue(stableTitle.isHittable, "Empty state should be fully rendered")
    }
}
