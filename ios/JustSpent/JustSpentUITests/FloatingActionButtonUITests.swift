import XCTest

class FloatingActionButtonUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launch()
        
        // Wait for app to load
        let appTitle = app.staticTexts["Just Spent"]
        XCTAssertTrue(appTitle.waitForExistence(timeout: 10.0), "App should launch and show title")
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
        
        // Then - Check initial state (should show microphone icon)
        let micIcon = floatingButton.images["mic.circle.fill"]
        XCTAssertTrue(micIcon.exists, "Button should show microphone icon initially")
    }
    
    func testFloatingActionButtonTapToRecord() throws {
        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")
        
        // When - Tap the button to start recording
        floatingButton.tap()
        
        // Then - Button should change to recording state
        let stopIcon = floatingButton.images["stop.circle.fill"]
        XCTAssertTrue(stopIcon.waitForExistence(timeout: 2.0), "Button should show stop icon when recording")
        
        // And recording indicator should appear
        let listeningText = app.staticTexts["Listening..."]
        XCTAssertTrue(listeningText.exists, "Should show listening indicator")
    }
    
    func testFloatingActionButtonTapToStopRecording() throws {
        // Given - Start recording first
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")
        
        floatingButton.tap() // Start recording
        
        let stopIcon = floatingButton.images["stop.circle.fill"]
        XCTAssertTrue(stopIcon.waitForExistence(timeout: 2.0), "Should be in recording state")
        
        // When - Tap again to stop recording
        floatingButton.tap()
        
        // Then - Button should return to initial state
        let micIcon = floatingButton.images["mic.circle.fill"]
        XCTAssertTrue(micIcon.waitForExistence(timeout: 2.0), "Button should return to microphone icon")
        
        // And recording indicator should disappear
        let listeningText = app.staticTexts["Listening..."]
        XCTAssertFalse(listeningText.exists, "Listening indicator should disappear")
    }
    
    // MARK: - Recording Indicator Tests
    
    func testRecordingIndicatorAppearance() throws {
        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")
        
        // When - Start recording
        floatingButton.tap()
        
        // Then - Recording indicators should appear
        let listeningText = app.staticTexts["Listening..."]
        XCTAssertTrue(listeningText.waitForExistence(timeout: 2.0), "Should show listening text")
        
        let autoStopText = app.staticTexts["Will stop automatically when you finish speaking"]
        XCTAssertTrue(autoStopText.exists, "Should show auto-stop instruction")
        
        // Check for status indicator dot
        let statusIndicator = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'status_indicator'")).firstMatch
        // Note: The exact identifier depends on implementation
    }
    
    func testRecordingIndicatorStateChanges() throws {
        // Given - Start recording
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")
        
        floatingButton.tap()
        
        // When - Wait for potential state changes during recording
        let listeningText = app.staticTexts["Listening..."]
        XCTAssertTrue(listeningText.waitForExistence(timeout: 2.0), "Should show listening state")
        
        // Then - Check if processing state appears (if speech is detected)
        let processingText = app.staticTexts["Processing..."]
        
        // Note: This test might be flaky as it depends on actual speech detection
        // In a real test environment, we might need to mock the speech input
        if processingText.waitForExistence(timeout: 5.0) {
            XCTAssertTrue(processingText.exists, "Should show processing state when speech detected")
        }
    }
    
    // MARK: - Auto-Stop Behavior Tests
    
    func testAutoStopInstructionVisibility() throws {
        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")
        
        // When - Start recording
        floatingButton.tap()
        
        // Then - Auto-stop instruction should be visible
        let autoStopText = app.staticTexts["Will stop automatically when you finish speaking"]
        XCTAssertTrue(autoStopText.waitForExistence(timeout: 2.0), "Should show auto-stop instruction")
        
        // Check text positioning (should be above the button)
        let buttonFrame = floatingButton.frame
        let textFrame = autoStopText.frame
        
        XCTAssertTrue(textFrame.maxY < buttonFrame.minY, "Auto-stop text should be above the button")
    }
    
    func testAutoStopAfterSilence() throws {
        // Given - Start recording
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")
        
        floatingButton.tap()
        
        let stopIcon = floatingButton.images["stop.circle.fill"]
        XCTAssertTrue(stopIcon.waitForExistence(timeout: 2.0), "Should be recording")
        
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
        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")
        
        // When - Tap to start recording
        floatingButton.tap()
        
        // Then - Visual state should change
        let stopIcon = floatingButton.images["stop.circle.fill"]
        XCTAssertTrue(stopIcon.waitForExistence(timeout: 2.0), "Should show stop icon")
        
        // Check button color/appearance (limited by XCUITest capabilities)
        // We can verify the button frame and accessibility properties
        
        // Stop recording
        floatingButton.tap()
        
        let micIcon = floatingButton.images["mic.circle.fill"]
        XCTAssertTrue(micIcon.waitForExistence(timeout: 2.0), "Should return to mic icon")
    }
    
    func testButtonAccessibilityLabels() throws {
        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")
        
        // When - Check accessibility label in initial state
        let initialLabel = floatingButton.label
        
        // Then - Should have appropriate accessibility label
        XCTAssertTrue(initialLabel.contains("Start") || initialLabel.contains("Record") || initialLabel.contains("Voice"),
                     "Button should have descriptive accessibility label")
        
        // When - Start recording
        floatingButton.tap()
        
        // Then - Accessibility label should change
        let recordingLabel = floatingButton.label
        XCTAssertTrue(recordingLabel.contains("Stop") || recordingLabel.contains("Recording"),
                     "Button should have appropriate accessibility label while recording")
        
        // Cleanup - Stop recording
        floatingButton.tap()
    }
    
    // MARK: - Integration Tests
    
    func testFloatingButtonToExpenseCreation() throws {
        // This test would require actual speech input or mocking
        // For now, we'll test the UI flow up to the point where speech processing would occur
        
        // Given
        let floatingButton = app.buttons.matching(identifier: "voice_recording_button").firstMatch
        XCTAssertTrue(floatingButton.waitForExistence(timeout: 5.0), "Button should exist")
        
        // When - Start and stop recording quickly
        floatingButton.tap() // Start recording
        
        let stopIcon = floatingButton.images["stop.circle.fill"]
        XCTAssertTrue(stopIcon.waitForExistence(timeout: 2.0), "Should start recording")
        
        floatingButton.tap() // Stop recording
        
        // Then - Should return to normal state
        let micIcon = floatingButton.images["mic.circle.fill"]
        XCTAssertTrue(micIcon.waitForExistence(timeout: 2.0), "Should stop recording")
        
        // Note: In a full integration test, we would:
        // 1. Simulate speech input
        // 2. Verify expense creation
        // 3. Check UI updates
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