package com.justspent.app.ui.voice

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.justspent.app.data.model.ExpenseData
import com.justspent.app.data.repository.ExpenseRepositoryInterface
import com.justspent.app.voice.VoiceCommandProcessor
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import java.math.BigDecimal
import java.util.Locale
import javax.inject.Inject

data class VoiceExpenseUiState(
    val isProcessing: Boolean = false,
    val isProcessed: Boolean = false,
    val errorMessage: String? = null,
    val processedExpense: String? = null,
    val confidenceScore: Double? = null,
    val suggestedPhrases: List<String> = emptyList(),
    val requiresConfirmation: Boolean = false,
    val extractedData: ExtractedVoiceData? = null
)

data class ExtractedVoiceData(
    val originalCommand: String,
    val amount: String?,
    val currency: String?,
    val category: String?,
    val merchant: String?,
    val notes: String?
)

@HiltViewModel
class VoiceExpenseViewModel @Inject constructor(
    private val repository: ExpenseRepositoryInterface,
    private val voiceCommandProcessor: VoiceCommandProcessor,
    val voiceRecordingManager: com.justspent.app.voice.VoiceRecordingManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(VoiceExpenseUiState())
    val uiState: StateFlow<VoiceExpenseUiState> = _uiState.asStateFlow()

    private var lastVoiceCommand: VoiceCommand? = null
    private var lastRawCommand: String? = null

    /**
     * Start voice recording with auto-stop detection
     */
    fun startVoiceRecording() {
        _uiState.value = VoiceExpenseUiState(isProcessing = true)

        voiceRecordingManager.startRecording(
            onResult = { transcription ->
                // Process the transcription
                processRawVoiceCommand(transcription)
            },
            onError = { errorMessage ->
                _uiState.value = VoiceExpenseUiState(
                    errorMessage = errorMessage
                )
            }
        )
    }

    override fun onCleared() {
        super.onCleared()
        voiceRecordingManager.release()
    }
    
    /**
     * Process raw voice command using the VoiceCommandProcessor
     */
    fun processRawVoiceCommand(
        command: String,
        locale: Locale = Locale.getDefault()
    ) {
        android.util.Log.d("VoiceExpenseViewModel", "Processing voice command: '$command'")
        lastRawCommand = command
        _uiState.value = VoiceExpenseUiState(isProcessing = true)

        viewModelScope.launch {
            try {
                android.util.Log.d("VoiceExpenseViewModel", "Calling voiceCommandProcessor.processVoiceCommand()")
                val result = voiceCommandProcessor.processVoiceCommand(command, locale)
                val confidenceScore = voiceCommandProcessor.getConfidenceScore(command)

                android.util.Log.d("VoiceExpenseViewModel", "Confidence score: $confidenceScore")

                result.fold(
                    onSuccess = { expenseData ->
                        android.util.Log.d("VoiceExpenseViewModel", "Successfully parsed: amount=${expenseData.amount}, currency=${expenseData.currency}, category=${expenseData.category}")

                        val extractedData = ExtractedVoiceData(
                            originalCommand = command,
                            amount = expenseData.amount.toString(),
                            currency = expenseData.currency,
                            category = expenseData.category,
                            merchant = expenseData.merchant,
                            notes = expenseData.notes
                        )

                        // Check if confirmation is needed (large amounts or low confidence)
                        val requiresConfirmation = expenseData.amount.toDouble() > 1000.0 || confidenceScore < 0.8

                        android.util.Log.d("VoiceExpenseViewModel", "Requires confirmation: $requiresConfirmation")

                        if (requiresConfirmation) {
                            _uiState.value = VoiceExpenseUiState(
                                isProcessing = false,
                                requiresConfirmation = true,
                                extractedData = extractedData,
                                confidenceScore = confidenceScore
                            )
                        } else {
                            // Auto-save for high confidence, small amounts
                            android.util.Log.d("VoiceExpenseViewModel", "Auto-saving expense")
                            saveExpenseData(expenseData, extractedData, confidenceScore)
                        }
                    },
                    onFailure = { error ->
                        android.util.Log.e("VoiceExpenseViewModel", "Failed to process command: ${error.message}", error)
                        val suggestions = voiceCommandProcessor.getSuggestedPhrases(locale)
                        _uiState.value = VoiceExpenseUiState(
                            errorMessage = error.message ?: "Failed to process voice command",
                            suggestedPhrases = suggestions.take(3),
                            confidenceScore = confidenceScore
                        )
                    }
                )
            } catch (e: Exception) {
                android.util.Log.e("VoiceExpenseViewModel", "Exception processing command", e)
                _uiState.value = VoiceExpenseUiState(
                    errorMessage = e.message ?: "Failed to process voice command"
                )
            }
        }
    }
    
    /**
     * Confirm and save the extracted expense data
     */
    fun confirmExpense() {
        val currentState = _uiState.value
        val extractedData = currentState.extractedData
        
        if (extractedData != null) {
            viewModelScope.launch {
                try {
                    // Re-process to get ExpenseData object
                    val result = voiceCommandProcessor.processVoiceCommand(extractedData.originalCommand)
                    result.fold(
                        onSuccess = { expenseData ->
                            saveExpenseData(expenseData, extractedData, currentState.confidenceScore)
                        },
                        onFailure = { error ->
                            _uiState.value = VoiceExpenseUiState(
                                errorMessage = error.message ?: "Failed to save expense"
                            )
                        }
                    )
                } catch (e: Exception) {
                    _uiState.value = VoiceExpenseUiState(
                        errorMessage = e.message ?: "Failed to save expense"
                    )
                }
            }
        }
    }
    
    /**
     * Legacy method for structured voice command input
     */
    fun processVoiceCommand(
        amount: String?,
        category: String?,
        merchant: String?,
        note: String?
    ) {
        val command = VoiceCommand(amount, category, merchant, note)
        lastVoiceCommand = command
        
        _uiState.value = VoiceExpenseUiState(isProcessing = true)
        
        viewModelScope.launch {
            try {
                val expenseData = parseVoiceCommand(command)
                val result = repository.addExpense(expenseData)
                
                result.fold(
                    onSuccess = { expense ->
                        _uiState.value = VoiceExpenseUiState(
                            isProcessed = true,
                            processedExpense = formatExpenseForDisplay(expenseData)
                        )
                    },
                    onFailure = { error ->
                        _uiState.value = VoiceExpenseUiState(
                            errorMessage = error.message ?: "Failed to save expense"
                        )
                    }
                )
            } catch (e: Exception) {
                _uiState.value = VoiceExpenseUiState(
                    errorMessage = e.message ?: "Failed to process voice command"
                )
            }
        }
    }
    
    /**
     * Retry the last voice command
     */
    fun retry() {
        lastRawCommand?.let { command ->
            processRawVoiceCommand(command)
        } ?: lastVoiceCommand?.let { command ->
            processVoiceCommand(command.amount, command.category, command.merchant, command.note)
        }
    }
    
    /**
     * Reset the UI state
     */
    fun resetState() {
        _uiState.value = VoiceExpenseUiState()
    }
    
    /**
     * Get training phrases for the user
     */
    fun getTrainingPhrases(locale: Locale = Locale.getDefault()): List<String> {
        return voiceCommandProcessor.getSuggestedPhrases(locale)
    }
    
    /**
     * Save expense data and update UI state
     */
    private suspend fun saveExpenseData(
        expenseData: ExpenseData,
        extractedData: ExtractedVoiceData,
        confidenceScore: Double?
    ) {
        android.util.Log.d("VoiceExpenseViewModel", "Saving expense to database: ${expenseData.amount} ${expenseData.currency}")
        val result = repository.addExpense(expenseData)

        result.fold(
            onSuccess = { expense ->
                android.util.Log.d("VoiceExpenseViewModel", "Expense saved successfully with ID: ${expense.id}")
                _uiState.value = VoiceExpenseUiState(
                    isProcessed = true,
                    processedExpense = formatExpenseForDisplay(expenseData),
                    extractedData = extractedData,
                    confidenceScore = confidenceScore
                )
            },
            onFailure = { error ->
                android.util.Log.e("VoiceExpenseViewModel", "Failed to save expense: ${error.message}", error)
                _uiState.value = VoiceExpenseUiState(
                    errorMessage = error.message ?: "Failed to save expense"
                )
            }
        )
    }
    
    private fun parseVoiceCommand(command: VoiceCommand): ExpenseData {
        // Parse amount
        val amount = parseAmount(command.amount)
            ?: throw IllegalArgumentException("Invalid or missing amount")
        
        // Parse category
        val category = parseCategory(command.category)
            ?: "Other"
        
        // Currency detection (basic implementation)
        val currency = detectCurrency(command.amount) ?: "USD"
        
        return ExpenseData(
            amount = amount,
            currency = currency,
            category = category,
            merchant = command.merchant?.trim(),
            notes = command.note?.trim(),
            transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            source = "voice_assistant",
            voiceTranscript = formatOriginalCommand(command)
        )
    }
    
    private fun parseAmount(amountStr: String?): BigDecimal? {
        if (amountStr.isNullOrBlank()) return null
        
        return try {
            // Remove currency symbols and parse
            val cleanAmount = amountStr
                .replace("$", "")
                .replace("AED", "")
                .replace("USD", "")
                .replace("EUR", "")
                .replace("GBP", "")
                .replace(",", "")
                .trim()
            
            BigDecimal(cleanAmount)
        } catch (e: NumberFormatException) {
            null
        }
    }
    
    private fun parseCategory(categoryStr: String?): String? {
        if (categoryStr.isNullOrBlank()) return null
        
        // Map common voice commands to categories
        return when (categoryStr.lowercase()) {
            "food", "dining", "restaurant", "meal" -> "Food & Dining"
            "grocery", "groceries", "supermarket" -> "Grocery"
            "transport", "transportation", "taxi", "gas", "fuel" -> "Transportation"
            "shopping", "store", "mall" -> "Shopping"
            "entertainment", "movie", "cinema" -> "Entertainment"
            "bills", "utility", "rent" -> "Bills & Utilities"
            "healthcare", "doctor", "medicine" -> "Healthcare"
            "education", "school", "course" -> "Education"
            else -> categoryStr.replaceFirstChar { it.uppercase() }
        }
    }
    
    private fun detectCurrency(amountStr: String?): String? {
        if (amountStr.isNullOrBlank()) return null
        
        return when {
            amountStr.contains("AED", ignoreCase = true) || 
            amountStr.contains("dirham", ignoreCase = true) -> "AED"
            amountStr.contains("USD", ignoreCase = true) || 
            amountStr.contains("dollar", ignoreCase = true) -> "USD"
            amountStr.contains("EUR", ignoreCase = true) || 
            amountStr.contains("euro", ignoreCase = true) -> "EUR"
            amountStr.contains("GBP", ignoreCase = true) || 
            amountStr.contains("pound", ignoreCase = true) -> "GBP"
            else -> "USD" // Default
        }
    }
    
    private fun formatOriginalCommand(command: VoiceCommand): String {
        return buildString {
            append("I spent ")
            command.amount?.let { append(it) }
            command.category?.let { append(" on $it") }
            command.merchant?.let { append(" at $it") }
            command.note?.let { append(" - $it") }
        }
    }
    
    private fun formatExpenseForDisplay(expenseData: ExpenseData): String {
        return "${expenseData.currency} ${expenseData.amount} - ${expenseData.category}"
    }
}

private data class VoiceCommand(
    val amount: String?,
    val category: String?,
    val merchant: String?,
    val note: String?
)