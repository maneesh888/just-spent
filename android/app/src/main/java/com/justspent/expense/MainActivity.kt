package com.justspent.expense

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
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.justspent.expense.data.preferences.UserPreferences
import com.justspent.expense.lifecycle.AppLifecycleManager
import com.justspent.expense.permissions.PermissionManager
import com.justspent.expense.ui.MainContentScreen
import com.justspent.expense.ui.onboarding.CurrencyOnboardingScreen
import com.justspent.expense.ui.theme.JustSpentTheme
import com.justspent.expense.voice.AutoRecordingCoordinator
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

    @Inject
    lateinit var userPreferences: UserPreferences

    private var hasTriggeredInitialAutoRecording = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Register AppLifecycleManager as lifecycle observer
        // This must happen after Hilt injection (which happens in super.onCreate())
        androidx.lifecycle.ProcessLifecycleOwner.get().lifecycle.addObserver(lifecycleManager)
        android.util.Log.d("MainActivity", "🚀 Lifecycle observer registered")

        // Initialize default currency based on locale if not already set
        // This ensures app ALWAYS has a default currency (module independence)
        userPreferences.initializeDefaultCurrency()
        android.util.Log.d("MainActivity", "💱 Default currency initialized")

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

            // Collect onboarding state
            val hasCompletedOnboarding by userPreferences.hasCompletedOnboarding.collectAsStateWithLifecycle()
            var pendingCurrency by remember { mutableStateOf(userPreferences.defaultCurrency.value) }

            JustSpentTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    if (!hasCompletedOnboarding) {
                        // Show onboarding screen
                        CurrencyOnboardingScreen(
                            onCurrencySelected = { currency ->
                                // Track selected currency
                                pendingCurrency = currency
                                userPreferences.setDefaultCurrency(currency)
                            },
                            onComplete = {
                                // Complete onboarding with selected currency
                                userPreferences.completeOnboarding(pendingCurrency)
                                android.util.Log.d("MainActivity", "✅ Onboarding completed with ${pendingCurrency.code}")
                            }
                        )
                    } else {
                        // Show main app
                        MainContentScreen(
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