package com.justspent.app.ui.expenses

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.justspent.app.data.model.Expense
import com.justspent.app.data.model.ExpenseData
import com.justspent.app.data.repository.ExpenseRepositoryInterface
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import java.math.BigDecimal
import java.text.NumberFormat
import java.util.*
import javax.inject.Inject

data class ExpenseListUiState(
    val expenses: List<Expense> = emptyList(),
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val totalSpending: BigDecimal = BigDecimal.ZERO,
    val formattedTotalSpending: String = "$0.00"
)

@HiltViewModel
class ExpenseListViewModel @Inject constructor(
    private val repository: ExpenseRepositoryInterface
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(ExpenseListUiState())
    val uiState: StateFlow<ExpenseListUiState> = _uiState.asStateFlow()
    
    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()
    
    init {
        loadExpenses()
    }
    
    private fun loadExpenses() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }
            
            try {
                combine(
                    repository.getAllExpenses(),
                    repository.getTotalSpending()
                ) { expenses, total ->
                    val totalAmount = total ?: BigDecimal.ZERO
                    val formattedTotal = formatCurrency(totalAmount)
                    
                    ExpenseListUiState(
                        expenses = expenses,
                        isLoading = false,
                        totalSpending = totalAmount,
                        formattedTotalSpending = formattedTotal
                    )
                }.collect { state ->
                    _uiState.value = state
                }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(
                        isLoading = false, 
                        errorMessage = e.message ?: "Unknown error"
                    )
                }
            }
        }
    }
    
    fun addSampleExpense() {
        viewModelScope.launch {
            val categories = listOf("Food & Dining", "Grocery", "Transport", "Shopping")
            val merchants = listOf("Coffee Shop", "Supermarket", "Gas Station", "Store")
            val amounts = listOf(5.50, 15.75, 25.00, 45.99, 8.25)
            
            val expenseData = ExpenseData(
                amount = BigDecimal(amounts.random()),
                currency = "USD",
                category = categories.random(),
                merchant = merchants.random(),
                notes = "Sample expense",
                transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
                source = "manual"
            )
            
            repository.addExpense(expenseData)
                .onFailure { error ->
                    _errorMessage.value = error.message
                }
        }
    }
    
    fun deleteExpense(expense: Expense) {
        viewModelScope.launch {
            repository.deleteExpense(expense)
                .onFailure { error ->
                    _errorMessage.value = error.message
                }
        }
    }
    
    fun clearErrorMessage() {
        _errorMessage.value = null
    }
    
    private fun formatCurrency(amount: BigDecimal): String {
        val formatter = NumberFormat.getCurrencyInstance(Locale.US)
        return formatter.format(amount)
    }
}