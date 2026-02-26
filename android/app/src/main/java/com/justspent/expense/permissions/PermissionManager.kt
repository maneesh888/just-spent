package com.justspent.expense.permissions

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Centralized Permission Manager
 *
 * Mirrors iOS permission management from ContentView.swift:735-820
 * Features:
 * - Permission status monitoring
 * - Proactive permission flow
 * - Smart UI state updates
 */
@Singleton
class PermissionManager @Inject constructor(
    @ApplicationContext private val context: Context
) {

    companion object {
        const val AUDIO_PERMISSION = Manifest.permission.RECORD_AUDIO
    }

    // Permission states
    private val _audioPermissionState = MutableStateFlow<PermissionState>(PermissionState.Unknown)
    val audioPermissionState: StateFlow<PermissionState> = _audioPermissionState.asStateFlow()

    private val _allPermissionsGranted = MutableStateFlow(false)
    val allPermissionsGranted: StateFlow<Boolean> = _allPermissionsGranted.asStateFlow()

    /**
     * Check current permission statuses
     */
    fun checkPermissions() {
        val audioGranted = checkAudioPermission()

        _audioPermissionState.value = if (audioGranted) {
            PermissionState.Granted
        } else {
            PermissionState.Denied
        }

        _allPermissionsGranted.value = audioGranted
    }

    /**
     * Check audio recording permission
     */
    fun checkAudioPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            AUDIO_PERMISSION
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Update permission state (call from Activity after permission result)
     */
    fun updatePermissionState(permission: String, granted: Boolean) {
        when (permission) {
            AUDIO_PERMISSION -> {
                _audioPermissionState.value = if (granted) {
                    PermissionState.Granted
                } else {
                    PermissionState.Denied
                }
            }
        }

        // Update overall state
        _allPermissionsGranted.value = checkAudioPermission()
    }

    /**
     * Get required permissions list
     */
    fun getRequiredPermissions(): Array<String> {
        return arrayOf(AUDIO_PERMISSION)
    }

    /**
     * Check if all permissions are granted
     */
    fun areAllPermissionsGranted(): Boolean {
        return checkAudioPermission()
    }
}

/**
 * Permission state sealed class
 */
sealed class PermissionState {
    object Unknown : PermissionState()
    object Granted : PermissionState()
    object Denied : PermissionState()
    object PermanentlyDenied : PermissionState()
}
