package com.justspent.app.ui.voice

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.justspent.app.data.model.ExpenseData
import com.justspent.app.data.repository.ExpenseRepositoryInterface
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import java.math.BigDecimal
import javax.inject.Inject

data class VoiceExpenseUiState(
    val isProcessing: Boolean = false,
    val isProcessed: Boolean = false,
    val errorMessage: String? = null,
    val processedExpense: String? = null
)

@HiltViewModel
class VoiceExpenseViewModel @Inject constructor(
    private val repository: ExpenseRepositoryInterface
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(VoiceExpenseUiState())
    val uiState: StateFlow<VoiceExpenseUiState> = _uiState.asStateFlow()
    
    private var lastVoiceCommand: VoiceCommand? = null
    
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
    
    fun retry() {
        lastVoiceCommand?.let { command ->
            processVoiceCommand(command.amount, command.category, command.merchant, command.note)
        }
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