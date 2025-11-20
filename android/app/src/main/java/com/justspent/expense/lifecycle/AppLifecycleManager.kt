package com.justspent.expense.lifecycle

import android.content.Context
import android.content.SharedPreferences
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * App Lifecycle Manager
 *
 * Centralized management of app lifecycle states and first-launch detection.
 * Mirrors iOS implementation from AppLifecycleManager.swift.
 *
 * Responsibilities:
 * - Track first launch vs subsequent launches
 * - Monitor app foreground/background state
 * - Prevent concurrent recording sessions
 * - Provide state to AutoRecordingCoordinator
 *
 * Architecture Pattern: SOLID principles
 * - Single Responsibility: Only manages lifecycle state
 * - Open/Closed: Extensible through StateFlow observers
 * - Dependency Inversion: Depends on Android interfaces
 */
@Singleton
class AppLifecycleManager @Inject constructor(
    @ApplicationContext private val context: Context
) : DefaultLifecycleObserver {

    companion object {
        private const val PREFS_NAME = "app_lifecycle_prefs"
        private const val KEY_FIRST_LAUNCH_COMPLETE = "first_launch_complete"
        private const val KEY_LAST_APP_STATE = "last_app_state"
        private const val TAG = "AppLifecycleManager"

        /** Threshold for considering app "been away for a while" (30 minutes in milliseconds) */
        const val BACKGROUND_THRESHOLD_MS = 1800000L // 30 minutes
    }

    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /** Timestamp when app went to background (null if never backgrounded or currently active) */
    private var lastBackgroundTime: Long? = null

    // Public state flows
    private val _isFirstLaunch = MutableStateFlow(!prefs.getBoolean(KEY_FIRST_LAUNCH_COMPLETE, false))
    val isFirstLaunch: StateFlow<Boolean> = _isFirstLaunch.asStateFlow()

    private val _appState = MutableStateFlow(AppState.INACTIVE)
    val appState: StateFlow<AppState> = _appState.asStateFlow()

    private val _didBecomeActive = MutableStateFlow(false)
    val didBecomeActive: StateFlow<Boolean> = _didBecomeActive.asStateFlow()

    private val _isAutoRecording = MutableStateFlow(false)
    val isAutoRecording: StateFlow<Boolean> = _isAutoRecording.asStateFlow()

    init {
        android.util.Log.d(TAG, "AppLifecycleManager initialized - First Launch: ${_isFirstLaunch.value}")
    }

    /**
     * Mark first launch as complete
     * Call this after initial permissions are granted or user completes onboarding
     */
    fun completeFirstLaunch() {
        if (!_isFirstLaunch.value) {
            android.util.Log.w(TAG, "completeFirstLaunch() called but not first launch")
            return
        }

        prefs.edit().putBoolean(KEY_FIRST_LAUNCH_COMPLETE, true).apply()
        _isFirstLaunch.value = false

        android.util.Log.d(TAG, "✅ First launch marked as complete")
    }

    /**
     * Update app state when lifecycle changes
     * Should be called from Activity/Application lifecycle callbacks
     */
    fun updateAppState(newState: AppState) {
        val previousState = _appState.value
        _appState.value = newState

        // Track background time
        if (newState == AppState.BACKGROUND) {
            lastBackgroundTime = System.currentTimeMillis()
            android.util.Log.d(TAG, "📱 App went to background - timestamp recorded")
        }

        // Detect foreground transition
        if (previousState.isBackground() && newState == AppState.ACTIVE) {
            _didBecomeActive.value = true

            lastBackgroundTime?.let { backgroundTime ->
                val timeInBackground = System.currentTimeMillis() - backgroundTime
                android.util.Log.d(TAG, "📱 App became active (from background) - was backgrounded for ${timeInBackground / 1000}s")
            } ?: run {
                android.util.Log.d(TAG, "📱 App became active (from background)")
            }
        }

        // Save state for crash recovery
        prefs.edit().putString(KEY_LAST_APP_STATE, newState.name).apply()

        android.util.Log.d(TAG, "🔄 App state: $previousState → $newState")
    }

    /**
     * Reset the "did become active" flag after it's been consumed
     * Call this after handling the foreground transition
     */
    fun consumeForegroundTransition() {
        _didBecomeActive.value = false
    }

    /**
     * Indicate that auto-recording has started
     * Prevents duplicate auto-recording sessions
     */
    fun startAutoRecording() {
        if (_isAutoRecording.value) {
            android.util.Log.w(TAG, "⚠️ Auto-recording already active, ignoring start request")
            return
        }

        _isAutoRecording.value = true
        android.util.Log.d(TAG, "🎙️ Auto-recording session started")
    }

    /**
     * Indicate that auto-recording has stopped
     */
    fun stopAutoRecording() {
        if (!_isAutoRecording.value) {
            android.util.Log.w(TAG, "⚠️ Auto-recording not active, ignoring stop request")
            return
        }

        _isAutoRecording.value = false
        android.util.Log.d(TAG, "🛑 Auto-recording session stopped")
    }

    /**
     * Check if auto-recording should be triggered
     * Returns true only if:
     * 1. Not first launch
     * 2. App is active
     * 3. No auto-recording session active
     * 4. Either never backgrounded OR been in background for ≥30 minutes
     */
    fun shouldTriggerAutoRecording(): Boolean {
        // Basic checks
        if (_isFirstLaunch.value) {
            android.util.Log.d(TAG, "⏸️ Auto-recording skipped: first launch")
            return false
        }

        if (_appState.value != AppState.ACTIVE) {
            android.util.Log.d(TAG, "⏸️ Auto-recording skipped: app not active (${_appState.value})")
            return false
        }

        if (_isAutoRecording.value) {
            android.util.Log.d(TAG, "⏸️ Auto-recording skipped: already recording")
            return false
        }

        // Check background time threshold
        lastBackgroundTime?.let { backgroundTime ->
            val timeInBackground = System.currentTimeMillis() - backgroundTime

            if (timeInBackground < BACKGROUND_THRESHOLD_MS) {
                val remaining = (BACKGROUND_THRESHOLD_MS - timeInBackground) / 1000
                android.util.Log.d(TAG, "⏸️ Auto-recording skipped: quick background switch (${timeInBackground / 1000}s < 30min threshold, ${remaining}s remaining)")
                // Clear the timestamp after checking since we're not auto-recording
                lastBackgroundTime = null
                return false
            } else {
                android.util.Log.d(TAG, "✅ Background threshold met (${timeInBackground / 1000}s ≥ 30min) - will auto-record")
                // Clear timestamp - we're proceeding with auto-recording
                lastBackgroundTime = null
                return true
            }
        } ?: run {
            // Never backgrounded (app launch) - should auto-record
            android.util.Log.d(TAG, "✅ App launch (never backgrounded) - will auto-record")
            return true
        }
    }

    // DefaultLifecycleObserver implementation
    override fun onStart(owner: LifecycleOwner) {
        updateAppState(AppState.ACTIVE)
    }

    override fun onStop(owner: LifecycleOwner) {
        updateAppState(AppState.BACKGROUND)
    }

    override fun onPause(owner: LifecycleOwner) {
        updateAppState(AppState.INACTIVE)
    }

    override fun onResume(owner: LifecycleOwner) {
        updateAppState(AppState.ACTIVE)
    }

    /**
     * Reset first launch flag (for testing only)
     */
    fun resetFirstLaunchForTesting() {
        prefs.edit().remove(KEY_FIRST_LAUNCH_COMPLETE).apply()
        _isFirstLaunch.value = true
        android.util.Log.d(TAG, "🔄 First launch flag reset (TESTING)")
    }
}

/**
 * App State Enum
 * Mirrors iOS AppState
 */
enum class AppState {
    ACTIVE,
    INACTIVE,
    BACKGROUND;

    fun isBackground(): Boolean = this == BACKGROUND || this == INACTIVE
}
