package com.justspent.expense.ui.expenses

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.justspent.expense.data.model.Currency
import com.justspent.expense.data.model.Expense
import com.justspent.expense.data.model.ExpenseData
import com.justspent.expense.data.preferences.UserPreferences
import com.justspent.expense.data.repository.ExpenseRepositoryInterface
import com.justspent.expense.utils.CurrencyFormatter
import com.justspent.expense.utils.DateFilter
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import java.math.BigDecimal
import javax.inject.Inject

data class ExpenseListUiState(
    val expenses: List<Expense> = emptyList(),
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val totalSpending: BigDecimal = BigDecimal.ZERO,
    val formattedTotalSpending: String = "$0.00"
)

data class PaginationState(
    val loadedExpenses: List<Expense> = emptyList(),
    val currentPage: Int = 0,
    val hasMore: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class ExpenseListViewModel @Inject constructor(
    private val repository: ExpenseRepositoryInterface,
    private val userPreferences: UserPreferences
) : ViewModel() {

    private val _uiState = MutableStateFlow(ExpenseListUiState())
    val uiState: StateFlow<ExpenseListUiState> = _uiState.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    // Pagination state
    private val _paginationState = MutableStateFlow(PaginationState())
    val paginationState: StateFlow<PaginationState> = _paginationState.asStateFlow()

    private var currentCurrency: String = ""
    private var currentDateFilter: DateFilter = DateFilter.All
    private val pageSize: Int = 20

    init {
        loadExpenses()
    }

    private fun loadExpenses() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }

            try {
                combine(
                    repository.getAllExpenses(),
                    repository.getTotalSpending(),
                    userPreferences.defaultCurrency
                ) { expenses, total, defaultCurrency ->
                    val totalAmount = total ?: BigDecimal.ZERO
                    val formattedTotal = formatCurrency(totalAmount, defaultCurrency)

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

    fun updateExpense(expense: Expense) {
        viewModelScope.launch {
            repository.updateExpense(expense)
                .onFailure { error ->
                    _errorMessage.value = error.message
                }
        }
    }

    fun clearErrorMessage() {
        _errorMessage.value = null
    }

    private fun formatCurrency(amount: BigDecimal, currency: Currency): String {
        return CurrencyFormatter.format(
            amount = amount,
            currency = currency,
            showSymbol = true,
            showCode = false
        )
    }

    // Pagination methods
    fun loadFirstPage(currency: String, dateFilter: DateFilter) {
        currentCurrency = currency
        currentDateFilter = dateFilter

        viewModelScope.launch {
            _paginationState.update { it.copy(isLoading = true, error = null) }

            repository.loadExpensesPage(
                currency = currency,
                dateFilter = dateFilter,
                page = 0,
                pageSize = pageSize
            ).fold(
                onSuccess = { expenses ->
                    _paginationState.update {
                        PaginationState(
                            loadedExpenses = expenses,
                            currentPage = 0,
                            hasMore = expenses.size == pageSize,
                            isLoading = false,
                            error = null
                        )
                    }
                },
                onFailure = { error ->
                    _paginationState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message ?: "Failed to load expenses"
                        )
                    }
                }
            )
        }
    }

    fun loadNextPage() {
        val currentState = _paginationState.value

        // Don't load if already loading or no more data
        if (currentState.isLoading || !currentState.hasMore) {
            return
        }

        val nextPage = currentState.currentPage + 1

        viewModelScope.launch {
            _paginationState.update { it.copy(isLoading = true, error = null) }

            repository.loadExpensesPage(
                currency = currentCurrency,
                dateFilter = currentDateFilter,
                page = nextPage,
                pageSize = pageSize
            ).fold(
                onSuccess = { newExpenses ->
                    _paginationState.update { state ->
                        state.copy(
                            loadedExpenses = state.loadedExpenses + newExpenses,
                            currentPage = nextPage,
                            hasMore = newExpenses.size == pageSize,
                            isLoading = false,
                            error = null
                        )
                    }
                },
                onFailure = { error ->
                    _paginationState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message ?: "Failed to load more expenses"
                        )
                    }
                }
            )
        }
    }
}