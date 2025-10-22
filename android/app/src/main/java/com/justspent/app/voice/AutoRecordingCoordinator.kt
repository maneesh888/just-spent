package com.justspent.app.voice

import com.justspent.app.lifecycle.AppLifecycleManager
import com.justspent.app.lifecycle.AppState
import com.justspent.app.permissions.PermissionManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Auto-Recording Coordinator
 *
 * Orchestrates automatic voice recording when app opens or returns to foreground.
 * Works in conjunction with AppLifecycleManager to ensure proper conditions.
 * Mirrors iOS implementation from AutoRecordingCoordinator.swift.
 *
 * Responsibilities:
 * - Verify permissions before auto-recording
 * - Delay recording to allow UI to settle (500ms)
 * - Prevent duplicate recording sessions
 * - Trigger voice recording through StateFlow
 *
 * Architecture Pattern: Coordinator Pattern
 * - Coordinates between lifecycle, permissions, and recording systems
 * - Single Responsibility: Only handles auto-recording orchestration
 * - Dependency Injection: Receives dependencies through Hilt
 */
@Singleton
class AutoRecordingCoordinator @Inject constructor(
    private val lifecycleManager: AppLifecycleManager,
    private val permissionManager: PermissionManager
) {

    companion object {
        private const val TAG = "AutoRecordingCoordinator"
        private const val AUTO_RECORDING_DELAY_MS = 0L // Immediate start for better UX
    }

    // Coroutine scope for auto-recording tasks
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // Request to start recording (observed by Activity/UI)
    private val _shouldStartRecording = MutableStateFlow(false)
    val shouldStartRecording: StateFlow<Boolean> = _shouldStartRecording.asStateFlow()

    // Private state
    private var autoRecordingJob: Job? = null
    private var isProcessingAutoRecord = false

    init {
        android.util.Log.d(TAG, "🎤 AutoRecordingCoordinator initialized")
    }

    /**
     * Attempt to trigger auto-recording
     * Called when app becomes active or returns to foreground
     *
     * @param isRecordingActive Current recording state from UI
     */
    suspend fun triggerAutoRecordingIfNeeded(isRecordingActive: Boolean) {
        // Guard against concurrent auto-recording attempts
        if (isProcessingAutoRecord) {
            android.util.Log.d(TAG, "⏸️ Auto-recording already processing, skipping")
            return
        }

        // Check lifecycle conditions
        if (!lifecycleManager.shouldTriggerAutoRecording()) {
            // shouldTriggerAutoRecording() logs reasons internally
            return
        }

        // Check if already recording (manual or previous auto)
        if (isRecordingActive) {
            android.util.Log.d(TAG, "⏸️ Auto-recording skipped: already recording")
            return
        }

        // Check recording state from VoiceRecordingManager
        // Note: This is checked in UI layer to avoid circular dependencies

        // Verify all permissions granted
        if (!permissionManager.areAllPermissionsGranted()) {
            android.util.Log.d(TAG, "⏸️ Auto-recording skipped: permissions not granted")
            return
        }

        // All conditions met - trigger auto-recording with delay
        startAutoRecordingWithDelay()
    }

    /**
     * Cancel any pending auto-recording
     * Call this if user manually triggers recording or app goes to background
     */
    fun cancelPendingAutoRecording() {
        autoRecordingJob?.cancel()
        autoRecordingJob = null
        isProcessingAutoRecord = false

        android.util.Log.d(TAG, "🚫 Pending auto-recording cancelled")
    }

    /**
     * Notify coordinator that auto-recording has completed
     * Updates lifecycle manager state
     */
    fun autoRecordingDidComplete() {
        lifecycleManager.stopAutoRecording()
        isProcessingAutoRecord = false

        android.util.Log.d(TAG, "✅ Auto-recording completed")
    }

    /**
     * Start auto-recording with delay
     * Private method that handles the actual triggering
     */
    private fun startAutoRecordingWithDelay() {
        // Cancel any existing job
        autoRecordingJob?.cancel()

        isProcessingAutoRecord = true
        lifecycleManager.startAutoRecording()

        android.util.Log.d(TAG, "⏳ Auto-recording scheduled (delay: ${AUTO_RECORDING_DELAY_MS}ms)")

        autoRecordingJob = scope.launch {
            try {
                // Wait for UI to settle
                delay(AUTO_RECORDING_DELAY_MS)

                // Check if still valid (not cancelled, app still active)
                val appState = lifecycleManager.appState.first()
                if (appState != AppState.ACTIVE) {
                    android.util.Log.d(TAG, "⏸️ Auto-recording cancelled: app not active")
                    isProcessingAutoRecord = false
                    lifecycleManager.stopAutoRecording()
                    return@launch
                }

                // Trigger recording via StateFlow
                android.util.Log.d(TAG, "🎙️ Triggering auto-recording now")

                _shouldStartRecording.value = true

                // Reset flag after brief delay to allow observation
                delay(100L) // 100ms
                _shouldStartRecording.value = false

                // Note: autoRecordingDidComplete() will be called when recording finishes

            } catch (e: Exception) {
                // Job was cancelled or error occurred
                android.util.Log.d(TAG, "⏸️ Auto-recording task cancelled or failed: ${e.message}")
                isProcessingAutoRecord = false
                lifecycleManager.stopAutoRecording()
            }
        }
    }

    /**
     * Manual trigger for testing
     */
    fun forceAutoRecordingForTesting() {
        scope.launch {
            _shouldStartRecording.value = true
            delay(100L)
            _shouldStartRecording.value = false
        }
    }

    /**
     * Clean up resources
     */
    fun cleanup() {
        autoRecordingJob?.cancel()
        autoRecordingJob = null
        isProcessingAutoRecord = false
        android.util.Log.d(TAG, "🧹 AutoRecordingCoordinator cleaned up")
    }
}
