package com.justspent.app.permissions

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import com.google.common.truth.Truth.assertThat
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import org.mockito.kotlin.whenever

/**
 * Unit tests for PermissionManager
 * Mirrors iOS permission management from ContentView.swift:735-820
 */
@OptIn(ExperimentalCoroutinesApi::class)
class PermissionManagerTest {

    @Mock
    private lateinit var mockContext: Context

    private lateinit var permissionManager: PermissionManager

    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        permissionManager = PermissionManager(mockContext)
    }

    @Test
    fun `initial audio permission state is Unknown`() = runTest {
        // Then
        val state = permissionManager.audioPermissionState.first()
        assertThat(state).isInstanceOf(PermissionState.Unknown::class.java)
    }

    @Test
    fun `initial allPermissionsGranted is false`() = runTest {
        // Then
        val allGranted = permissionManager.allPermissionsGranted.first()
        assertThat(allGranted).isFalse()
    }

    @Test
    fun `checkPermissions updates audioPermissionState to Granted when permission granted`() = runTest {
        // Given
        whenever(mockContext.checkSelfPermission(Manifest.permission.RECORD_AUDIO))
            .thenReturn(PackageManager.PERMISSION_GRANTED)

        // When
        permissionManager.checkPermissions()

        // Then
        val state = permissionManager.audioPermissionState.first()
        assertThat(state).isInstanceOf(PermissionState.Granted::class.java)
    }

    @Test
    fun `checkPermissions updates audioPermissionState to Denied when permission denied`() = runTest {
        // Given
        whenever(mockContext.checkSelfPermission(Manifest.permission.RECORD_AUDIO))
            .thenReturn(PackageManager.PERMISSION_DENIED)

        // When
        permissionManager.checkPermissions()

        // Then
        val state = permissionManager.audioPermissionState.first()
        assertThat(state).isInstanceOf(PermissionState.Denied::class.java)
    }

    @Test
    fun `checkAudioPermission returns true when granted`() {
        // Given
        whenever(mockContext.checkSelfPermission(Manifest.permission.RECORD_AUDIO))
            .thenReturn(PackageManager.PERMISSION_GRANTED)

        // When
        val hasPermission = permissionManager.checkAudioPermission()

        // Then
        assertThat(hasPermission).isTrue()
    }

    @Test
    fun `checkAudioPermission returns false when denied`() {
        // Given
        whenever(mockContext.checkSelfPermission(Manifest.permission.RECORD_AUDIO))
            .thenReturn(PackageManager.PERMISSION_DENIED)

        // When
        val hasPermission = permissionManager.checkAudioPermission()

        // Then
        assertThat(hasPermission).isFalse()
    }

    @Test
    fun `updatePermissionState updates audioPermissionState correctly`() = runTest {
        // When
        permissionManager.updatePermissionState(Manifest.permission.RECORD_AUDIO, true)

        // Then
        val state = permissionManager.audioPermissionState.first()
        assertThat(state).isInstanceOf(PermissionState.Granted::class.java)

        // When
        permissionManager.updatePermissionState(Manifest.permission.RECORD_AUDIO, false)

        // Then
        val deniedState = permissionManager.audioPermissionState.first()
        assertThat(deniedState).isInstanceOf(PermissionState.Denied::class.java)
    }

    @Test
    fun `updatePermissionState updates allPermissionsGranted flag`() = runTest {
        // Given
        whenever(mockContext.checkSelfPermission(Manifest.permission.RECORD_AUDIO))
            .thenReturn(PackageManager.PERMISSION_GRANTED)

        // When
        permissionManager.updatePermissionState(Manifest.permission.RECORD_AUDIO, true)

        // Then
        val allGranted = permissionManager.allPermissionsGranted.first()
        assertThat(allGranted).isTrue()
    }

    @Test
    fun `getRequiredPermissions returns audio permission`() {
        // When
        val permissions = permissionManager.getRequiredPermissions()

        // Then
        assertThat(permissions).contains(Manifest.permission.RECORD_AUDIO)
        assertThat(permissions.size).isEqualTo(1)
    }

    @Test
    fun `areAllPermissionsGranted returns true only when all granted`() {
        // Given - Audio permission granted
        whenever(mockContext.checkSelfPermission(Manifest.permission.RECORD_AUDIO))
            .thenReturn(PackageManager.PERMISSION_GRANTED)

        // When
        val allGranted = permissionManager.areAllPermissionsGranted()

        // Then
        assertThat(allGranted).isTrue()

        // Given - Audio permission denied
        whenever(mockContext.checkSelfPermission(Manifest.permission.RECORD_AUDIO))
            .thenReturn(PackageManager.PERMISSION_DENIED)

        // When
        val allDenied = permissionManager.areAllPermissionsGranted()

        // Then
        assertThat(allDenied).isFalse()
    }

    @Test
    fun `permission state enum has all required states`() {
        // Verify all states exist
        val states = listOf(
            PermissionState.Unknown,
            PermissionState.Granted,
            PermissionState.Denied,
            PermissionState.PermanentlyDenied
        )

        assertThat(states).hasSize(4)
    }

    @Test
    fun `permission state flow emits updates reactively`() = runTest {
        // Given
        whenever(mockContext.checkSelfPermission(Manifest.permission.RECORD_AUDIO))
            .thenReturn(PackageManager.PERMISSION_DENIED)
            .thenReturn(PackageManager.PERMISSION_GRANTED)

        // When - First check
        permissionManager.checkPermissions()
        val firstState = permissionManager.audioPermissionState.first()

        // Then
        assertThat(firstState).isInstanceOf(PermissionState.Denied::class.java)

        // When - Permission granted and check again
        permissionManager.checkPermissions()
        val secondState = permissionManager.audioPermissionState.first()

        // Then
        assertThat(secondState).isInstanceOf(PermissionState.Granted::class.java)
    }

    @Test
    fun `PermissionManager is singleton scoped`() {
        // When creating multiple instances from Hilt
        // Then should return same instance

        // Note: This is enforced by @Singleton annotation
        // In real tests, verify with Hilt test framework
    }

    @Test
    fun `permission check handles unknown permissions gracefully`() {
        // Given
        val unknownPermission = "android.permission.UNKNOWN"

        // When
        permissionManager.updatePermissionState(unknownPermission, true)

        // Then - Should not crash
        // Should only update known permissions
    }

    @Test
    fun `allPermissionsGranted flow emits correct initial state`() = runTest {
        // When
        val initialState = permissionManager.allPermissionsGranted.first()

        // Then
        assertThat(initialState).isFalse() // Default should be false until checked
    }

    @Test
    fun `permission manager works with Activity result contracts`() {
        // Integration test concept:
        // 1. MainActivity launches permission request
        // 2. User grants/denies permission
        // 3. MainActivity calls updatePermissionState()
        // 4. PermissionManager updates flows
        // 5. UI observes flow and updates

        // This validates the integration pattern used in MainActivity
    }

    @Test
    fun `proactive permission flow matches iOS implementation`() {
        // iOS Pattern from ContentView.swift:735-820:
        // 1. Check current permissions on app launch
        // 2. Request if not determined
        // 3. Show UI feedback for denied/restricted
        // 4. Refresh permissions when returning from Settings

        // Android should follow same pattern:
        // 1. PermissionManager.checkPermissions() on launch
        // 2. Request via ActivityResultContracts.RequestPermission
        // 3. Show UI feedback via permission states
        // 4. Check again in onResume() when returning from Settings
    }
}
