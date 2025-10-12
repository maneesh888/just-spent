package com.justspent.app.ui.voice

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.justspent.app.ui.theme.JustSpentTheme
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.delay

@AndroidEntryPoint
class VoiceExpenseActivity : ComponentActivity() {
    
    private val viewModel: VoiceExpenseViewModel by viewModels()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Parse deep link parameters
        parseDeepLinkIntent(intent)
        
        setContent {
            JustSpentTheme {
                VoiceExpenseScreen(
                    viewModel = viewModel,
                    onFinish = { finish() }
                )
            }
        }
    }
    
    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        intent?.let { parseDeepLinkIntent(it) }
    }
    
    private fun parseDeepLinkIntent(intent: Intent) {
        val data: Uri? = intent.data
        if (data != null && data.scheme == "https" && data.host == "justspent.app") {
            val amount = data.getQueryParameter("amount")
            val category = data.getQueryParameter("category")
            val merchant = data.getQueryParameter("merchant")
            val note = data.getQueryParameter("note")
            
            viewModel.processVoiceCommand(
                amount = amount,
                category = category,
                merchant = merchant,
                note = note
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VoiceExpenseScreen(
    viewModel: VoiceExpenseViewModel,
    onFinish: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    
    // Auto-finish after successful processing
    LaunchedEffect(uiState.isProcessed) {
        if (uiState.isProcessed && uiState.errorMessage == null) {
            delay(2000) // Show success message for 2 seconds
            onFinish()
        }
    }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        when {
            uiState.isProcessing -> {
                ProcessingContent()
            }
            uiState.errorMessage != null -> {
                ErrorContent(
                    error = uiState.errorMessage!!,
                    onRetry = { viewModel.retry() },
                    onCancel = onFinish
                )
            }
            uiState.isProcessed -> {
                SuccessContent(uiState.processedExpense)
            }
            else -> {
                IdleContent()
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
        CircularProgressIndicator()
        Text(
            text = "Processing your expense...",
            style = MaterialTheme.typography.titleMedium
        )
    }
}

@Composable
private fun ErrorContent(
    error: String,
    onRetry: () -> Unit,
    onCancel: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "Error",
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.error
        )
        
        Text(
            text = error,
            style = MaterialTheme.typography.bodyLarge
        )
        
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            TextButton(onClick = onCancel) {
                Text("Cancel")
            }
            
            Button(onClick = onRetry) {
                Text("Retry")
            }
        }
    }
}

@Composable
private fun SuccessContent(expense: String?) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "✓",
            style = MaterialTheme.typography.displayMedium,
            color = MaterialTheme.colorScheme.primary
        )
        
        Text(
            text = "Expense logged successfully!",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )
        
        expense?.let {
            Text(
                text = it,
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}

@Composable
private fun IdleContent() {
    Text(
        text = "Waiting for voice command...",
        style = MaterialTheme.typography.titleMedium
    )
}