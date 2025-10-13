package com.justspent.app.ui.expenses

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import com.justspent.app.data.model.Expense
import com.justspent.app.data.model.ExpenseData
import com.justspent.app.data.repository.ExpenseRepositoryInterface
import com.justspent.app.data.repository.ExpenseError
import com.google.common.truth.Truth.assertThat
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.*
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.mockito.kotlin.*
import java.math.BigDecimal

@ExperimentalCoroutinesApi
class ExpenseListViewModelTest {
    
    @get:Rule
    val instantExecutorRule = InstantTaskExecutorRule()
    
    private val testDispatcher = UnconfinedTestDispatcher()
    private val mockRepository = mock<ExpenseRepositoryInterface>()
    private lateinit var viewModel: ExpenseListViewModel
    
    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        
        // Setup default mock responses
        whenever(mockRepository.getAllExpenses(any())).thenReturn(flowOf(emptyList()))
        whenever(mockRepository.getTotalSpending(any())).thenReturn(flowOf(BigDecimal.ZERO))
        
        viewModel = ExpenseListViewModel(mockRepository)
    }
    
    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }
    
    @Test
    fun `initial state is correct`() = runTest {
        // Given - viewModel initialized in setup
        
        // When
        val state = viewModel.uiState.value
        
        // Then
        assertThat(state.expenses).isEmpty()
        assertThat(state.isLoading).isFalse()
        assertThat(state.errorMessage).isNull()
        assertThat(state.totalSpending).isEqualTo(BigDecimal.ZERO)
        assertThat(state.formattedTotalSpending).isEqualTo("$0.00")
    }
    
    @Test
    fun `loadExpenses updates ui state with expenses and total`() = runTest {
        // Given
        val expenses = listOf(
            createSampleExpense("1", BigDecimal("15.50")),
            createSampleExpense("2", BigDecimal("25.00"))
        )
        val total = BigDecimal("40.50")
        
        whenever(mockRepository.getAllExpenses(any())).thenReturn(flowOf(expenses))
        whenever(mockRepository.getTotalSpending(any())).thenReturn(flowOf(total))
        
        // When
        viewModel = ExpenseListViewModel(mockRepository)
        advanceUntilIdle()
        
        // Then
        val state = viewModel.uiState.value
        assertThat(state.expenses).isEqualTo(expenses)
        assertThat(state.totalSpending).isEqualTo(total)
        assertThat(state.formattedTotalSpending).isEqualTo("$40.50")
        assertThat(state.isLoading).isFalse()
    }
    
    @Test
    fun `addSampleExpense calls repository with valid data`() = runTest {
        // Given
        whenever(mockRepository.addExpense(any())).thenReturn(Result.success(createSampleExpense("1")))
        
        // When
        viewModel.addSampleExpense()
        advanceUntilIdle()
        
        // Then
        verify(mockRepository).addExpense(any())
    }
    
    @Test
    fun `addSampleExpense handles repository failure`() = runTest {
        // Given
        val errorMessage = "Database error"
        whenever(mockRepository.addExpense(any())).thenReturn(Result.failure(Exception(errorMessage)))
        
        // When
        viewModel.addSampleExpense()
        advanceUntilIdle()
        
        // Then
        assertThat(viewModel.errorMessage.value).isEqualTo(errorMessage)
    }
    
    @Test
    fun `deleteExpense calls repository delete`() = runTest {
        // Given
        val expense = createSampleExpense("1")
        whenever(mockRepository.deleteExpense(expense)).thenReturn(Result.success(Unit))
        
        // When
        viewModel.deleteExpense(expense)
        advanceUntilIdle()
        
        // Then
        verify(mockRepository).deleteExpense(expense)
    }
    
    @Test
    fun `deleteExpense handles repository failure`() = runTest {
        // Given
        val expense = createSampleExpense("1")
        val errorMessage = "Delete failed"
        whenever(mockRepository.deleteExpense(expense)).thenReturn(Result.failure(Exception(errorMessage)))
        
        // When
        viewModel.deleteExpense(expense)
        advanceUntilIdle()
        
        // Then
        assertThat(viewModel.errorMessage.value).isEqualTo(errorMessage)
    }
    
    @Test
    fun `clearErrorMessage sets error to null`() = runTest {
        // Given
        whenever(mockRepository.addExpense(any())).thenReturn(Result.failure(Exception("Error")))
        viewModel.addSampleExpense()
        advanceUntilIdle()
        assertThat(viewModel.errorMessage.value).isNotNull()
        
        // When
        viewModel.clearErrorMessage()
        
        // Then
        assertThat(viewModel.errorMessage.value).isNull()
    }
    
    @Test
    fun `formatting currency works correctly`() = runTest {
        // Given
        val total = BigDecimal("1234.56")
        whenever(mockRepository.getAllExpenses(any())).thenReturn(flowOf(emptyList()))
        whenever(mockRepository.getTotalSpending(any())).thenReturn(flowOf(total))
        
        // When
        viewModel = ExpenseListViewModel(mockRepository)
        advanceUntilIdle()
        
        // Then
        val state = viewModel.uiState.value
        assertThat(state.formattedTotalSpending).isEqualTo("$1,234.56")
    }
    
    @Test
    fun `loadExpenses handles repository error gracefully`() = runTest {
        // Given
        val errorMessage = "Network error"
        whenever(mockRepository.getAllExpenses(any())).thenThrow(RuntimeException(errorMessage))
        
        // When
        viewModel = ExpenseListViewModel(mockRepository)
        advanceUntilIdle()
        
        // Then
        val state = viewModel.uiState.value
        assertThat(state.expenses).isEmpty()
        assertThat(state.errorMessage).isNotNull()
        assertThat(state.isLoading).isFalse()
    }
    
    @Test
    fun `refreshExpenses updates state correctly`() = runTest {
        // Given
        val initialExpenses = listOf(createSampleExpense("1", BigDecimal("10.00")))
        val updatedExpenses = listOf(
            createSampleExpense("1", BigDecimal("10.00")),
            createSampleExpense("2", BigDecimal("20.00"))
        )
        
        whenever(mockRepository.getAllExpenses(any()))
            .thenReturn(flowOf(initialExpenses))
            .thenReturn(flowOf(updatedExpenses))
        whenever(mockRepository.getTotalSpending(any()))
            .thenReturn(flowOf(BigDecimal("10.00")))
            .thenReturn(flowOf(BigDecimal("30.00")))
        
        viewModel = ExpenseListViewModel(mockRepository)
        advanceUntilIdle()
        
        // When
        viewModel.refreshExpenses()
        advanceUntilIdle()
        
        // Then
        val state = viewModel.uiState.value
        assertThat(state.expenses).hasSize(2)
        assertThat(state.totalSpending).isEqualTo(BigDecimal("30.00"))
    }
    
    @Test
    fun `filterExpensesByCategory works correctly`() = runTest {
        // Given
        val foodExpenses = listOf(createSampleExpense("1", category = "Food & Dining"))
        whenever(mockRepository.getExpensesByCategory("Food & Dining", any()))
            .thenReturn(flowOf(foodExpenses))
        
        // When
        viewModel.filterExpensesByCategory("Food & Dining")
        advanceUntilIdle()
        
        // Then
        val state = viewModel.uiState.value
        assertThat(state.expenses).hasSize(1)
        assertThat(state.expenses.first().category).isEqualTo("Food & Dining")
        verify(mockRepository).getExpensesByCategory("Food & Dining", any())
    }
    
    @Test
    fun `viewModel handles multiple rapid operations`() = runTest {
        // Given
        val expense1 = createSampleExpense("1")
        val expense2 = createSampleExpense("2")
        whenever(mockRepository.addExpense(any()))
            .thenReturn(Result.success(expense1))
            .thenReturn(Result.success(expense2))
        
        // When - Rapid successive operations
        viewModel.addSampleExpense()
        viewModel.addSampleExpense()
        advanceUntilIdle()
        
        // Then
        verify(mockRepository, times(2)).addExpense(any())
        assertThat(viewModel.errorMessage.value).isNull()
    }
    
    private fun createSampleExpense(
        id: String,
        amount: BigDecimal = BigDecimal("15.50"),
        category: String = "Food & Dining"
    ): Expense {
        val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())
        return Expense(
            id = id,
            userId = "test-user",
            amount = amount,
            currency = "USD",
            category = category,
            transactionDate = now,
            createdAt = now,
            updatedAt = now,
            source = "manual"
        )
    }
}