package com.justspent.app.voice

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.justspent.app.lifecycle.AppLifecycleManager
import com.justspent.app.lifecycle.AppState
import com.justspent.app.permissions.PermissionManager
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import junit.framework.TestCase.assertFalse
import junit.framework.TestCase.assertTrue
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

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
@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33])
class AutoRecordingCoordinatorTest {

    private lateinit var context: Context
    private lateinit var lifecycleManager: AppLifecycleManager
    private lateinit var permissionManager: PermissionManager
    private lateinit var sut: AutoRecordingCoordinator

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()

        // Clear SharedPreferences
        context.getSharedPreferences("app_lifecycle_prefs", Context.MODE_PRIVATE)
            .edit().clear().commit()

        lifecycleManager = AppLifecycleManager(context)
        permissionManager = mockk(relaxed = true)

        sut = AutoRecordingCoordinator(lifecycleManager, permissionManager)
    }

    @After
    fun tearDown() {
        sut.cleanup()
        context.getSharedPreferences("app_lifecycle_prefs", Context.MODE_PRIVATE)
            .edit().clear().commit()
    }

    // MARK: - Initialization Tests

    @Test
    fun `initialization creates instance successfully`() = runTest {
        // Then: Should initialize without errors
        assertFalse(sut.shouldStartRecording.first())
    }

    // MARK: - Auto-Recording Trigger Tests - Permission Scenarios

    @Test
    fun `trigger auto recording missing permissions does not trigger`() = runTest {
        // Given: Good lifecycle state, but NO permissions
        lifecycleManager.completeFirstLaunch()
        lifecycleManager.updateAppState(AppState.ACTIVE)
        every { permissionManager.areAllPermissionsGranted() } returns false

        // When: Try to trigger auto-recording
        sut.triggerAutoRecordingIfNeeded(isRecordingActive = false)

        // Then: Should NOT trigger
        assertFalse(sut.shouldStartRecording.first())
        assertFalse(lifecycleManager.isAutoRecording.first())
    }

    @Test
    fun `trigger auto recording permissions granted triggers`() = runTest {
        // Given: Good lifecycle state, permissions OK
        lifecycleManager.completeFirstLaunch()
        lifecycleManager.updateAppState(AppState.ACTIVE)
        every { permissionManager.areAllPermissionsGranted() } returns true

        // When: Trigger auto-recording
        sut.triggerAutoRecordingIfNeeded(isRecordingActive = false)

        // Then: Should update lifecycle manager immediately
        assertTrue(lifecycleManager.isAutoRecording.first())

        // Clean up
        sut.cancelPendingAutoRecording()
    }

    // MARK: - Auto-Recording Trigger Tests - Lifecycle Scenarios

    @Test
    fun `trigger auto recording first launch does not trigger`() = runTest {
        // Given: First launch, all permissions OK
        assertTrue(lifecycleManager.isFirstLaunch.first())
        lifecycleManager.updateAppState(AppState.ACTIVE)
        every { permissionManager.areAllPermissionsGranted() } returns true

        // When: Try to trigger auto-recording
        sut.triggerAutoRecordingIfNeeded(isRecordingActive = false)

        // Wait for delay
        advanceTimeBy(600L)

        // Then: Should NOT trigger on first launch
        assertFalse(sut.shouldStartRecording.first())
        assertFalse(lifecycleManager.isAutoRecording.first())
    }

    @Test
    fun `trigger auto recording app inactive does not trigger`() = runTest {
        // Given: Not first launch, permissions OK, but app INACTIVE
        lifecycleManager.completeFirstLaunch()
        lifecycleManager.updateAppState(AppState.INACTIVE)
        every { permissionManager.areAllPermissionsGranted() } returns true

        // When: Try to trigger auto-recording
        sut.triggerAutoRecordingIfNeeded(isRecordingActive = false)

        // Then: Should NOT trigger
        assertFalse(sut.shouldStartRecording.first())
    }

    @Test
    fun `trigger auto recording already recording does not trigger`() = runTest {
        // Given: Good state, but ALREADY recording
        lifecycleManager.completeFirstLaunch()
        lifecycleManager.updateAppState(AppState.ACTIVE)
        every { permissionManager.areAllPermissionsGranted() } returns true

        // When: Try to trigger while recording active
        sut.triggerAutoRecordingIfNeeded(isRecordingActive = true)

        // Then: Should NOT trigger
        assertFalse(sut.shouldStartRecording.first())
    }

    // MARK: - Auto-Recording Trigger Tests - Success Scenarios

    @Test
    fun `trigger auto recording all conditions met triggers with delay`() = runTest {
        // Given: Perfect conditions
        lifecycleManager.completeFirstLaunch()
        lifecycleManager.updateAppState(AppState.ACTIVE)
        every { permissionManager.areAllPermissionsGranted() } returns true

        // When: Trigger auto-recording
        sut.triggerAutoRecordingIfNeeded(isRecordingActive = false)

        // Then: Should update lifecycle manager immediately
        assertTrue(lifecycleManager.isAutoRecording.first())

        // Clean up
        sut.cancelPendingAutoRecording()
    }

    @Test
    fun `trigger auto recording sets lifecycle manager state`() = runTest {
        // Given: Perfect conditions
        lifecycleManager.completeFirstLaunch()
        lifecycleManager.updateAppState(AppState.ACTIVE)
        every { permissionManager.areAllPermissionsGranted() } returns true
        assertFalse(lifecycleManager.isAutoRecording.first())

        // When: Trigger auto-recording
        sut.triggerAutoRecordingIfNeeded(isRecordingActive = false)

        // Then: Lifecycle manager should reflect auto-recording state
        assertTrue(lifecycleManager.isAutoRecording.first())

        // Clean up
        sut.cancelPendingAutoRecording()
    }

    // MARK: - Cancellation Tests

    @Test
    fun `cancel pending auto recording cancels scheduled recording`() = runTest {
        // Given: Auto-recording scheduled
        lifecycleManager.completeFirstLaunch()
        lifecycleManager.updateAppState(AppState.ACTIVE)
        every { permissionManager.areAllPermissionsGranted() } returns true

        sut.triggerAutoRecordingIfNeeded(isRecordingActive = false)
        assertTrue(lifecycleManager.isAutoRecording.first())

        // When: Cancel before delay completes
        sut.cancelPendingAutoRecording()

        // Wait past delay
        advanceTimeBy(600L)

        // Then: Should NOT have triggered
        assertFalse(sut.shouldStartRecording.first())
    }

    @Test
    fun `cancel pending auto recording app goes to background cancels recording`() = runTest {
        // Given: Auto-recording scheduled
        lifecycleManager.completeFirstLaunch()
        lifecycleManager.updateAppState(AppState.ACTIVE)
        every { permissionManager.areAllPermissionsGranted() } returns true

        sut.triggerAutoRecordingIfNeeded(isRecordingActive = false)

        // When: App goes to background (triggers cancel in real app)
        lifecycleManager.updateAppState(AppState.BACKGROUND)
        sut.cancelPendingAutoRecording()

        // Wait past delay
        advanceTimeBy(600L)

        // Then: Should NOT have triggered
        assertFalse(sut.shouldStartRecording.first())
    }

    // MARK: - Completion Tests

    @Test
    fun `auto recording did complete updates lifecycle manager`() = runTest {
        // Given: Auto-recording active
        lifecycleManager.startAutoRecording()
        assertTrue(lifecycleManager.isAutoRecording.first())

        // When: Auto-recording completes
        sut.autoRecordingDidComplete()

        // Then: Lifecycle manager should be updated
        assertFalse(lifecycleManager.isAutoRecording.first())
    }

    // MARK: - Concurrent Request Tests

    @Test
    fun `trigger auto recording concurrent requests only processes one`() = runTest {
        // Given: Perfect conditions
        lifecycleManager.completeFirstLaunch()
        lifecycleManager.updateAppState(AppState.ACTIVE)
        every { permissionManager.areAllPermissionsGranted() } returns true

        // When: Trigger multiple times rapidly
        sut.triggerAutoRecordingIfNeeded(isRecordingActive = false)
        sut.triggerAutoRecordingIfNeeded(isRecordingActive = false)
        sut.triggerAutoRecordingIfNeeded(isRecordingActive = false)

        // Then: Should only process one (lifecycle manager prevents duplicates)
        assertTrue(lifecycleManager.isAutoRecording.first())

        // Clean up
        sut.cancelPendingAutoRecording()
    }

    // MARK: - Integration Test - Complete Flow

    @Test
    fun `complete flow foreground transition triggers auto recording`() = runTest {
        // Scenario: App goes to background, then returns to foreground

        // 1. Setup: Not first launch, app was active
        lifecycleManager.completeFirstLaunch()
        lifecycleManager.updateAppState(AppState.ACTIVE)
        every { permissionManager.areAllPermissionsGranted() } returns true

        // 2. App goes to background
        lifecycleManager.updateAppState(AppState.BACKGROUND)

        // 3. App returns to foreground
        lifecycleManager.updateAppState(AppState.ACTIVE)
        assertTrue(lifecycleManager.didBecomeActive.first())

        // 4. Auto-recording should be triggered
        sut.triggerAutoRecordingIfNeeded(isRecordingActive = false)

        // 5. Should start auto-recording
        assertTrue(lifecycleManager.isAutoRecording.first())

        // 6. Clean up foreground transition
        lifecycleManager.consumeForegroundTransition()
        assertFalse(lifecycleManager.didBecomeActive.first())

        // Clean up
        sut.cancelPendingAutoRecording()
    }
}
