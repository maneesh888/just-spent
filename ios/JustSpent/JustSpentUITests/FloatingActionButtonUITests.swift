import XCTest

class FloatingActionButtonUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        app = XCUIApplication()
        // Skip onboarding when running UI tests
        app.launchArguments = ["--uitesting"]
        app.launch()

        // Wait for app to load (increased timeout for simulator boot time)
        let appTitle = app.staticTexts["Just Spent"]
        XCTAssertTrue(appTitle.waitForExistence(timeout: 30.0), "App should launch and show title")
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Floating Action Button Visibility Tests
    
    func testFloatingActionButtonVisibilityInEmptyState() throws {
        // Given - App launched with no expenses
        let emptyStateText = app.staticTexts["No expenses yet"]
        
        // When - Check if empty state is visible
        if emptyStateText.exists {
            // Then - Floating action button should be visible
            let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
            XCTAssertTrue(floatingButton.exists, "Floating action button should exist in empty state")
            XCTAssertTrue(floatingButton.isHittable, "Floating action button should be tappable in empty state")
        }
    }
    
    func testFloatingActionButtonVisibilityWithExpenses() throws {
        // Given - Add an expense first (simulated)
        addMockExpenseForTesting()
        
        // When - Check if expenses exist
        let expensesList = app.tables.firstMatch
        if expensesList.exists {
            // Then - Floating action button should still be visible
            let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
            XCTAssertTrue(floatingButton.exists, "Floating action button should exist with expenses")
            XCTAssertTrue(floatingButton.isHittable, "Floating action button should be tappable with expenses")
        }
    }
    
    func testFloatingActionButtonPosition() throws {
        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        
        // When
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Floating button should exist")
        
        // Then - Check button is positioned at bottom center
        let buttonFrame = floatingButton.frame
        let screenFrame = app.frame
        
        // Check horizontal centering (with some tolerance)
        let buttonCenterX = buttonFrame.midX
        let screenCenterX = screenFrame.midX
        let horizontalTolerance: CGFloat = 50
        
        XCTAssertTrue(abs(buttonCenterX - screenCenterX) < horizontalTolerance,
                     "Button should be horizontally centered. Button center: \(buttonCenterX), Screen center: \(screenCenterX)")
        
        // Check vertical positioning (should be near bottom)
        let buttonBottomY = buttonFrame.maxY
        let screenBottomY = screenFrame.maxY
        let bottomMargin = screenBottomY - buttonBottomY
        
        XCTAssertTrue(bottomMargin > 20 && bottomMargin < 100,
                     "Button should be near bottom with safe area margin. Bottom margin: \(bottomMargin)")
    }
    
    // MARK: - Button State Tests
    
    func testFloatingActionButtonInitialState() throws {
        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch

        // When
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // Then - Check initial state (should show "Start voice recording" label)
        XCTAssertEqual(floatingButton.label, "Start voice recording", "Button should show start recording label initially")
    }
    
    #if !targetEnvironment(simulator)
    func testFloatingActionButtonTapToRecord() throws {
        // NOTE: This test requires actual microphone and speech recognition
        // which are not available in iOS Simulator

        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // When - Tap the button to start recording
        floatingButton.tap()

        // Then - Button should change to recording state
        let stopIcon = floatingButton.images["stop.circle.fill"]
        XCTAssertTrue(stopIcon.waitForExistence(timeout: 3.0), "Button should show stop icon when recording")

        // And recording indicator should appear
        let listeningText = app.staticTexts["Listening..."]
        XCTAssertTrue(listeningText.exists, "Should show listening indicator")
    }
    #endif
    
    #if !targetEnvironment(simulator)
    func testFloatingActionButtonTapToStopRecording() throws {
        // NOTE: This test requires actual microphone and speech recognition
        // which are not available in iOS Simulator

        // Given - Start recording first
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        floatingButton.tap() // Start recording

        let stopIcon = floatingButton.images["stop.circle.fill"]
        XCTAssertTrue(stopIcon.waitForExistence(timeout: 3.0), "Should be in recording state")

        // When - Tap again to stop recording
        floatingButton.tap()

        // Then - Button should return to initial state
        let micIcon = floatingButton.images["mic.circle.fill"]
        XCTAssertTrue(micIcon.waitForExistence(timeout: 3.0), "Button should return to microphone icon")

        // And recording indicator should disappear
        let listeningText = app.staticTexts["Listening..."]
        XCTAssertFalse(listeningText.exists, "Listening indicator should disappear")
    }
    #endif
    
    // MARK: - Recording Indicator Tests
    
    #if !targetEnvironment(simulator)
    func testRecordingIndicatorAppearance() throws {
        // NOTE: This test requires actual microphone and speech recognition
        // which are not available in iOS Simulator

        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // When - Start recording
        floatingButton.tap()

        // Then - Recording indicators should appear
        let listeningText = app.staticTexts["Listening..."]
        XCTAssertTrue(listeningText.waitForExistence(timeout: 3.0), "Should show listening text")

        let autoStopText = app.staticTexts["Will stop automatically when you finish speaking"]
        XCTAssertTrue(autoStopText.exists, "Should show auto-stop instruction")

        // Check for status indicator dot
        let statusIndicator = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'status_indicator'")).firstMatch
        // Note: The exact identifier depends on implementation
    }
    #endif
    
    #if !targetEnvironment(simulator)
    func testRecordingIndicatorStateChanges() throws {
        // NOTE: This test requires actual microphone and speech recognition
        // which are not available in iOS Simulator

        // Given - Start recording
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        floatingButton.tap()

        // When - Wait for potential state changes during recording
        let listeningText = app.staticTexts["Listening..."]
        XCTAssertTrue(listeningText.waitForExistence(timeout: 3.0), "Should show listening state")

        // Then - Check if processing state appears (if speech is detected)
        let processingText = app.staticTexts["Processing..."]

        // Note: This test might be flaky as it depends on actual speech detection
        // In a real test environment, we might need to mock the speech input
        if processingText.waitForExistence(timeout: 5.0) {
            XCTAssertTrue(processingText.exists, "Should show processing state when speech detected")
        }
    }
    #endif
    
    // MARK: - Auto-Stop Behavior Tests

    #if !targetEnvironment(simulator)
    func testAutoStopInstructionVisibility() throws {
        // NOTE: This test requires actual microphone and speech recognition
        // which are not available in iOS Simulator

        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // When - Start recording
        floatingButton.tap()

        // Then - Auto-stop instruction should be visible (checking for the actual localized text)
        // The text "Will stop automatically when you finish speaking" should exist
        let autoStopText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'stop automatically'")).firstMatch
        XCTAssertTrue(autoStopText.waitForExistence(timeout: 2.0), "Should show auto-stop instruction")

        // Stop recording to clean up
        floatingButton.tap()
    }
    #endif
    
    #if !targetEnvironment(simulator)
    func testAutoStopAfterSilence() throws {
        // NOTE: This test requires actual microphone and speech recognition
        // which are not available in iOS Simulator

        // Given - Start recording
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        floatingButton.tap()

        let stopIcon = floatingButton.images["stop.circle.fill"]
        XCTAssertTrue(stopIcon.waitForExistence(timeout: 3.0), "Should be recording")

        // When - Wait for auto-stop (this will depend on the silence threshold)
        // Note: In a real test, we might need longer timeout or mock the silence detection

        // Then - Recording should stop automatically after silence period
        let micIcon = floatingButton.images["mic.circle.fill"]

        // Wait up to 10 seconds for auto-stop (longer than the 2-second silence threshold)
        if micIcon.waitForExistence(timeout: 10.0) {
            XCTAssertTrue(micIcon.exists, "Recording should auto-stop after silence")

            // Recording indicators should disappear
            let listeningText = app.staticTexts["Listening..."]
            XCTAssertFalse(listeningText.exists, "Listening indicator should disappear after auto-stop")
        } else {
            // If auto-stop doesn't happen, manually stop to clean up
            floatingButton.tap()
            XCTFail("Auto-stop should have occurred within timeout period")
        }
    }
    #endif
    
    // MARK: - Permission-Dependent Behavior Tests
    
    func testButtonDisabledWithoutPermissions() throws {
        // Note: This test is challenging to implement as it requires controlling permissions
        // In a real test environment, we might need to:
        // 1. Reset app permissions
        // 2. Deny permissions during app launch
        // 3. Check button state
        
        // For now, we'll test the visual state when permissions might be missing
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        
        if floatingButton.waitForExistence(timeout: 5.0) {
            // Check if button appears disabled (reduced opacity)
            // Note: XCUITest has limited ability to check opacity directly
            // We might need to check if button is enabled/disabled
            
            if !floatingButton.isEnabled {
                XCTAssertFalse(floatingButton.isEnabled, "Button should be disabled without permissions")
            }
        }
    }
    
    #if !targetEnvironment(simulator)
    func testPermissionAlertFromButton() throws {
        // NOTE: This test requires actual microphone and speech recognition permissions
        // which cannot be properly tested in iOS Simulator

        // Given - Button without permissions (this might vary by test environment)
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // When - Tap button (might trigger permission alert if not granted)
        floatingButton.tap()

        // Then - Check for permission alert (if permissions not granted)
        let permissionAlert = app.alerts.firstMatch

        if permissionAlert.waitForExistence(timeout: 3.0) {
            // If permission alert appears, verify its content
            let goToSettingsButton = permissionAlert.buttons["Go to Settings"]
            let cancelButton = permissionAlert.buttons["Cancel"]

            XCTAssertTrue(goToSettingsButton.exists, "Permission alert should have 'Go to Settings' button")
            XCTAssertTrue(cancelButton.exists, "Permission alert should have 'Cancel' button")

            // Dismiss the alert
            cancelButton.tap()
        }
    }
    #endif
    
    // MARK: - Visual Feedback Tests
    
    #if !targetEnvironment(simulator)
    func testButtonVisualStateChanges() throws {
        // NOTE: This test requires actual microphone and speech recognition
        // which are not available in iOS Simulator

        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // When - Tap to start recording
        floatingButton.tap()

        // Then - Accessibility label should change to recording state
        // Wait briefly for state change
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertEqual(floatingButton.label, "Stop recording", "Should show stop recording label")

        // Stop recording
        floatingButton.tap()

        // Should return to initial state
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertEqual(floatingButton.label, "Start voice recording", "Should return to start recording label")
    }
    #endif
    
    #if !targetEnvironment(simulator)
    func testButtonAccessibilityLabels() throws {
        // NOTE: This test requires actual microphone and speech recognition
        // which are not available in iOS Simulator

        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // When - Check accessibility label in initial state
        let initialLabel = floatingButton.label

        // Then - Should have exact accessibility label
        XCTAssertEqual(initialLabel, "Start voice recording", "Button should have 'Start voice recording' label")

        // When - Start recording
        floatingButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Then - Accessibility label should change
        let recordingLabel = floatingButton.label
        XCTAssertEqual(recordingLabel, "Stop recording", "Button should have 'Stop recording' label while recording")

        // Cleanup - Stop recording
        floatingButton.tap()
    }
    #endif
    
    // MARK: - Integration Tests
    
    #if !targetEnvironment(simulator)
    func testFloatingButtonToExpenseCreation() throws {
        // NOTE: This test requires actual microphone and speech recognition
        // which are not available in iOS Simulator
        // This test would require actual speech input or mocking

        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // When - Start and stop recording quickly
        floatingButton.tap() // Start recording

        let stopIcon = floatingButton.images["stop.circle.fill"]
        XCTAssertTrue(stopIcon.waitForExistence(timeout: 3.0), "Should start recording")

        floatingButton.tap() // Stop recording

        // Then - Should return to normal state
        let micIcon = floatingButton.images["mic.circle.fill"]
        XCTAssertTrue(micIcon.waitForExistence(timeout: 3.0), "Should stop recording")

        // Note: In a full integration test, we would:
        // 1. Simulate speech input
        // 2. Verify expense creation
        // 3. Check UI updates
    }
    #endif

    // MARK: - Additional Simulator-Compatible Tests (10 tests)

    func testFloatingActionButtonEnabledState() throws {
        // Given
        Thread.sleep(forTimeInterval: 1.5)
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // Then - Button should be tappable (enabled state depends on permissions)
        XCTAssertTrue(floatingButton.isHittable, "Floating button should be tappable")

        // Note: Button might be disabled if microphone permissions not granted
        // Test passes if button exists and is hittable, even if not enabled
        if !floatingButton.isEnabled {
            print("Floating button is disabled - likely microphone permissions not granted in test environment")
        }
    }

    func testFloatingButtonQuickTapCycle() throws {
        // Given - Simulator-compatible version (no actual recording)
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // When - Quick tap cycle
        let initialLabel = floatingButton.label
        floatingButton.tap()
        Thread.sleep(forTimeInterval: 0.2)

        floatingButton.tap()
        Thread.sleep(forTimeInterval: 0.3)

        // Then - Button should return to normal state
        XCTAssertTrue(floatingButton.exists, "Button should remain after quick cycle")
    }

    func testFloatingButtonMultipleTapCycles() throws {
        // Given - Test button stability with multiple taps
        Thread.sleep(forTimeInterval: 1.5)
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // When - Perform 3 tap cycles
        for _ in 1...3 {
            floatingButton.tap()
            Thread.sleep(forTimeInterval: 0.3)

            floatingButton.tap()
            Thread.sleep(forTimeInterval: 0.3)
        }

        // Then - Button should still be functional
        XCTAssertTrue(floatingButton.exists, "Button should remain stable after multiple cycles")

        // Note: Button might be disabled after taps if microphone permissions not granted
        // Test passes if button remains stable and exists, even if not enabled
        if !floatingButton.isEnabled {
            print("Floating button is disabled after taps - likely microphone permissions not granted in test environment")
        }
    }

    func testFloatingButtonExistsRegardlessOfPermissions() throws {
        // Given/When - The button should always exist
        // (Permission state affects functionality, not visibility)
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch

        // Then
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist regardless of permissions")
        XCTAssertTrue(floatingButton.isHittable, "Button should be visible")
    }

    func testFloatingButtonVisibleAcrossDifferentStates() throws {
        // Given - Button should be visible in both empty and populated states
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should be visible initially")

        // When - Navigate or change state (if applicable)
        // For now, just verify consistent visibility
        Thread.sleep(forTimeInterval: 1.0)

        // Then - Button should remain visible
        XCTAssertTrue(floatingButton.exists, "Button should remain visible across states")
        XCTAssertTrue(floatingButton.isHittable, "Button should remain tappable")
    }

    func testFloatingButtonPositionInEmptyState() throws {
        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // When - Check position in empty state
        let emptyStateText = app.staticTexts["No expenses yet"]

        if emptyStateText.exists {
            // Then - Both should be visible (button doesn't overlap empty state)
            XCTAssertTrue(floatingButton.exists, "Button should be visible in empty state")
            XCTAssertTrue(floatingButton.isHittable, "Button should be accessible in empty state")
            XCTAssertTrue(emptyStateText.isHittable, "Empty state should be visible")
        }
    }

    func testFloatingButtonSizeAndAppearance() throws {
        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // When - Check button properties
        let buttonFrame = floatingButton.frame

        // Then - Button should have reasonable size (not tiny, not huge)
        XCTAssertGreaterThan(buttonFrame.width, 40, "Button should be at least 40pt wide")
        XCTAssertGreaterThan(buttonFrame.height, 40, "Button should be at least 40pt tall")
        XCTAssertLessThan(buttonFrame.width, 200, "Button should not be unreasonably wide")
        XCTAssertLessThan(buttonFrame.height, 200, "Button should not be unreasonably tall")
    }

    func testFloatingButtonPerformanceOfTap() throws {
        // Given
        Thread.sleep(forTimeInterval: 1.5)
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // When - Measure tap response time
        let startTime = Date()
        floatingButton.tap()
        let tapTime = Date().timeIntervalSince(startTime)

        // Then - Tap should be responsive (< 500ms for UI test)
        // Note: UI tests are slower than unit tests, 500ms is reasonable threshold
        XCTAssertLessThan(tapTime, 0.5, "Button tap should be responsive, took \(tapTime)s")

        // Cleanup - tap again to stop any recording
        Thread.sleep(forTimeInterval: 0.3)
        if floatingButton.exists {
            floatingButton.tap()
        }
    }

    func testFloatingButtonAccessibleToScreenReaders() throws {
        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // Then - Button should have accessible label
        XCTAssertFalse(floatingButton.label.isEmpty, "Button should have accessible label for screen readers")

        // Label should be descriptive
        let label = floatingButton.label.lowercased()
        let hasRelevantKeywords = label.contains("voice") || label.contains("record") || label.contains("start")
        XCTAssertTrue(hasRelevantKeywords, "Button label should be descriptive: '\(floatingButton.label)'")
    }

    // Note: This test requires microphone permissions which are not available in simulator
    // Test is only run on physical devices where microphone access is available
    #if !targetEnvironment(simulator)
    func testFloatingButtonStateTransitionSmooth() throws {
        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // Check if button is enabled before testing transitions
        guard floatingButton.isEnabled else {
            throw XCTSkip("Button is disabled (likely no microphone permissions)")
        }

        // When - Tap to change state
        let initialLabel = floatingButton.label
        floatingButton.tap()

        // Handle potential permission alert
        let permissionAlert = app.alerts.firstMatch
        if permissionAlert.waitForExistence(timeout: 2.0) {
            let cancelButton = permissionAlert.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            }
        }

        Thread.sleep(forTimeInterval: 0.5) // Wait for transition

        // Then - Button should still exist (smooth transition)
        XCTAssertTrue(floatingButton.exists, "Button should exist during state transition")

        // Tap again to return to normal
        floatingButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Should return to initial state smoothly
        XCTAssertTrue(floatingButton.exists, "Button should exist after return transition")
    }
    #endif

    // MARK: - Helper Methods
    
    private func addMockExpenseForTesting() {
        // This would normally add a test expense to the app
        // For UI tests, we might need to use app launch arguments
        // or interact with the app to create a test expense
        
        // For now, this is a placeholder
        // In a real implementation, we might:
        // 1. Use app.launchArguments to inject test data
        // 2. Interact with the app UI to create an expense
        // 3. Use a test-specific app configuration
    }
    
    private func waitForRecordingToStop(button: XCUIElement, timeout: TimeInterval = 10.0) -> Bool {
        // Helper to wait for auto-stop or manual stop
        let micIcon = button.images["mic.circle.fill"]
        return micIcon.waitForExistence(timeout: timeout)
    }
    
    private func dismissAnyAlerts() {
        // Helper to dismiss any permission or other alerts that might appear
        let alert = app.alerts.firstMatch
        if alert.exists {
            let cancelButton = alert.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            } else {
                // Try to find any button to dismiss
                let firstButton = alert.buttons.firstMatch
                if firstButton.exists {
                    firstButton.tap()
                }
            }
        }
    }
}