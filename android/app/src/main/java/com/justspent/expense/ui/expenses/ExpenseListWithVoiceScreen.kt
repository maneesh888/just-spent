package com.justspent.expense.ui.expenses

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.MicOff
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.justspent.expense.voice.RecordingState
import com.justspent.expense.ui.voice.VoiceExpenseViewModel
import com.justspent.expense.ui.voice.ExtractedVoiceData
import com.justspent.expense.lifecycle.AppLifecycleManager
import com.justspent.expense.lifecycle.AppState
import com.justspent.expense.voice.AutoRecordingCoordinator
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExpenseListWithVoiceScreen(
    hasAudioPermission: Boolean,
    onRequestPermission: () -> Unit,
    lifecycleManager: AppLifecycleManager,
    autoRecordingCoordinator: AutoRecordingCoordinator,
    expenseViewModel: ExpenseListViewModel = hiltViewModel(),
    voiceViewModel: VoiceExpenseViewModel = hiltViewModel()
) {
    val expenseUiState by expenseViewModel.uiState.collectAsStateWithLifecycle()
    val errorMessage by expenseViewModel.errorMessage.collectAsStateWithLifecycle()

    val voiceUiState by voiceViewModel.uiState.collectAsStateWithLifecycle()

    // Auto-recording trigger from coordinator
    val shouldStartRecording by autoRecordingCoordinator.shouldStartRecording.collectAsStateWithLifecycle()
    val voiceRecordingManager = voiceViewModel.voiceRecordingManager
    val recordingState by voiceRecordingManager.recordingState.collectAsStateWithLifecycle()
    val isRecording = recordingState is RecordingState.Recording

    val scope = rememberCoroutineScope()

    var showVoiceResultDialog by remember { mutableStateOf(false) }
    var voiceResult by remember { mutableStateOf("")}
    var lastProcessedExpense by remember { mutableStateOf<String?>(null) }

    // Request permission automatically on empty state load (like iOS behavior)
    var hasRequestedPermission by remember { mutableStateOf(false) }
    LaunchedEffect(hasAudioPermission, expenseUiState.expenses.isEmpty()) {
        // Only request permission automatically if:
        // 1. We haven't requested it yet in this session
        // 2. Permission is not granted
        // 3. Expense list is empty (empty state is showing)
        if (!hasRequestedPermission && !hasAudioPermission && expenseUiState.expenses.isEmpty()) {
            hasRequestedPermission = true
            // Small delay to let UI render before showing permission dialog
            kotlinx.coroutines.delay(500)
            android.util.Log.d("ExpenseListWithVoiceScreen", "🎤 Auto-requesting microphone permission on empty state load (iOS-like behavior)")
            onRequestPermission()
        }
    }

    // Auto-recording disabled for app launch/foreground
    // (kept for future widget support)
    // val didBecomeActive by lifecycleManager.didBecomeActive.collectAsStateWithLifecycle()
    // LaunchedEffect(didBecomeActive) {
    //     if (didBecomeActive) {
    //         android.util.Log.d("ExpenseListWithVoiceScreen", "📱 App became active - checking auto-recording conditions")
    //         autoRecordingCoordinator.triggerAutoRecordingIfNeeded(isRecording)
    //         lifecycleManager.consumeForegroundTransition()
    //     }
    // }

    // Handle auto-recording trigger
    LaunchedEffect(shouldStartRecording) {
        if (shouldStartRecording && !isRecording && hasAudioPermission) {
            android.util.Log.d("ExpenseListWithVoiceScreen", "🎙️ Auto-recording triggered by coordinator")
            voiceViewModel.startVoiceRecording()
        }
    }

    // Monitor recording completion for auto-recording cleanup
    LaunchedEffect(recordingState) {
        if (recordingState is RecordingState.Idle && lifecycleManager.isAutoRecording.value) {
            android.util.Log.d("ExpenseListWithVoiceScreen", "✅ Auto-recording completed, notifying coordinator")
            autoRecordingCoordinator.autoRecordingDidComplete()
        }
    }

    // Cancel recording when app goes to background
    val appState by lifecycleManager.appState.collectAsStateWithLifecycle()
    LaunchedEffect(appState) {
        if (appState == AppState.BACKGROUND && isRecording) {
            android.util.Log.d("ExpenseListWithVoiceScreen", "🛑 App went to background while recording - cancelling without saving")
            voiceRecordingManager.stopRecording()
            voiceViewModel.resetState()
        }
    }

    // Handle voice result
    LaunchedEffect(voiceUiState.isProcessed, voiceUiState.processedExpense) {
        if (voiceUiState.isProcessed &&
            voiceUiState.processedExpense != null &&
            voiceUiState.processedExpense != lastProcessedExpense) {
            voiceResult = voiceUiState.processedExpense!!
            lastProcessedExpense = voiceUiState.processedExpense
            showVoiceResultDialog = true
            // Expenses will auto-reload via Flow
        }
    }

    // Handle error messages
    LaunchedEffect(voiceUiState.errorMessage) {
        voiceUiState.errorMessage?.let {
            // Error will be shown in the dialog
        }
    }

    Scaffold(
        floatingActionButton = {
            VoiceRecordingFAB(
                hasAudioPermission = hasAudioPermission,
                onRequestPermission = onRequestPermission,
                voiceViewModel = voiceViewModel,
                isRecording = isRecording
            )
        },
        floatingActionButtonPosition = FabPosition.End
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            Color(0xFF1976D2).copy(alpha = 0.1f),
                            Color(0xFF9C27B0).copy(alpha = 0.05f)
                        )
                    )
                )
        ) {
            // Header Card
            HeaderCard(
                hasAudioPermission = hasAudioPermission,
                formattedTotal = expenseUiState.formattedTotalSpending
            )

            // Content
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp),
                contentAlignment = Alignment.Center
            ) {
                if (expenseUiState.expenses.isEmpty()) {
                    // Empty State - properly centered for tablet
                    EmptyStateContent(
                        hasAudioPermission = hasAudioPermission,
                        onRequestPermission = onRequestPermission
                    )
                } else {
                    // Expense List
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                        contentPadding = PaddingValues(top = 8.dp, bottom = 88.dp)
                    ) {
                        items(expenseUiState.expenses) { expense ->
                            ExpenseRow(
                                expense = expense,
                                onDelete = { expenseViewModel.deleteExpense(expense) }
                            )
                        }
                    }
                }

                // Error Message
                errorMessage?.let { message ->
                    Card(
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .padding(16.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.errorContainer
                        )
                    ) {
                        Text(
                            text = message,
                            modifier = Modifier.padding(16.dp),
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }
            }
        }

        // Voice Result Dialog
        if (showVoiceResultDialog) {
            VoiceResultDialog(
                voiceResult = voiceResult,
                onDismiss = {
                    showVoiceResultDialog = false
                    voiceViewModel.resetState()
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
            VoiceErrorDialog(
                error = error,
                onDismiss = { voiceViewModel.resetState() },
                onRetry = { voiceViewModel.retry() }
            )
        }
    }
}

