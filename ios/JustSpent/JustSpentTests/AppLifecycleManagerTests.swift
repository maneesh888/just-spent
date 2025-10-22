import XCTest
@testable import JustSpent

/**
 * AppLifecycleManager Unit Tests
 *
 * Test Coverage:
 * - First launch detection and completion
 * - App state transitions
 * - Foreground transition detection
 * - Auto-recording state management
 * - Edge cases and concurrent operations
 *
 * Coverage Target: >90%
 */
@MainActor
final class AppLifecycleManagerTests: XCTestCase {

    var sut: AppLifecycleManager!
    var mockUserDefaults: UserDefaults!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Use a unique suite name for each test to ensure isolation
        let suiteName = "test.\(UUID().uuidString)"
        mockUserDefaults = UserDefaults(suiteName: suiteName)!

        sut = AppLifecycleManager(userDefaults: mockUserDefaults)
    }

    override func tearDownWithError() throws {
        // Clean up user defaults
        mockUserDefaults.removePersistentDomain(forName: mockUserDefaults.dictionaryRepresentation().keys.first ?? "")
        mockUserDefaults = nil
        sut = nil

        try super.tearDownWithError()
    }

    // MARK: - First Launch Tests

    func testInitialization_FirstLaunch_SetsFirstLaunchTrue() {
        // Given: Fresh UserDefaults with no prior state

        // When: Initialize AppLifecycleManager
        // (Already done in setUp)

        // Then: Should detect first launch
        XCTAssertTrue(sut.isFirstLaunch, "Should detect first launch")
    }

    func testInitialization_SubsequentLaunch_SetsFirstLaunchFalse() {
        // Given: UserDefaults with first launch completed
        mockUserDefaults.set(true, forKey: "AppLifecycle_FirstLaunchComplete")

        // When: Initialize new AppLifecycleManager
        sut = AppLifecycleManager(userDefaults: mockUserDefaults)

        // Then: Should NOT be first launch
        XCTAssertFalse(sut.isFirstLaunch, "Should not be first launch")
    }

    func testCompleteFirstLaunch_FirstTime_UpdatesStateAndPersists() {
        // Given: First launch state
        XCTAssertTrue(sut.isFirstLaunch)

        // When: Complete first launch
        sut.completeFirstLaunch()

        // Then: State updated and persisted
        XCTAssertFalse(sut.isFirstLaunch, "Should update isFirstLaunch to false")
        XCTAssertTrue(
            mockUserDefaults.bool(forKey: "AppLifecycle_FirstLaunchComplete"),
            "Should persist first launch completion"
        )
    }

    func testCompleteFirstLaunch_AlreadyCompleted_NoChange() {
        // Given: First launch already completed
        sut.completeFirstLaunch()
        XCTAssertFalse(sut.isFirstLaunch)

        // When: Try to complete again
        sut.completeFirstLaunch()

        // Then: No change (idempotent)
        XCTAssertFalse(sut.isFirstLaunch)
    }

    // MARK: - App State Tests

    func testUpdateAppState_ToActive_UpdatesState() {
        // Given: Initial inactive state
        XCTAssertEqual(sut.appState, .inactive)

        // When: Update to active
        sut.updateAppState(.active)

        // Then: State should be active
        XCTAssertEqual(sut.appState, .active)
    }

    func testUpdateAppState_ToBackground_UpdatesState() {
        // Given: Active state
        sut.updateAppState(.active)

        // When: Update to background
        sut.updateAppState(.background)

        // Then: State should be background
        XCTAssertEqual(sut.appState, .background)
    }

    func testUpdateAppState_PersistsToUserDefaults() {
        // Given: Initial state

        // When: Update state
        sut.updateAppState(.active)

        // Then: Should persist to UserDefaults
        let savedState = mockUserDefaults.string(forKey: "AppLifecycle_LastAppState")
        XCTAssertEqual(savedState, "active")
    }

    // MARK: - Foreground Transition Tests

    func testForegroundTransition_FromBackgroundToActive_SetsFlagTrue() {
        // Given: App in background
        sut.updateAppState(.background)
        XCTAssertFalse(sut.didBecomeActive)

        // When: Transition to active
        sut.updateAppState(.active)

        // Then: didBecomeActive should be true
        XCTAssertTrue(sut.didBecomeActive, "Should detect foreground transition")
    }

    func testForegroundTransition_FromInactiveToActive_SetsFlagTrue() {
        // Given: App inactive
        sut.updateAppState(.inactive)
        XCTAssertFalse(sut.didBecomeActive)

        // When: Transition to active
        sut.updateAppState(.active)

        // Then: didBecomeActive should be true
        XCTAssertTrue(sut.didBecomeActive, "Should detect foreground transition from inactive")
    }

    func testForegroundTransition_ActiveToActive_KeepsFlagFalse() {
        // Given: App already active
        sut.updateAppState(.active)
        sut.consumeForegroundTransition()
        XCTAssertFalse(sut.didBecomeActive)

        // When: Update to active again
        sut.updateAppState(.active)

        // Then: didBecomeActive should remain false (no transition)
        XCTAssertFalse(sut.didBecomeActive, "Should not flag transition if already active")
    }

    func testConsumeForegroundTransition_ResetFlag() {
        // Given: Foreground transition detected
        sut.updateAppState(.background)
        sut.updateAppState(.active)
        XCTAssertTrue(sut.didBecomeActive)

        // When: Consume transition
        sut.consumeForegroundTransition()

        // Then: Flag should be reset
        XCTAssertFalse(sut.didBecomeActive, "Should reset didBecomeActive flag")
    }

    // MARK: - Auto-Recording State Tests

    func testStartAutoRecording_SetsStateTrue() {
        // Given: No auto-recording active
        XCTAssertFalse(sut.isAutoRecording)

        // When: Start auto-recording
        sut.startAutoRecording()

        // Then: State should be true
        XCTAssertTrue(sut.isAutoRecording)
    }

    func testStartAutoRecording_WhenAlreadyActive_NoChange() {
        // Given: Auto-recording already active
        sut.startAutoRecording()
        XCTAssertTrue(sut.isAutoRecording)

        // When: Try to start again
        sut.startAutoRecording()

        // Then: State should remain true (idempotent)
        XCTAssertTrue(sut.isAutoRecording)
    }

    func testStopAutoRecording_SetsStateFalse() {
        // Given: Auto-recording active
        sut.startAutoRecording()
        XCTAssertTrue(sut.isAutoRecording)

        // When: Stop auto-recording
        sut.stopAutoRecording()

        // Then: State should be false
        XCTAssertFalse(sut.isAutoRecording)
    }

    func testStopAutoRecording_WhenNotActive_NoChange() {
        // Given: No auto-recording active
        XCTAssertFalse(sut.isAutoRecording)

        // When: Try to stop
        sut.stopAutoRecording()

        // Then: State should remain false (idempotent)
        XCTAssertFalse(sut.isAutoRecording)
    }

    // MARK: - Should Trigger Auto-Recording Tests

    func testShouldTriggerAutoRecording_FirstLaunch_ReturnsFalse() {
        // Given: First launch, active state, no recording
        XCTAssertTrue(sut.isFirstLaunch)
        sut.updateAppState(.active)
        XCTAssertFalse(sut.isAutoRecording)

        // When: Check if should trigger
        let should = sut.shouldTriggerAutoRecording()

        // Then: Should NOT trigger (first launch)
        XCTAssertFalse(should, "Should not trigger on first launch")
    }

    func testShouldTriggerAutoRecording_AppInactive_ReturnsFalse() {
        // Given: Not first launch, inactive state, no recording
        sut.completeFirstLaunch()
        sut.updateAppState(.inactive)
        XCTAssertFalse(sut.isAutoRecording)

        // When: Check if should trigger
        let should = sut.shouldTriggerAutoRecording()

        // Then: Should NOT trigger (app inactive)
        XCTAssertFalse(should, "Should not trigger when app inactive")
    }

    func testShouldTriggerAutoRecording_AlreadyRecording_ReturnsFalse() {
        // Given: Not first launch, active state, already recording
        sut.completeFirstLaunch()
        sut.updateAppState(.active)
        sut.startAutoRecording()

        // When: Check if should trigger
        let should = sut.shouldTriggerAutoRecording()

        // Then: Should NOT trigger (already recording)
        XCTAssertFalse(should, "Should not trigger when already recording")
    }

    func testShouldTriggerAutoRecording_AllConditionsMet_ReturnsTrue() {
        // Given: Not first launch, active state, no recording
        sut.completeFirstLaunch()
        sut.updateAppState(.active)
        XCTAssertFalse(sut.isAutoRecording)

        // When: Check if should trigger
        let should = sut.shouldTriggerAutoRecording()

        // Then: Should trigger
        XCTAssertTrue(should, "Should trigger when all conditions met")
    }

    // MARK: - Integration Tests

    func testCompleteFlow_FirstLaunchToSubsequentLaunch() {
        // Scenario: User's first launch → grants permissions → closes app → reopens

        // 1. First launch - should NOT auto-record
        XCTAssertTrue(sut.isFirstLaunch)
        sut.updateAppState(.active)
        XCTAssertFalse(sut.shouldTriggerAutoRecording(), "No auto-record on first launch")

        // 2. User grants permissions and completes first launch
        sut.completeFirstLaunch()
        XCTAssertFalse(sut.isFirstLaunch)

        // 3. App goes to background
        sut.updateAppState(.background)

        // 4. App returns to foreground (subsequent launch simulation)
        sut.updateAppState(.active)
        XCTAssertTrue(sut.didBecomeActive, "Should detect foreground transition")
        XCTAssertTrue(sut.shouldTriggerAutoRecording(), "Should auto-record on subsequent launch")
    }

    func testCompleteFlow_AutoRecordingLifecycle() {
        // Scenario: App in good state → auto-recording triggered → completes → ready for next

        // 1. Setup: Not first launch, app active
        sut.completeFirstLaunch()
        sut.updateAppState(.active)
        XCTAssertTrue(sut.shouldTriggerAutoRecording())

        // 2. Auto-recording starts
        sut.startAutoRecording()
        XCTAssertTrue(sut.isAutoRecording)
        XCTAssertFalse(sut.shouldTriggerAutoRecording(), "Should not trigger while recording")

        // 3. Auto-recording completes
        sut.stopAutoRecording()
        XCTAssertFalse(sut.isAutoRecording)

        // 4. Should be ready for next auto-recording
        XCTAssertTrue(sut.shouldTriggerAutoRecording(), "Should be ready for next session")
    }

    // MARK: - AppState Enum Tests

    func testAppStateFromScenePhase_Active() {
        let state = AppState(from: .active)
        XCTAssertEqual(state, .active)
        XCTAssertFalse(state.isBackground)
    }

    func testAppStateFromScenePhase_Inactive() {
        let state = AppState(from: .inactive)
        XCTAssertEqual(state, .inactive)
        XCTAssertTrue(state.isBackground)
    }

    func testAppStateFromScenePhase_Background() {
        let state = AppState(from: .background)
        XCTAssertEqual(state, .background)
        XCTAssertTrue(state.isBackground)
    }
}
