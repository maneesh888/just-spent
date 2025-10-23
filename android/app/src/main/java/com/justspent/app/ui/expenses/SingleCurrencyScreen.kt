package com.justspent.app.ui.expenses

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.justspent.app.data.model.Currency
import com.justspent.app.utils.CurrencyFormatter
import java.math.BigDecimal

/**
 * Simple expense list view for when only one currency exists
 * No tabs needed - just shows the single currency list
 * Design matches ExpenseListWithVoiceScreen with header card and gradient
 *
 * @param currency The single currency to display
 * @param isRecording Whether voice recording is active
 * @param hasDetectedSpeech Whether speech has been detected during recording
 * @param hasAudioPermission Whether microphone permission is granted
 * @param onStartRecording Callback to start voice recording
 * @param onStopRecording Callback to stop voice recording
 * @param onPermissionRequest Callback to request microphone permission
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SingleCurrencyScreen(
    currency: Currency,
    isRecording: Boolean = false,
    hasDetectedSpeech: Boolean = false,
    hasAudioPermission: Boolean = false,
    onStartRecording: () -> Unit = {},
    onStopRecording: () -> Unit = {},
    onPermissionRequest: () -> Unit = {},
    viewModel: ExpenseListViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val expenses = uiState.expenses

    // Calculate total for this specific currency
    val currencyTotal = remember(expenses, currency) {
        expenses
            .filter { it.currency == currency.code }
            .fold(BigDecimal.ZERO) { acc, expense -> acc.add(expense.amount) }
    }

    val formattedTotal = remember(currencyTotal, currency) {
        CurrencyFormatter.format(
            amount = currencyTotal,
            currency = currency,
            showSymbol = true,
            showCode = false
        )
    }

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

    Scaffold(
        floatingActionButton = {
            // Custom FAB matching ExpenseListWithVoiceScreen
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
                            onPermissionRequest()
                        } else if (isRecording) {
                            onStopRecording()
                        } else {
                            onStartRecording()
                        }
                    },
                    containerColor = if (isRecording)
                        MaterialTheme.colorScheme.error
                    else
                        MaterialTheme.colorScheme.primary,
                    modifier = Modifier
                        .size(if (isRecording) 66.dp else 60.dp)
                        .scale(if (isRecording) scale else 1f)
                ) {
                    Icon(
                        imageVector = if (isRecording) Icons.Default.Stop else Icons.Default.Mic,
                        contentDescription = if (isRecording) "Stop Recording" else "Start Recording",
                        modifier = Modifier.size(24.dp),
                        tint = MaterialTheme.colorScheme.onPrimary
                    )
                }
            }
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
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
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
                        modifier = Modifier
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

            // Expense List
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp)
            ) {
                CurrencyExpenseListScreen(currency = currency)
            }
        }
    }
}