// MARK: - Header Card
@Composable
private fun HeaderCard(
    hasAudioPermission: Boolean,
    formattedTotal: String
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp)
            .testTag("header_card"),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Just Spent",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "Voice-enabled expense tracker",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )
                    if (!hasAudioPermission) {
                        Icon(
                            imageVector = Icons.Default.Mic,
                            contentDescription = "No permission",
                            modifier = Modifier.size(16.dp),
                            tint = MaterialTheme.colorScheme.error
                        )
                    }
                }
            }

            Card(
                colors = CardDefaults.cardColors(
                    containerColor = Color(0xFF4CAF50).copy(alpha = 0.2f)
                ),
                modifier = Modifier.clip(RoundedCornerShape(12.dp))
            ) {
                Column(
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                    horizontalAlignment = Alignment.End
                ) {
                    Text(
                        text = "Total",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )
                    Text(
                        text = formattedTotal,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
            }
        }
    }
}

// MARK: - Empty State Content
@Composable
private fun EmptyStateContent(
    hasAudioPermission: Boolean,
    onRequestPermission: () -> Unit
) {
    // Full-width column with centered, constrained content
    Column(
        modifier = Modifier
            .fillMaxWidth() // Fill parent width
            .testTag("empty_state"),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Card(
            modifier = Modifier
                .widthIn(max = 600.dp) // Max width constraint on the Card itself
                .fillMaxWidth(0.9f) // Use 90% of available width up to max
                .padding(horizontal = 24.dp), // Horizontal padding
            elevation = CardDefaults.cardElevation(defaultElevation = 6.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)
            )
        ) {
            Column(
                modifier = Modifier.padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Permission-aware icon similar to iOS
                Icon(
                    imageVector = if (hasAudioPermission) {
                        Icons.Default.Mic
                    } else {
                        Icons.Default.MicOff
                    },
                    contentDescription = if (hasAudioPermission) {
                        "Voice Input"
                    } else {
                        "Permission Needed"
                    },
                    modifier = Modifier
                        .size(60.dp)
                        .testTag("empty_state_icon"),
                    tint = if (hasAudioPermission)
                        MaterialTheme.colorScheme.primary
                    else
                        Color(0xFFFF9800) // Orange color like iOS warning
                )

                Spacer(modifier = Modifier.height(20.dp))

                Text(
                    text = "No Expenses Yet",
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onSurface,
                    modifier = Modifier.testTag("empty_state_title")
                )

                Spacer(modifier = Modifier.height(12.dp))

                Text(
                    text = if (hasAudioPermission) {
                        "Tap the microphone button below to record an expense"
                    } else {
                        "Grant microphone permission to use voice features"
                    },
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                    textAlign = TextAlign.Center,
                    modifier = Modifier.testTag("empty_state_help_text")
                )

                // Show "Grant Permission" button when permission is needed (iOS-like)
                if (!hasAudioPermission) {
                    Spacer(modifier = Modifier.height(16.dp))

                    Button(
                        onClick = onRequestPermission,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.primary
                        )
                    ) {
                        Text("Grant Permission")
                    }
                }

                if (hasAudioPermission) {
                    Spacer(modifier = Modifier.height(16.dp))

                    Text(
                        text = "Try saying:",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    Text(
                        text = "• \"I just spent 20 dollars on coffee\"\n" +
                               "• \"I spent 50 dirhams on groceries\"\n" +
                               "• \"I paid 100 AED for gas\"",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                        textAlign = TextAlign.Start
                    )
                }
            }
        }
    }
}

