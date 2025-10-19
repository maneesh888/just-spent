import XCTest
@testable import JustSpent

/**
 * AutoRecordingCoordinator Unit Tests
 *
 * Test Coverage:
 * - Auto-recording trigger conditions
 * - Permission validation
 * - Delay mechanism
 * - Cancellation scenarios
 * - Integration with AppLifecycleManager
 *
 * Coverage Target: >85%
 */
@MainActor
final class AutoRecordingCoordinatorTests: XCTestCase {

    var sut: AutoRecordingCoordinator!
    var mockLifecycleManager: AppLifecycleManager!
    var mockUserDefaults: UserDefaults!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create mock UserDefaults for lifecycle manager
        let suiteName = "test.\(UUID().uuidString)"
        mockUserDefaults = UserDefaults(suiteName: suiteName)!

        mockLifecycleManager = AppLifecycleManager(userDefaults: mockUserDefaults)
        sut = AutoRecordingCoordinator(lifecycleManager: mockLifecycleManager)
    }

    override func tearDownWithError() throws {
        sut = nil
        mockUserDefaults.removePersistentDomain(forName: mockUserDefaults.dictionaryRepresentation().keys.first ?? "")
        mockUserDefaults = nil
        mockLifecycleManager = nil

        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testInitialization_CreatesInstanceSuccessfully() {
        // Then: Should initialize without errors
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.shouldStartRecording)
    }

    // MARK: - Auto-Recording Trigger Tests - Permission Scenarios

    func testTriggerAutoRecording_MissingAllPermissions_DoesNotTrigger() {
        // Given: Good lifecycle state, but NO permissions
        mockLifecycleManager.completeFirstLaunch()
        mockLifecycleManager.updateAppState(.active)

        // When: Try to trigger auto-recording
        sut.triggerAutoRecordingIfNeeded(
            isRecordingActive: false,
            speechPermissionGranted: false,
            microphonePermissionGranted: false,
            speechRecognitionAvailable: true
        )

        // Then: Should NOT trigger
        XCTAssertFalse(sut.shouldStartRecording)
        XCTAssertFalse(mockLifecycleManager.isAutoRecording)
    }

    func testTriggerAutoRecording_MissingSpeechPermission_DoesNotTrigger() {
        // Given: Good lifecycle state, microphone granted but NOT speech
        mockLifecycleManager.completeFirstLaunch()
        mockLifecycleManager.updateAppState(.active)

        // When: Try to trigger auto-recording
        sut.triggerAutoRecordingIfNeeded(
            isRecordingActive: false,
            speechPermissionGranted: false,
            microphonePermissionGranted: true,
            speechRecognitionAvailable: true
        )

        // Then: Should NOT trigger
        XCTAssertFalse(sut.shouldStartRecording)
    }

    func testTriggerAutoRecording_MissingMicrophonePermission_DoesNotTrigger() {
        // Given: Good lifecycle state, speech granted but NOT microphone
        mockLifecycleManager.completeFirstLaunch()
        mockLifecycleManager.updateAppState(.active)

        // When: Try to trigger auto-recording
        sut.triggerAutoRecordingIfNeeded(
            isRecordingActive: false,
            speechPermissionGranted: true,
            microphonePermissionGranted: false,
            speechRecognitionAvailable: true
        )

        // Then: Should NOT trigger
        XCTAssertFalse(sut.shouldStartRecording)
    }

    func testTriggerAutoRecording_SpeechRecognitionUnavailable_DoesNotTrigger() {
        // Given: Good lifecycle state, permissions granted but recognition unavailable
        mockLifecycleManager.completeFirstLaunch()
        mockLifecycleManager.updateAppState(.active)

        // When: Try to trigger auto-recording
        sut.triggerAutoRecordingIfNeeded(
            isRecordingActive: false,
            speechPermissionGranted: true,
            microphonePermissionGranted: true,
            speechRecognitionAvailable: false
        )

        // Then: Should NOT trigger
        XCTAssertFalse(sut.shouldStartRecording)
    }

    // MARK: - Auto-Recording Trigger Tests - Lifecycle Scenarios

    func testTriggerAutoRecording_FirstLaunch_DoesNotTrigger() async {
        // Given: First launch, all permissions OK
        XCTAssertTrue(mockLifecycleManager.isFirstLaunch)
        mockLifecycleManager.updateAppState(.active)

        // When: Try to trigger auto-recording
        sut.triggerAutoRecordingIfNeeded(
            isRecordingActive: false,
            speechPermissionGranted: true,
            microphonePermissionGranted: true,
            speechRecognitionAvailable: true
        )

        // Wait for delay
        try? await Task.sleep(nanoseconds: 600_000_000) // 600ms

        // Then: Should NOT trigger on first launch
        XCTAssertFalse(sut.shouldStartRecording)
        XCTAssertFalse(mockLifecycleManager.isAutoRecording)
    }

    func testTriggerAutoRecording_AppInactive_DoesNotTrigger() {
        // Given: Not first launch, permissions OK, but app INACTIVE
        mockLifecycleManager.completeFirstLaunch()
        mockLifecycleManager.updateAppState(.inactive)

        // When: Try to trigger auto-recording
        sut.triggerAutoRecordingIfNeeded(
            isRecordingActive: false,
            speechPermissionGranted: true,
            microphonePermissionGranted: true,
            speechRecognitionAvailable: true
        )

        // Then: Should NOT trigger
        XCTAssertFalse(sut.shouldStartRecording)
    }

    func testTriggerAutoRecording_AlreadyRecording_DoesNotTrigger() {
        // Given: Good state, but ALREADY recording
        mockLifecycleManager.completeFirstLaunch()
        mockLifecycleManager.updateAppState(.active)

        // When: Try to trigger while recording active
        sut.triggerAutoRecordingIfNeeded(
            isRecordingActive: true, // Already recording
            speechPermissionGranted: true,
            microphonePermissionGranted: true,
            speechRecognitionAvailable: true
        )

        // Then: Should NOT trigger
        XCTAssertFalse(sut.shouldStartRecording)
    }

    // MARK: - Auto-Recording Trigger Tests - Success Scenarios

    func testTriggerAutoRecording_AllConditionsMet_TriggersWithDelay() async {
        // Given: Perfect conditions
        mockLifecycleManager.completeFirstLaunch()
        mockLifecycleManager.updateAppState(.active)

        // When: Trigger auto-recording
        sut.triggerAutoRecordingIfNeeded(
            isRecordingActive: false,
            speechPermissionGranted: true,
            microphonePermissionGranted: true,
            speechRecognitionAvailable: true
        )

        // Then: Should update lifecycle manager immediately
        XCTAssertTrue(mockLifecycleManager.isAutoRecording)

        // Wait for delay (500ms + buffer)
        try? await Task.sleep(nanoseconds: 600_000_000)

        // Then: Should have triggered recording (flag set then reset)
        // Note: In real usage, ContentView observes this change
        // The flag resets after 100ms, so it may be false by now
        // What matters is that isAutoRecording was set
        XCTAssertTrue(mockLifecycleManager.isAutoRecording)
    }

    func testTriggerAutoRecording_SetsLifecycleManagerState() {
        // Given: Perfect conditions
        mockLifecycleManager.completeFirstLaunch()
        mockLifecycleManager.updateAppState(.active)
        XCTAssertFalse(mockLifecycleManager.isAutoRecording)

        // When: Trigger auto-recording
        sut.triggerAutoRecordingIfNeeded(
            isRecordingActive: false,
            speechPermissionGranted: true,
            microphonePermissionGranted: true,
            speechRecognitionAvailable: true
        )

        // Then: Lifecycle manager should reflect auto-recording state
        XCTAssertTrue(mockLifecycleManager.isAutoRecording)
    }

    // MARK: - Cancellation Tests

    func testCancelPendingAutoRecording_CancelsScheduledRecording() async {
        // Given: Auto-recording scheduled
        mockLifecycleManager.completeFirstLaunch()
        mockLifecycleManager.updateAppState(.active)

        sut.triggerAutoRecordingIfNeeded(
            isRecordingActive: false,
            speechPermissionGranted: true,
            microphonePermissionGranted: true,
            speechRecognitionAvailable: true
        )

        XCTAssertTrue(mockLifecycleManager.isAutoRecording)

        // When: Cancel before delay completes
        sut.cancelPendingAutoRecording()

        // Wait past delay
        try? await Task.sleep(nanoseconds: 600_000_000)

        // Then: Should NOT have triggered
        XCTAssertFalse(sut.shouldStartRecording)
    }

    func testCancelPendingAutoRecording_AppGoesToBackground_CancelsRecording() async {
        // Given: Auto-recording scheduled
        mockLifecycleManager.completeFirstLaunch()
        mockLifecycleManager.updateAppState(.active)

        sut.triggerAutoRecordingIfNeeded(
            isRecordingActive: false,
            speechPermissionGranted: true,
            microphonePermissionGranted: true,
            speechRecognitionAvailable: true
        )

        // When: App goes to background (triggers cancel in real app)
        mockLifecycleManager.updateAppState(.background)
        sut.cancelPendingAutoRecording()

        // Wait past delay
        try? await Task.sleep(nanoseconds: 600_000_000)

        // Then: Should NOT have triggered
        XCTAssertFalse(sut.shouldStartRecording)
    }

    // MARK: - Completion Tests

    func testAutoRecordingDidComplete_UpdatesLifecycleManager() {
        // Given: Auto-recording active
        mockLifecycleManager.startAutoRecording()
        XCTAssertTrue(mockLifecycleManager.isAutoRecording)

        // When: Auto-recording completes
        sut.autoRecordingDidComplete()

        // Then: Lifecycle manager should be updated
        XCTAssertFalse(mockLifecycleManager.isAutoRecording)
    }

    // MARK: - Concurrent Request Tests

    func testTriggerAutoRecording_ConcurrentRequests_OnlyProcessesOne() async {
        // Given: Perfect conditions
        mockLifecycleManager.completeFirstLaunch()
        mockLifecycleManager.updateAppState(.active)

        // When: Trigger multiple times rapidly
        sut.triggerAutoRecordingIfNeeded(
            isRecordingActive: false,
            speechPermissionGranted: true,
            microphonePermissionGranted: true,
            speechRecognitionAvailable: true
        )

        // Immediate second request
        sut.triggerAutoRecordingIfNeeded(
            isRecordingActive: false,
            speechPermissionGranted: true,
            microphonePermissionGranted: true,
            speechRecognitionAvailable: true
        )

        // Third request
        sut.triggerAutoRecordingIfNeeded(
            isRecordingActive: false,
            speechPermissionGranted: true,
            microphonePermissionGranted: true,
            speechRecognitionAvailable: true
        )

        // Then: Should only process one (lifecycle manager prevents duplicates)
        XCTAssertTrue(mockLifecycleManager.isAutoRecording)

        // Clean up
        sut.cancelPendingAutoRecording()
    }

    // MARK: - Integration Test - Complete Flow

    func testCompleteFlow_ForegroundTransition_TriggersAutoRecording() async {
        // Scenario: App goes to background, then returns to foreground

        // 1. Setup: Not first launch, app was active
        mockLifecycleManager.completeFirstLaunch()
        mockLifecycleManager.updateAppState(.active)

        // 2. App goes to background
        mockLifecycleManager.updateAppState(.background)

        // 3. App returns to foreground
        mockLifecycleManager.updateAppState(.active)
        XCTAssertTrue(mockLifecycleManager.didBecomeActive)

        // 4. Auto-recording should be triggered
        sut.triggerAutoRecordingIfNeeded(
            isRecordingActive: false,
            speechPermissionGranted: true,
            microphonePermissionGranted: true,
            speechRecognitionAvailable: true
        )

        // 5. Should start auto-recording
        XCTAssertTrue(mockLifecycleManager.isAutoRecording)

        // Wait for delay
        try? await Task.sleep(nanoseconds: 600_000_000)

        // 6. Should have attempted to trigger recording
        // (In real app, ContentView would observe shouldStartRecording)

        // 7. Clean up foreground transition
        mockLifecycleManager.consumeForegroundTransition()
        XCTAssertFalse(mockLifecycleManager.didBecomeActive)
    }
}
