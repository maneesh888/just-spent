package com.justspent.expense.ui.voice

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.justspent.expense.ui.theme.JustSpentTheme
import dagger.hilt.android.AndroidEntryPoint
import java.net.URLDecoder
import java.util.*

/**
 * Activity that handles Google Assistant deep links for voice expense logging
 * URL Format: https://justspent.app/expense?amount=50&category=grocery&merchant=store&note=weekly
 */
@AndroidEntryPoint
class VoiceDeepLinkActivity : ComponentActivity() {
    
    private val viewModel: VoiceExpenseViewModel by viewModels()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Parse the incoming intent
        val deepLinkData = parseDeepLinkIntent(intent)
        
        setContent {
            JustSpentTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    VoiceDeepLinkScreen(
                        deepLinkData = deepLinkData,
                        viewModel = viewModel,
                        onFinish = { finish() }
                    )
                }
            }
        }
        
        // Process the voice command if we have data
        deepLinkData?.let { data ->
            when {
                data.rawCommand != null -> {
                    viewModel.processRawVoiceCommand(data.rawCommand)
                }
                data.hasStructuredData() -> {
                    viewModel.processVoiceCommand(
                        amount = data.amount,
                        category = data.category,
                        merchant = data.merchant,
                        note = data.note
                    )
                }
            }
        }
    }
    
    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        intent?.let { 
            val deepLinkData = parseDeepLinkIntent(it)
            deepLinkData?.let { data ->
                when {
                    data.rawCommand != null -> {
                        viewModel.processRawVoiceCommand(data.rawCommand)
                    }
                    data.hasStructuredData() -> {
                        viewModel.processVoiceCommand(
                            amount = data.amount,
                            category = data.category,
                            merchant = data.merchant,
                            note = data.note
                        )
                    }
                }
            }
        }
    }
    
    private fun parseDeepLinkIntent(intent: Intent): DeepLinkData? {
        val uri = intent.data ?: return null
        
        return try {
            DeepLinkData(
                rawCommand = uri.getQueryParameter("command")?.let { 
                    URLDecoder.decode(it, "UTF-8") 
                },
                amount = uri.getQueryParameter("amount"),
                category = uri.getQueryParameter("category"),
                merchant = uri.getQueryParameter("merchant"),
                note = uri.getQueryParameter("note")
            )
        } catch (e: Exception) {
            null
        }
    }
}

data class DeepLinkData(
    val rawCommand: String? = null,
    val amount: String? = null,
    val category: String? = null,
    val merchant: String? = null,
    val note: String? = null
) {
    fun hasStructuredData(): Boolean {
        return !amount.isNullOrBlank() || !category.isNullOrBlank() || 
               !merchant.isNullOrBlank() || !note.isNullOrBlank()
    }
}

@Composable
fun VoiceDeepLinkScreen(
    deepLinkData: DeepLinkData?,
    viewModel: VoiceExpenseViewModel,
    onFinish: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    
    LaunchedEffect(uiState.isProcessed) {
        if (uiState.isProcessed) {
            // Auto-close after 2 seconds on success
            kotlinx.coroutines.delay(2000)
            onFinish()
        }
    }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
            .verticalScroll(rememberScrollState()),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        when {
            uiState.isProcessing -> {
                ProcessingContent()
            }
            
            uiState.requiresConfirmation -> {
                ConfirmationContent(
                    extractedData = uiState.extractedData,
                    confidenceScore = uiState.confidenceScore,
                    onConfirm = { viewModel.confirmExpense() },
                    onCancel = onFinish
                )
            }
            
            uiState.isProcessed -> {
                SuccessContent(
                    processedExpense = uiState.processedExpense ?: "Expense logged",
                    confidenceScore = uiState.confidenceScore
                )
            }
            
            uiState.errorMessage != null -> {
                val errorMessage = uiState.errorMessage!!
                ErrorContent(
                    error = errorMessage,
                    suggestions = uiState.suggestedPhrases,
                    onRetry = { viewModel.retry() },
                    onCancel = onFinish
                )
            }
            
            deepLinkData == null -> {
                ErrorContent(
                    error = "Invalid voice command data",
                    suggestions = viewModel.getTrainingPhrases(),
                    onRetry = { },
                    onCancel = onFinish
                )
            }
            
            else -> {
                // Waiting for processing to start
                ProcessingContent()
            }
        }
    }
}

@Composable
private fun ProcessingContent() {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        CircularProgressIndicator(
            modifier = Modifier.size(48.dp),
            color = MaterialTheme.colorScheme.primary
        )
        
        Text(
            text = "Processing your expense...",
            style = MaterialTheme.typography.headlineSmall,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurface
        )
        
        Text(
            text = "Analyzing voice command and extracting details",
            style = MaterialTheme.typography.bodyMedium,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun ConfirmationContent(
    extractedData: ExtractedVoiceData?,
    confidenceScore: Double?,
    onConfirm: () -> Unit,
    onCancel: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Icon(
            imageVector = Icons.Default.Info,
            contentDescription = "Confirmation needed",
            modifier = Modifier.size(48.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        
        Text(
            text = "Please Confirm",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSurface
        )
        
        if (extractedData != null) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "\"${extractedData.originalCommand}\"",
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    extractedData.amount?.let {
                        DetailRow("Amount", "${extractedData.currency ?: "USD"} $it")
                    }
                    
                    extractedData.category?.let {
                        DetailRow("Category", it)
                    }
                    
                    extractedData.merchant?.let {
                        DetailRow("Merchant", it)
                    }
                    
                    extractedData.notes?.let {
                        DetailRow("Notes", it)
                    }
                    
                    confidenceScore?.let {
                        val percentage = (it * 100).toInt()
                        DetailRow("Confidence", "$percentage%")
                    }
                }
            }
        }
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            OutlinedButton(
                onClick = onCancel,
                modifier = Modifier.weight(1f)
            ) {
                Text("Cancel")
            }
            
            Button(
                onClick = onConfirm,
                modifier = Modifier.weight(1f)
            ) {
                Text("Confirm")
            }
        }
    }
}

@Composable
private fun SuccessContent(
    processedExpense: String,
    confidenceScore: Double?
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Icon(
            imageVector = Icons.Default.CheckCircle,
            contentDescription = "Success",
            modifier = Modifier.size(64.dp),
            tint = Color(0xFF4CAF50)
        )
        
        Text(
            text = "Expense Logged!",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSurface
        )
        
        Text(
            text = processedExpense,
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        confidenceScore?.let {
            val percentage = (it * 100).toInt()
            Text(
                text = "Processed with $percentage% confidence",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun ErrorContent(
    error: String,
    suggestions: List<String>,
    onRetry: () -> Unit,
    onCancel: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Icon(
            imageVector = Icons.Default.Error,
            contentDescription = "Error",
            modifier = Modifier.size(48.dp),
            tint = MaterialTheme.colorScheme.error
        )
        
        Text(
            text = "Oops!",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSurface
        )
        
        Text(
            text = error,
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.error
        )
        
        if (suggestions.isNotEmpty()) {
            Text(
                text = "Try saying:",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurface
            )
            
            suggestions.forEach { suggestion ->
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Text(
                        text = "\"$suggestion\"",
                        modifier = Modifier.padding(12.dp),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            OutlinedButton(
                onClick = onCancel,
                modifier = Modifier.weight(1f)
            ) {
                Text("Close")
            }
            
            Button(
                onClick = onRetry,
                modifier = Modifier.weight(1f)
            ) {
                Text("Retry")
            }
        }
    }
}

@Composable
private fun DetailRow(
    label: String,
    value: String
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = "$label:",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}