// MARK: - Voice Recording FAB
@Composable
private fun VoiceRecordingFAB(
    hasAudioPermission: Boolean,
    onRequestPermission: () -> Unit,
    voiceViewModel: VoiceExpenseViewModel,
    isRecording: Boolean
) {
    val voiceRecordingManager = voiceViewModel.voiceRecordingManager
    val recordingState by voiceRecordingManager.recordingState.collectAsStateWithLifecycle()

    val hasDetectedSpeech = (recordingState as? RecordingState.Recording)?.hasDetectedSpeech ?: false

    // Animation for pulsing effect
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.1f,
        animationSpec = infiniteRepeatable(
            animation = tween(500, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scale"
    )

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // Recording indicator
        if (isRecording) {
            Card(
                modifier = Modifier.padding(8.dp),
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)
                ),
                elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .scale(if (isRecording) scale else 1f)
                            .background(
                                color = if (hasDetectedSpeech) Color.Green else Color.Red,
                                shape = CircleShape
                            )
                    )
                    Text(
                        text = if (hasDetectedSpeech) "Processing..." else "Listening...",
                        style = MaterialTheme.typography.bodySmall,
                        color = if (hasDetectedSpeech)
                            MaterialTheme.colorScheme.primary
                        else
                            MaterialTheme.colorScheme.error
                    )
                }
            }
        }

        // Main FAB
        FloatingActionButton(
            onClick = {
                if (!hasAudioPermission) {
                    onRequestPermission()
                } else if (isRecording) {
                    voiceRecordingManager.stopRecording()
                } else {
                    voiceViewModel.startVoiceRecording()
                }
            },
            containerColor = if (isRecording)
                MaterialTheme.colorScheme.error
            else
                MaterialTheme.colorScheme.primary,
            modifier = Modifier
                .size(if (isRecording) 66.dp else 60.dp)
                .scale(if (isRecording) scale else 1f)
                .testTag("voice_fab")
        ) {
            Icon(
                imageVector = if (isRecording) Icons.Default.Stop else Icons.Default.Mic,
                contentDescription = if (isRecording) "Stop voice recording" else "Voice recording button",
                modifier = Modifier.size(24.dp),
                tint = MaterialTheme.colorScheme.onPrimary
            )
        }
    }
}

// MARK: - Dialogs

@Composable
private fun VoiceResultDialog(
    voiceResult: String,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Voice Expense Added") },
        text = { Text(voiceResult) },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("OK")
            }
        }
    )
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
                Text(
                    text = "Please confirm this expense:",
                    style = MaterialTheme.typography.bodyMedium
                )
                Spacer(modifier = Modifier.height(8.dp))

                // Amount
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Amount:",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "${extractedData.currency} ${extractedData.amount}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.primary
                    )
                }

                // Category
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Category:",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = extractedData.category ?: "Other",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }

                // Merchant (if available)
                extractedData.merchant?.let { merchant ->
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Merchant:",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = merchant,
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }

                // Notes (if available)
                extractedData.notes?.let { notes ->
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Notes:",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = notes,
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }

                // Confidence score
                confidenceScore?.let { confidence ->
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Confidence: ${(confidence * 100).toInt()}%",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
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

@Composable
private fun VoiceErrorDialog(
    error: String,
    onDismiss: () -> Unit,
    onRetry: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Voice Recognition Error") },
        text = {
            Column {
                Text(error)
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = "Try saying: 'I just spent 20 dollars on coffee'",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("OK")
            }
        },
        dismissButton = {
            TextButton(onClick = onRetry) {
                Text("Retry")
            }
        }
    )
}
