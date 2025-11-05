package com.justspent.app.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.justspent.app.data.model.Currency
import com.justspent.app.lifecycle.AppLifecycleManager
import com.justspent.app.lifecycle.AppState
import com.justspent.app.ui.expenses.*
import com.justspent.app.ui.preferences.UserPreferencesViewModel
import com.justspent.app.ui.voice.ExtractedVoiceData
import com.justspent.app.ui.voice.VoiceExpenseViewModel
import com.justspent.app.voice.AutoRecordingCoordinator
import com.justspent.app.voice.RecordingState

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
    viewModel: ExpenseListViewModel = hiltViewModel(),
    voiceViewModel: VoiceExpenseViewModel = hiltViewModel(),
    preferencesViewModel: UserPreferencesViewModel = hiltViewModel()
) {
    // Collect expenses
    val uiState by viewModel.uiState.collectAsState()
    val expenses = uiState.expenses

    // Voice state
    val voiceUiState by voiceViewModel.uiState.collectAsStateWithLifecycle()
    val voiceRecordingManager = voiceViewModel.voiceRecordingManager
    val recordingState by voiceRecordingManager.recordingState.collectAsStateWithLifecycle()
    val isRecording = recordingState is RecordingState.Recording
    val hasDetectedSpeech = (recordingState as? RecordingState.Recording)?.hasDetectedSpeech ?: false

    // Dialog state
    var showVoiceResultDialog by remember { mutableStateOf(false) }
    var voiceResult by remember { mutableStateOf("") }
    var lastProcessedExpense by remember { mutableStateOf<String?>(null) }

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

    // Get default currency from user preferences (not device locale)
    val defaultCurrency by preferencesViewModel.defaultCurrency.collectAsStateWithLifecycle()

    // Handle voice result
    LaunchedEffect(voiceUiState.isProcessed, voiceUiState.processedExpense) {
        if (voiceUiState.isProcessed &&
            voiceUiState.processedExpense != null &&
            voiceUiState.processedExpense != lastProcessedExpense) {
            voiceResult = voiceUiState.processedExpense!!
            lastProcessedExpense = voiceUiState.processedExpense
            showVoiceResultDialog = true
        }
    }

    // Cancel recording when app goes to background
    val appState by lifecycleManager.appState.collectAsStateWithLifecycle()
    LaunchedEffect(appState) {
        if (appState == AppState.BACKGROUND && isRecording) {
            voiceRecordingManager.stopRecording()
            voiceViewModel.resetState()
        }
    }

    // Monitor recording completion for auto-recording cleanup
    LaunchedEffect(recordingState) {
        if (recordingState is RecordingState.Idle && lifecycleManager.isAutoRecording.value) {
            autoRecordingCoordinator.autoRecordingDidComplete()
        }
    }

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
                defaultCurrency = defaultCurrency,
                isRecording = isRecording,
                hasDetectedSpeech = hasDetectedSpeech,
                hasAudioPermission = hasAudioPermission,
                onStartRecording = {
                    if (hasAudioPermission) {
                        voiceViewModel.startVoiceRecording()
                    } else {
                        onRequestPermission()
                    }
                },
                onStopRecording = {
                    voiceRecordingManager.stopRecording()
                },
                onPermissionRequest = onRequestPermission
            )
        }

        else -> {
            // Single Currency → Simple List View
            val currency = activeCurrencies.firstOrNull() ?: Currency.AED
            SingleCurrencyScreen(
                currency = currency,
                isRecording = isRecording,
                hasDetectedSpeech = hasDetectedSpeech,
                hasAudioPermission = hasAudioPermission,
                onStartRecording = {
                    if (hasAudioPermission) {
                        voiceViewModel.startVoiceRecording()
                    } else {
                        onRequestPermission()
                    }
                },
                onStopRecording = {
                    voiceRecordingManager.stopRecording()
                },
                onPermissionRequest = onRequestPermission
            )
        }
    }

    // Voice Result Dialog
    if (showVoiceResultDialog) {
        AlertDialog(
            onDismissRequest = {
                showVoiceResultDialog = false
                voiceViewModel.resetState()
            },
            title = { Text("Voice Expense Added") },
            text = { Text(voiceResult) },
            confirmButton = {
                TextButton(
                    onClick = {
                        showVoiceResultDialog = false
                        voiceViewModel.resetState()
                    }
                ) {
                    Text("OK")
                }
            }
        )
    }

    // Voice Confirmation Dialog
    if (voiceUiState.requiresConfirmation && voiceUiState.extractedData != null) {
        VoiceConfirmationDialog(
            extractedData = voiceUiState.extractedData!!,
            confidenceScore = voiceUiState.confidenceScore,
            onConfirm = { voiceViewModel.confirmExpense() },
            onDismiss = { voiceViewModel.resetState() }
        )
    }

    // Voice Error Dialog
    voiceUiState.errorMessage?.let { error ->
        AlertDialog(
            onDismissRequest = { voiceViewModel.resetState() },
            title = { Text("Voice Recognition Error") },
            text = { Text(error) },
            confirmButton = {
                TextButton(onClick = { voiceViewModel.resetState() }) {
                    Text("OK")
                }
            },
            dismissButton = {
                TextButton(onClick = { voiceViewModel.retry() }) {
                    Text("Retry")
                }
            }
        )
    }
}

@Composable
private fun VoiceConfirmationDialog(
    extractedData: ExtractedVoiceData,
    confidenceScore: Double?,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Confirm Expense") },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text("Please confirm this expense:")
                Spacer(modifier = Modifier.height(8.dp))

                // Amount
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Amount:", fontWeight = androidx.compose.ui.text.font.FontWeight.Bold)
                    Text("${extractedData.currency} ${extractedData.amount}")
                }

                // Category
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Category:", fontWeight = androidx.compose.ui.text.font.FontWeight.Bold)
                    Text(extractedData.category ?: "Other")
                }

                // Merchant (if available)
                extractedData.merchant?.let { merchant ->
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Merchant:", fontWeight = androidx.compose.ui.text.font.FontWeight.Bold)
                        Text(merchant)
                    }
                }

                // Confidence score
                confidenceScore?.let { confidence ->
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Confidence: ${(confidence * 100).toInt()}%",
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text("Confirm")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
