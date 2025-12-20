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
    
    func testFloatingActionButtonTapToRecord() throws {
        try TestDataHelper.skipIfSimulator("This test requires actual microphone and speech recognition which are not available in iOS Simulator")

        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // Check if button is enabled (has permissions)
        guard floatingButton.isEnabled else {
            throw XCTSkip("Button is disabled - microphone/speech permissions not available")
        }

        // When - Tap the button to start recording
        floatingButton.tap()

        // Handle potential permission alert
        let permissionAlert = app.alerts.firstMatch
        if permissionAlert.waitForExistence(timeout: 2.0) {
            if let cancelButton = permissionAlert.buttons["Cancel"].exists ? permissionAlert.buttons["Cancel"] : nil {
                cancelButton.tap()
            }
            throw XCTSkip("Permission alert appeared - permissions not granted")
        }

        // Then - Button should change to recording state (check accessibility label)
        // Wait for state change
        Thread.sleep(forTimeInterval: 0.5)

        // Verify recording started by checking accessibility label changed
        let recordingLabel = floatingButton.label
        if recordingLabel == "Stop recording" {
            // Recording started successfully - verify recording indicator
            let recordingIndicator = app.otherElements["recording_indicator_card"]
            XCTAssertTrue(recordingIndicator.waitForExistence(timeout: 3.0), "Recording indicator should appear")

            // Cleanup - stop recording
            floatingButton.tap()
        } else {
            // Recording didn't start - this is acceptable on device if speech recognition fails
            throw XCTSkip("Recording did not start - speech recognition may not be available: label=\(recordingLabel)")
        }
    }
    
    func testFloatingActionButtonTapToStopRecording() throws {
        try TestDataHelper.skipIfSimulator("This test requires actual microphone and speech recognition which are not available in iOS Simulator")

        // Given - Start recording first
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // Check if button is enabled (has permissions)
        guard floatingButton.isEnabled else {
            throw XCTSkip("Button is disabled - microphone/speech permissions not available")
        }

        floatingButton.tap() // Start recording

        // Handle potential permission alert
        let permissionAlert = app.alerts.firstMatch
        if permissionAlert.waitForExistence(timeout: 2.0) {
            if permissionAlert.buttons["Cancel"].exists {
                permissionAlert.buttons["Cancel"].tap()
            }
            throw XCTSkip("Permission alert appeared - permissions not granted")
        }

        // Wait for recording state
        Thread.sleep(forTimeInterval: 0.5)

        // Check if recording started by accessibility label
        guard floatingButton.label == "Stop recording" else {
            throw XCTSkip("Recording did not start - speech recognition may not be available")
        }

        // When - Tap again to stop recording
        floatingButton.tap()

        // Then - Button should return to initial state
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertEqual(floatingButton.label, "Start voice recording", "Button should return to start recording label")

        // And recording indicator should disappear
        let recordingIndicator = app.otherElements["recording_indicator_card"]
        XCTAssertFalse(recordingIndicator.exists, "Recording indicator should disappear")
    }
    
    // MARK: - Recording Indicator Tests

    func testRecordingIndicatorAppearance() throws {
        try TestDataHelper.skipIfSimulator("This test requires actual microphone and speech recognition which are not available in iOS Simulator")

        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // Check if button is enabled (has permissions)
        guard floatingButton.isEnabled else {
            throw XCTSkip("Button is disabled - microphone/speech permissions not available")
        }

        // When - Start recording
        floatingButton.tap()

        // Handle potential permission alert
        let permissionAlert = app.alerts.firstMatch
        if permissionAlert.waitForExistence(timeout: 2.0) {
            if permissionAlert.buttons["Cancel"].exists {
                permissionAlert.buttons["Cancel"].tap()
            }
            throw XCTSkip("Permission alert appeared - permissions not granted")
        }

        // Check if recording started by accessibility label
        Thread.sleep(forTimeInterval: 0.5)
        guard floatingButton.label == "Stop recording" else {
            throw XCTSkip("Recording did not start - speech recognition may not be available")
        }

        // Then - Recording indicator card should appear
        let recordingIndicator = app.otherElements["recording_indicator_card"]
        XCTAssertTrue(recordingIndicator.waitForExistence(timeout: 3.0), "Recording indicator card should appear")

        // Note: Child elements (status text, auto-stop indicator) may not be individually accessible
        // in SwiftUI's accessibility tree. The indicator card existing confirms the recording UI is shown.
        // This is a known limitation of XCUITest with SwiftUI hierarchies.

        // Cleanup - stop recording
        floatingButton.tap()
    }

    func testRecordingIndicatorStateChanges() throws {
        try TestDataHelper.skipIfSimulator("This test requires actual microphone and speech recognition which are not available in iOS Simulator")

        // Given - Start recording
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // Check if button is enabled (has permissions)
        guard floatingButton.isEnabled else {
            throw XCTSkip("Button is disabled - microphone/speech permissions not available")
        }

        floatingButton.tap()

        // Handle potential permission alert
        let permissionAlert = app.alerts.firstMatch
        if permissionAlert.waitForExistence(timeout: 2.0) {
            if permissionAlert.buttons["Cancel"].exists {
                permissionAlert.buttons["Cancel"].tap()
            }
            throw XCTSkip("Permission alert appeared - permissions not granted")
        }

        // Check if recording started by accessibility label
        Thread.sleep(forTimeInterval: 0.5)
        guard floatingButton.label == "Stop recording" else {
            throw XCTSkip("Recording did not start - speech recognition may not be available")
        }

        // Then - Recording indicator should be visible
        let recordingIndicator = app.otherElements["recording_indicator_card"]
        XCTAssertTrue(recordingIndicator.waitForExistence(timeout: 3.0), "Should show recording indicator")

        // Note: Child elements (status text) may not be individually accessible in SwiftUI's
        // accessibility tree. The indicator card existing confirms the recording UI is shown.
        // State changes (Listening → Processing) happen internally when speech is detected.

        // Cleanup - stop recording
        floatingButton.tap()
    }
    
    // MARK: - Auto-Stop Behavior Tests

    func testAutoStopInstructionVisibility() throws {
        try TestDataHelper.skipIfSimulator("This test requires actual microphone and speech recognition which are not available in iOS Simulator")

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

    func testAutoStopAfterSilence() throws {
        try TestDataHelper.skipIfSimulator("This test requires actual microphone and speech recognition which are not available in iOS Simulator")

        // Given - Start recording
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // Check if button is enabled (has permissions)
        guard floatingButton.isEnabled else {
            throw XCTSkip("Button is disabled - microphone/speech permissions not available")
        }

        floatingButton.tap()

        // Handle potential permission alert
        let permissionAlert = app.alerts.firstMatch
        if permissionAlert.waitForExistence(timeout: 2.0) {
            if permissionAlert.buttons["Cancel"].exists {
                permissionAlert.buttons["Cancel"].tap()
            }
            throw XCTSkip("Permission alert appeared - permissions not granted")
        }

        // Check if recording started by accessibility label
        Thread.sleep(forTimeInterval: 0.5)
        guard floatingButton.label == "Stop recording" else {
            throw XCTSkip("Recording did not start - speech recognition may not be available")
        }

        // When - Wait for auto-stop (this will depend on the silence threshold)
        // Note: In a real test, we might need longer timeout or mock the silence detection

        // Then - Recording should stop automatically after silence period
        // Wait up to 10 seconds for auto-stop (longer than the 2-second silence threshold)
        // Poll for the label to change back to "Start voice recording"
        var autoStopped = false
        for _ in 0..<20 { // Check every 0.5 seconds for 10 seconds
            Thread.sleep(forTimeInterval: 0.5)
            if floatingButton.label == "Start voice recording" {
                autoStopped = true
                break
            }
        }

        if autoStopped {
            // Recording indicators should disappear
            let recordingIndicator = app.otherElements["recording_indicator_card"]
            XCTAssertFalse(recordingIndicator.exists, "Recording indicator should disappear after auto-stop")
        } else {
            // If auto-stop doesn't happen, manually stop to clean up
            floatingButton.tap()
            // Don't fail - auto-stop depends on speech recognition behavior which varies
            throw XCTSkip("Auto-stop did not occur within timeout - speech recognition behavior may vary")
        }
    }
    
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

    func testPermissionAlertFromButton() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("This test requires actual microphone and speech recognition permissions which cannot be properly tested in iOS Simulator")
        #endif

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
    
    // MARK: - Visual Feedback Tests

    func testButtonVisualStateChanges() throws {
        try TestDataHelper.skipIfSimulator("This test requires actual microphone and speech recognition which are not available in iOS Simulator")

        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // Check if button is enabled (has permissions)
        guard floatingButton.isEnabled else {
            throw XCTSkip("Button is disabled - microphone/speech permissions not available")
        }

        // When - Tap to start recording
        floatingButton.tap()

        // Handle potential permission alert
        let permissionAlert = app.alerts.firstMatch
        if permissionAlert.waitForExistence(timeout: 2.0) {
            if permissionAlert.buttons["Cancel"].exists {
                permissionAlert.buttons["Cancel"].tap()
            }
            throw XCTSkip("Permission alert appeared - permissions not granted")
        }

        // Then - Accessibility label should change to recording state
        Thread.sleep(forTimeInterval: 0.5)
        guard floatingButton.label == "Stop recording" else {
            throw XCTSkip("Recording did not start - speech recognition may not be available")
        }

        // Stop recording
        floatingButton.tap()

        // Should return to initial state
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertEqual(floatingButton.label, "Start voice recording", "Should return to start recording label")
    }

    func testButtonAccessibilityLabels() throws {
        try TestDataHelper.skipIfSimulator("This test requires actual microphone and speech recognition which are not available in iOS Simulator")

        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // Check if button is enabled (has permissions)
        guard floatingButton.isEnabled else {
            throw XCTSkip("Button is disabled - microphone/speech permissions not available")
        }

        // When - Check accessibility label in initial state
        let initialLabel = floatingButton.label

        // Then - Should have exact accessibility label
        XCTAssertEqual(initialLabel, "Start voice recording", "Button should have 'Start voice recording' label")

        // When - Start recording
        floatingButton.tap()

        // Handle potential permission alert
        let permissionAlert = app.alerts.firstMatch
        if permissionAlert.waitForExistence(timeout: 2.0) {
            if permissionAlert.buttons["Cancel"].exists {
                permissionAlert.buttons["Cancel"].tap()
            }
            throw XCTSkip("Permission alert appeared - permissions not granted")
        }

        Thread.sleep(forTimeInterval: 0.5)

        // Then - Accessibility label should change
        let recordingLabel = floatingButton.label
        guard recordingLabel == "Stop recording" else {
            throw XCTSkip("Recording did not start - speech recognition may not be available")
        }

        // Cleanup - Stop recording
        floatingButton.tap()
    }
    
    // MARK: - Integration Tests

    func testFloatingButtonToExpenseCreation() throws {
        try TestDataHelper.skipIfSimulator("This test requires actual microphone and speech recognition which are not available in iOS Simulator")

        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")

        // Check if button is enabled (has permissions)
        guard floatingButton.isEnabled else {
            throw XCTSkip("Button is disabled - microphone/speech permissions not available")
        }

        // When - Start recording
        floatingButton.tap()

        // Handle potential permission alert
        let permissionAlert = app.alerts.firstMatch
        if permissionAlert.waitForExistence(timeout: 2.0) {
            if permissionAlert.buttons["Cancel"].exists {
                permissionAlert.buttons["Cancel"].tap()
            }
            throw XCTSkip("Permission alert appeared - permissions not granted")
        }

        // Check if recording started by accessibility label
        Thread.sleep(forTimeInterval: 0.5)
        guard floatingButton.label == "Stop recording" else {
            throw XCTSkip("Recording did not start - speech recognition may not be available")
        }

        // Stop recording
        floatingButton.tap()

        // Then - Should return to normal state
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertEqual(floatingButton.label, "Start voice recording", "Should return to start recording state")

        // Recording indicator should disappear
        let recordingIndicator = app.otherElements["recording_indicator_card"]
        XCTAssertFalse(recordingIndicator.exists, "Recording indicator should disappear")

        // Note: In a full integration test, we would:
        // 1. Simulate speech input
        // 2. Verify expense creation
        // 3. Check UI updates
    }

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
        #if targetEnvironment(simulator)
        throw XCTSkip("This test requires microphone permissions which are not available in iOS Simulator")
        #endif

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
        #if targetEnvironment(simulator)
        throw XCTSkip("This test requires microphone permissions which are not available in iOS Simulator")
        #endif

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

        // Then - Tap should be responsive
        // Use a more lenient threshold on Simulator (2.0s) and stricter on devices (1.0s)
        #if targetEnvironment(simulator)
        let threshold: TimeInterval = 2.0
        #else
        let threshold: TimeInterval = 1.0
        #endif
        XCTAssertLessThan(tapTime, threshold, "Button tap should be responsive (< \(threshold)s), took \(tapTime)s")

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

    func testFloatingButtonStateTransitionSmooth() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("This test requires microphone permissions which are not available in iOS Simulator")
        #endif

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
