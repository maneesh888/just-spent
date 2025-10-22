package com.justspent.app.lifecycle

import android.content.Context
import android.content.SharedPreferences
import androidx.test.core.app.ApplicationProvider
import junit.framework.TestCase.assertEquals
import junit.framework.TestCase.assertFalse
import junit.framework.TestCase.assertTrue
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

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
@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33])
class AppLifecycleManagerTest {

    private lateinit var context: Context
    private lateinit var sut: AppLifecycleManager
    private lateinit var prefs: SharedPreferences

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()

        // Clear SharedPreferences before each test
        context.getSharedPreferences("app_lifecycle_prefs", Context.MODE_PRIVATE)
            .edit().clear().commit()

        sut = AppLifecycleManager(context)
        prefs = context.getSharedPreferences("app_lifecycle_prefs", Context.MODE_PRIVATE)
    }

    @After
    fun tearDown() {
        prefs.edit().clear().commit()
    }

    // MARK: - First Launch Tests

    @Test
    fun `initialization with fresh prefs sets first launch true`() = runTest {
        // Given: Fresh SharedPreferences with no prior state (done in setUp)

        // When: Initialize AppLifecycleManager (done in setUp)

        // Then: Should detect first launch
        assertTrue("Should detect first launch", sut.isFirstLaunch.first())
    }

    @Test
    fun `initialization with completed first launch sets first launch false`() = runTest {
        // Given: SharedPreferences with first launch completed
        prefs.edit().putBoolean("first_launch_complete", true).commit()

        // When: Initialize new AppLifecycleManager
        val newSut = AppLifecycleManager(context)

        // Then: Should NOT be first launch
        assertFalse("Should not be first launch", newSut.isFirstLaunch.first())
    }

    @Test
    fun `complete first launch updates state and persists`() = runTest {
        // Given: First launch state
        assertTrue(sut.isFirstLaunch.first())

        // When: Complete first launch
        sut.completeFirstLaunch()

        // Then: State updated and persisted
        assertFalse("Should update isFirstLaunch to false", sut.isFirstLaunch.first())
        assertTrue(
            "Should persist first launch completion",
            prefs.getBoolean("first_launch_complete", false)
        )
    }

    @Test
    fun `complete first launch when already completed no change`() = runTest {
        // Given: First launch already completed
        sut.completeFirstLaunch()
        assertFalse(sut.isFirstLaunch.first())

        // When: Try to complete again
        sut.completeFirstLaunch()

        // Then: No change (idempotent)
        assertFalse(sut.isFirstLaunch.first())
    }

    // MARK: - App State Tests

    @Test
    fun `update app state to active updates state`() = runTest {
        // Given: Initial inactive state
        assertEquals(AppState.INACTIVE, sut.appState.first())

        // When: Update to active
        sut.updateAppState(AppState.ACTIVE)

        // Then: State should be active
        assertEquals(AppState.ACTIVE, sut.appState.first())
    }

    @Test
    fun `update app state to background updates state`() = runTest {
        // Given: Active state
        sut.updateAppState(AppState.ACTIVE)

        // When: Update to background
        sut.updateAppState(AppState.BACKGROUND)

        // Then: State should be background
        assertEquals(AppState.BACKGROUND, sut.appState.first())
    }

    @Test
    fun `update app state persists to shared preferences`() {
        // Given: Initial state

        // When: Update state
        sut.updateAppState(AppState.ACTIVE)

        // Then: Should persist to SharedPreferences
        val savedState = prefs.getString("last_app_state", null)
        assertEquals("ACTIVE", savedState)
    }

    // MARK: - Foreground Transition Tests

    @Test
    fun `foreground transition from background to active sets flag true`() = runTest {
        // Given: App in background
        sut.updateAppState(AppState.BACKGROUND)
        assertFalse(sut.didBecomeActive.first())

        // When: Transition to active
        sut.updateAppState(AppState.ACTIVE)

        // Then: didBecomeActive should be true
        assertTrue("Should detect foreground transition", sut.didBecomeActive.first())
    }

    @Test
    fun `foreground transition from inactive to active sets flag true`() = runTest {
        // Given: App inactive
        sut.updateAppState(AppState.INACTIVE)
        assertFalse(sut.didBecomeActive.first())

        // When: Transition to active
        sut.updateAppState(AppState.ACTIVE)

        // Then: didBecomeActive should be true
        assertTrue("Should detect foreground transition from inactive", sut.didBecomeActive.first())
    }

    @Test
    fun `foreground transition active to active keeps flag false`() = runTest {
        // Given: App already active
        sut.updateAppState(AppState.ACTIVE)
        sut.consumeForegroundTransition()
        assertFalse(sut.didBecomeActive.first())

        // When: Update to active again
        sut.updateAppState(AppState.ACTIVE)

        // Then: didBecomeActive should remain false (no transition)
        assertFalse("Should not flag transition if already active", sut.didBecomeActive.first())
    }

    @Test
    fun `consume foreground transition resets flag`() = runTest {
        // Given: Foreground transition detected
        sut.updateAppState(AppState.BACKGROUND)
        sut.updateAppState(AppState.ACTIVE)
        assertTrue(sut.didBecomeActive.first())

        // When: Consume transition
        sut.consumeForegroundTransition()

        // Then: Flag should be reset
        assertFalse("Should reset didBecomeActive flag", sut.didBecomeActive.first())
    }

    // MARK: - Auto-Recording State Tests

    @Test
    fun `start auto recording sets state true`() = runTest {
        // Given: No auto-recording active
        assertFalse(sut.isAutoRecording.first())

        // When: Start auto-recording
        sut.startAutoRecording()

        // Then: State should be true
        assertTrue(sut.isAutoRecording.first())
    }

    @Test
    fun `start auto recording when already active no change`() = runTest {
        // Given: Auto-recording already active
        sut.startAutoRecording()
        assertTrue(sut.isAutoRecording.first())

        // When: Try to start again
        sut.startAutoRecording()

        // Then: State should remain true (idempotent)
        assertTrue(sut.isAutoRecording.first())
    }

    @Test
    fun `stop auto recording sets state false`() = runTest {
        // Given: Auto-recording active
        sut.startAutoRecording()
        assertTrue(sut.isAutoRecording.first())

        // When: Stop auto-recording
        sut.stopAutoRecording()

        // Then: State should be false
        assertFalse(sut.isAutoRecording.first())
    }

    @Test
    fun `stop auto recording when not active no change`() = runTest {
        // Given: No auto-recording active
        assertFalse(sut.isAutoRecording.first())

        // When: Try to stop
        sut.stopAutoRecording()

        // Then: State should remain false (idempotent)
        assertFalse(sut.isAutoRecording.first())
    }

    // MARK: - Should Trigger Auto-Recording Tests

    @Test
    fun `should trigger auto recording first launch returns false`() = runTest {
        // Given: First launch, active state, no recording
        assertTrue(sut.isFirstLaunch.first())
        sut.updateAppState(AppState.ACTIVE)
        assertFalse(sut.isAutoRecording.first())

        // When: Check if should trigger
        val should = sut.shouldTriggerAutoRecording()

        // Then: Should NOT trigger (first launch)
        assertFalse("Should not trigger on first launch", should)
    }

    @Test
    fun `should trigger auto recording app inactive returns false`() {
        // Given: Not first launch, inactive state, no recording
        sut.completeFirstLaunch()
        sut.updateAppState(AppState.INACTIVE)

        // When: Check if should trigger
        val should = sut.shouldTriggerAutoRecording()

        // Then: Should NOT trigger (app inactive)
        assertFalse("Should not trigger when app inactive", should)
    }

    @Test
    fun `should trigger auto recording already recording returns false`() {
        // Given: Not first launch, active state, already recording
        sut.completeFirstLaunch()
        sut.updateAppState(AppState.ACTIVE)
        sut.startAutoRecording()

        // When: Check if should trigger
        val should = sut.shouldTriggerAutoRecording()

        // Then: Should NOT trigger (already recording)
        assertFalse("Should not trigger when already recording", should)
    }

    @Test
    fun `should trigger auto recording all conditions met returns true`() {
        // Given: Not first launch, active state, no recording
        sut.completeFirstLaunch()
        sut.updateAppState(AppState.ACTIVE)

        // When: Check if should trigger
        val should = sut.shouldTriggerAutoRecording()

        // Then: Should trigger
        assertTrue("Should trigger when all conditions met", should)
    }

    // MARK: - Integration Tests

    @Test
    fun `complete flow first launch to subsequent launch`() = runTest {
        // Scenario: User's first launch → grants permissions → closes app → reopens

        // 1. First launch - should NOT auto-record
        assertTrue(sut.isFirstLaunch.first())
        sut.updateAppState(AppState.ACTIVE)
        assertFalse("No auto-record on first launch", sut.shouldTriggerAutoRecording())

        // 2. User grants permissions and completes first launch
        sut.completeFirstLaunch()
        assertFalse(sut.isFirstLaunch.first())

        // 3. App goes to background
        sut.updateAppState(AppState.BACKGROUND)

        // 4. App returns to foreground (subsequent launch simulation)
        sut.updateAppState(AppState.ACTIVE)
        assertTrue("Should detect foreground transition", sut.didBecomeActive.first())
        assertTrue("Should auto-record on subsequent launch", sut.shouldTriggerAutoRecording())
    }

    @Test
    fun `complete flow auto recording lifecycle`() = runTest {
        // Scenario: App in good state → auto-recording triggered → completes → ready for next

        // 1. Setup: Not first launch, app active
        sut.completeFirstLaunch()
        sut.updateAppState(AppState.ACTIVE)
        assertTrue(sut.shouldTriggerAutoRecording())

        // 2. Auto-recording starts
        sut.startAutoRecording()
        assertTrue(sut.isAutoRecording.first())
        assertFalse("Should not trigger while recording", sut.shouldTriggerAutoRecording())

        // 3. Auto-recording completes
        sut.stopAutoRecording()
        assertFalse(sut.isAutoRecording.first())

        // 4. Should be ready for next auto-recording
        assertTrue("Should be ready for next session", sut.shouldTriggerAutoRecording())
    }

    // MARK: - AppState Enum Tests

    @Test
    fun `app state active is not background`() {
        assertFalse(AppState.ACTIVE.isBackground())
    }

    @Test
    fun `app state inactive is background`() {
        assertTrue(AppState.INACTIVE.isBackground())
    }

    @Test
    fun `app state background is background`() {
        assertTrue(AppState.BACKGROUND.isBackground())
    }
}
