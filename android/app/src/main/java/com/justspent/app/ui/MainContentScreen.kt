package com.justspent.app.ui

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import com.justspent.app.data.model.Currency
import com.justspent.app.lifecycle.AppLifecycleManager
import com.justspent.app.ui.components.FloatingVoiceButton
import com.justspent.app.ui.expenses.*
import com.justspent.app.voice.AutoRecordingCoordinator

/**
 * Main content screen with conditional UI rendering based on currency count
 * - Empty state: No expenses
 * - Single currency: Simple list view
 * - Multiple currencies: Tabbed interface
 *
 * Floating voice button always visible across all states
 *
 * @param hasAudioPermission Whether microphone permission granted
 * @param onRequestPermission Callback to request microphone permission
 * @param lifecycleManager App lifecycle manager
 * @param autoRecordingCoordinator Auto-recording coordinator
 * @param viewModel Expense list view model
 */
@Composable
fun MainContentScreen(
    hasAudioPermission: Boolean,
    onRequestPermission: () -> Unit,
    lifecycleManager: AppLifecycleManager,
    autoRecordingCoordinator: AutoRecordingCoordinator,
    viewModel: ExpenseListViewModel = hiltViewModel()
) {
    // Collect expenses
    val uiState by viewModel.uiState.collectAsState()
    val expenses = uiState.expenses

    // Voice recording state (simplified - should be from voice ViewModel)
    var isRecording by remember { mutableStateOf(false) }
    var hasDetectedSpeech by remember { mutableStateOf(false) }

    // Detect active currencies from expenses
    val activeCurrencies = remember(expenses) {
        expenses
            .map { expense -> expense.currency }
            .distinct()
            .mapNotNull { currencyCode -> Currency.fromCode(currencyCode) }
            .sortedBy { currency -> currency.displayName }
    }

    // Determine if we should show tabs
    val shouldShowTabs = activeCurrencies.size > 1

    // Get default currency (from user preferences or device locale)
    val defaultCurrency = Currency.default

    Box(modifier = Modifier.fillMaxSize()) {
        // Main Content - Conditional UI Rendering
        when {
            expenses.isEmpty() -> {
                // Empty State
                ExpenseListWithVoiceScreen(
                    hasAudioPermission = hasAudioPermission,
                    onRequestPermission = onRequestPermission,
                    lifecycleManager = lifecycleManager,
                    autoRecordingCoordinator = autoRecordingCoordinator
                )
            }

            shouldShowTabs -> {
                // Multiple Currencies → Tabbed Interface
                MultiCurrencyTabbedScreen(
                    currencies = activeCurrencies,
                    defaultCurrency = defaultCurrency
                )
            }

            else -> {
                // Single Currency → Simple List View
                val currency = activeCurrencies.firstOrNull() ?: Currency.AED
                SingleCurrencyScreen(currency = currency)
            }
        }

        // Floating Voice Button (Always Visible)
        if (expenses.isNotEmpty()) {
            FloatingVoiceButton(
                isRecording = isRecording,
                hasDetectedSpeech = hasDetectedSpeech,
                hasAudioPermission = hasAudioPermission,
                onStartRecording = {
                    isRecording = true
                    hasDetectedSpeech = false
                    // TODO: Start actual voice recording
                },
                onStopRecording = {
                    isRecording = false
                    hasDetectedSpeech = false
                    // TODO: Stop actual voice recording
                },
                onPermissionRequest = onRequestPermission
            )
        }
    }
}
