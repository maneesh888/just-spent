package com.justspent.app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import com.justspent.app.lifecycle.AppLifecycleManager
import com.justspent.app.permissions.PermissionManager
import com.justspent.app.ui.expenses.ExpenseListWithVoiceScreen
import com.justspent.app.ui.theme.JustSpentTheme
import com.justspent.app.voice.AutoRecordingCoordinator
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject
    lateinit var permissionManager: PermissionManager

    @Inject
    lateinit var lifecycleManager: AppLifecycleManager

    @Inject
    lateinit var autoRecordingCoordinator: AutoRecordingCoordinator

    private var hasTriggeredInitialAutoRecording = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Register AppLifecycleManager as lifecycle observer
        // This must happen after Hilt injection (which happens in super.onCreate())
        androidx.lifecycle.ProcessLifecycleOwner.get().lifecycle.addObserver(lifecycleManager)
        android.util.Log.d("MainActivity", "🚀 Lifecycle observer registered")

        // Check permissions on launch
        permissionManager.checkPermissions()

        setContent {
            var hasAudioPermission by remember {
                mutableStateOf(
                    ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.RECORD_AUDIO
                    ) == PackageManager.PERMISSION_GRANTED
                )
            }

            val permissionLauncher = rememberLauncherForActivityResult(
                contract = ActivityResultContracts.RequestPermission()
            ) { isGranted ->
                hasAudioPermission = isGranted
                permissionManager.updatePermissionState(
                    Manifest.permission.RECORD_AUDIO,
                    isGranted
                )

                // Mark first launch as complete after permission is granted
                if (isGranted && lifecycleManager.isFirstLaunch.value) {
                    lifecycleManager.completeFirstLaunch()
                    android.util.Log.d("MainActivity", "✅ First launch completed after permission grant")
                }
            }

            JustSpentTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    ExpenseListWithVoiceScreen(
                        hasAudioPermission = hasAudioPermission,
                        onRequestPermission = {
                            permissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                        },
                        lifecycleManager = lifecycleManager,
                        autoRecordingCoordinator = autoRecordingCoordinator
                    )
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()

        // Trigger auto-recording check when activity resumes
        // Delay slightly to allow UI to settle and permission states to update
        lifecycleScope.launch {
            kotlinx.coroutines.delay(300L) // 300ms delay

            // Only trigger after first onCreate to avoid double-triggering
            if (hasTriggeredInitialAutoRecording) {
                // This is a true resume (from background or another activity)
                android.util.Log.d("MainActivity", "📱 Activity resumed - checking auto-recording")
                // Note: The actual trigger happens in ExpenseListWithVoiceScreen
                // when it observes lifecycleManager.didBecomeActive
            } else {
                // First time after onCreate - mark as triggered
                hasTriggeredInitialAutoRecording = true
            }
        }
    }

    override fun onPause() {
        super.onPause()

        // Cancel any pending auto-recording when activity pauses
        autoRecordingCoordinator.cancelPendingAutoRecording()
    }
}