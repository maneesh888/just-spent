package com.justspent.app.ui.voice

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import com.justspent.app.data.model.Expense
import com.justspent.app.data.model.ExpenseData
import com.justspent.app.data.repository.ExpenseRepositoryInterface
import com.google.common.truth.Truth.assertThat
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
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
class VoiceExpenseViewModelTest {
    
    @get:Rule
    val instantExecutorRule = InstantTaskExecutorRule()
    
    private val testDispatcher = UnconfinedTestDispatcher()
    private val mockRepository = mock<ExpenseRepositoryInterface>()
    private lateinit var viewModel: VoiceExpenseViewModel
    
    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        viewModel = VoiceExpenseViewModel(mockRepository)
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
        assertThat(state.isProcessing).isFalse()
        assertThat(state.isProcessed).isFalse()
        assertThat(state.errorMessage).isNull()
        assertThat(state.processedExpense).isNull()
    }
    
    @Test
    fun `processVoiceCommand with valid data succeeds`() = runTest {
        // Given
        val mockExpense = createSampleExpense()
        whenever(mockRepository.addExpense(any())).thenReturn(Result.success(mockExpense))
        
        // When
        viewModel.processVoiceCommand(
            amount = "25.50",
            category = "food",
            merchant = "Coffee Shop",
            note = "Morning coffee"
        )
        advanceUntilIdle()
        
        // Then
        val state = viewModel.uiState.value
        assertThat(state.isProcessed).isTrue()
        assertThat(state.isProcessing).isFalse()
        assertThat(state.errorMessage).isNull()
        assertThat(state.processedExpense).contains("25.50")
        
        verify(mockRepository).addExpense(any())
    }
    
    @Test
    fun `processVoiceCommand with invalid amount fails`() = runTest {
        // When
        viewModel.processVoiceCommand(
            amount = "invalid",
            category = "food",
            merchant = null,
            note = null
        )
        advanceUntilIdle()
        
        // Then
        val state = viewModel.uiState.value
        assertThat(state.isProcessed).isFalse()
        assertThat(state.isProcessing).isFalse()
        assertThat(state.errorMessage).isNotNull()
        assertThat(state.errorMessage).contains("Invalid or missing amount")
    }
    
    @Test
    fun `processVoiceCommand with repository failure shows error`() = runTest {
        // Given
        val errorMessage = "Database error"
        whenever(mockRepository.addExpense(any())).thenReturn(Result.failure(Exception(errorMessage)))
        
        // When
        viewModel.processVoiceCommand(
            amount = "25.50",
            category = "food",
            merchant = null,
            note = null
        )
        advanceUntilIdle()
        
        // Then
        val state = viewModel.uiState.value
        assertThat(state.isProcessed).isFalse()
        assertThat(state.isProcessing).isFalse()
        assertThat(state.errorMessage).isEqualTo(errorMessage)
    }
    
    @Test
    fun `processVoiceCommand shows processing state initially`() = runTest {
        // Given
        whenever(mockRepository.addExpense(any())).thenReturn(Result.success(createSampleExpense()))
        
        // When
        viewModel.processVoiceCommand("25.50", "food", null, null)
        
        // Then (before advancing time)
        val state = viewModel.uiState.value
        assertThat(state.isProcessing).isTrue()
        assertThat(state.isProcessed).isFalse()
        assertThat(state.errorMessage).isNull()
    }
    
    @Test
    fun `retry calls processVoiceCommand with last command`() = runTest {
        // Given
        whenever(mockRepository.addExpense(any())).thenReturn(Result.failure(Exception("First failure")))
        
        // Process initial command that fails
        viewModel.processVoiceCommand("25.50", "food", "Coffee Shop", "Morning coffee")
        advanceUntilIdle()
        
        // Setup successful response for retry
        whenever(mockRepository.addExpense(any())).thenReturn(Result.success(createSampleExpense()))
        
        // When
        viewModel.retry()
        advanceUntilIdle()
        
        // Then
        val state = viewModel.uiState.value
        assertThat(state.isProcessed).isTrue()
        assertThat(state.errorMessage).isNull()
        
        // Verify repository was called twice (original + retry)
        verify(mockRepository, times(2)).addExpense(any())
    }
    
    @Test
    fun `parseAmount handles different currency formats`() = runTest {
        // Given
        whenever(mockRepository.addExpense(any())).thenReturn(Result.success(createSampleExpense()))
        
        // Test USD format
        viewModel.processVoiceCommand("$25.50", "food", null, null)
        advanceUntilIdle()
        assertThat(viewModel.uiState.value.isProcessed).isTrue()
        
        // Test AED format
        viewModel.processVoiceCommand("25.50 AED", "food", null, null)
        advanceUntilIdle()
        assertThat(viewModel.uiState.value.isProcessed).isTrue()
        
        // Test with comma
        viewModel.processVoiceCommand("1,234.56", "food", null, null)
        advanceUntilIdle()
        assertThat(viewModel.uiState.value.isProcessed).isTrue()
    }
    
    @Test
    fun `parseAmount handles edge cases correctly`() = runTest {
        // Given
        whenever(mockRepository.addExpense(any())).thenReturn(Result.success(createSampleExpense()))
        
        // Test minimum amount
        viewModel.processVoiceCommand("0.01", "food", null, null)
        advanceUntilIdle()
        assertThat(viewModel.uiState.value.isProcessed).isTrue()
        
        // Test large amount
        viewModel.processVoiceCommand("999999.99", "food", null, null)
        advanceUntilIdle()
        assertThat(viewModel.uiState.value.isProcessed).isTrue()
        
        // Test zero amount (should fail)
        viewModel.processVoiceCommand("0.00", "food", null, null)
        advanceUntilIdle()
        assertThat(viewModel.uiState.value.isProcessed).isFalse()
        assertThat(viewModel.uiState.value.errorMessage).contains("Invalid or missing amount")
    }
    
    @Test
    fun `processVoiceCommand handles long processing gracefully`() = runTest {
        // Given
        whenever(mockRepository.addExpense(any())).thenAnswer {
            kotlinx.coroutines.delay(2000) // Simulate slow processing
            Result.success(createSampleExpense())
        }
        
        // When
        viewModel.processVoiceCommand("25.50", "food", null, null)
        
        // Then - Should show processing state immediately
        assertThat(viewModel.uiState.value.isProcessing).isTrue()
        
        // After completion
        advanceUntilIdle()
        assertThat(viewModel.uiState.value.isProcessing).isFalse()
        assertThat(viewModel.uiState.value.isProcessed).isTrue()
    }
    
    @Test
    fun `clearError resets error state correctly`() = runTest {
        // Given - Create error state
        viewModel.processVoiceCommand("invalid", "food", null, null)
        advanceUntilIdle()
        assertThat(viewModel.uiState.value.errorMessage).isNotNull()
        
        // When
        viewModel.clearError()
        
        // Then
        assertThat(viewModel.uiState.value.errorMessage).isNull()
        assertThat(viewModel.uiState.value.isProcessed).isFalse()
    }
    
    @Test
    fun `processVoiceCommand validates merchant name length`() = runTest {
        // Given
        val longMerchantName = "A".repeat(256) // Very long merchant name
        whenever(mockRepository.addExpense(any())).thenReturn(Result.success(createSampleExpense()))
        
        // When
        viewModel.processVoiceCommand("25.50", "food", longMerchantName, null)
        advanceUntilIdle()
        
        // Then - Should handle gracefully or truncate
        verify(mockRepository).addExpense(argThat { expenseData ->
            expenseData.merchant == null || expenseData.merchant!!.length <= 100
        })
    }
    
    @Test
    fun `parseCategory maps voice commands correctly`() = runTest {
        // Given
        whenever(mockRepository.addExpense(any())).thenReturn(Result.success(createSampleExpense()))
        
        // When testing different category mappings
        viewModel.processVoiceCommand("25.50", "food", null, null)
        advanceUntilIdle()
        
        // Then verify repository was called (category mapping tested via integration)
        verify(mockRepository).addExpense(argThat { expenseData ->
            expenseData.category == "Food & Dining"
        })
    }
    
    @Test
    fun `detectCurrency identifies different currencies`() = runTest {
        // Given
        whenever(mockRepository.addExpense(any())).thenReturn(Result.success(createSampleExpense()))
        
        // Test AED detection
        viewModel.processVoiceCommand("25 AED", "food", null, null)
        advanceUntilIdle()
        
        verify(mockRepository).addExpense(argThat { expenseData ->
            expenseData.currency == "AED"
        })
        
        // Test USD detection
        viewModel.processVoiceCommand("25 dollars", "food", null, null)
        advanceUntilIdle()
        
        verify(mockRepository).addExpense(argThat { expenseData ->
            expenseData.currency == "USD"
        })
        
        // Test EUR detection
        viewModel.processVoiceCommand("25 euros", "food", null, null)
        advanceUntilIdle()
        
        verify(mockRepository).addExpense(argThat { expenseData ->
            expenseData.currency == "EUR"
        })
        
        // Test GBP detection
        viewModel.processVoiceCommand("25 pounds", "food", null, null)
        advanceUntilIdle()
        
        verify(mockRepository).addExpense(argThat { expenseData ->
            expenseData.currency == "GBP"
        })
    }
    
    @Test
    fun `processVoiceCommand handles concurrent requests correctly`() = runTest {
        // Given
        whenever(mockRepository.addExpense(any())).thenReturn(Result.success(createSampleExpense()))
        
        // When - Multiple rapid requests
        viewModel.processVoiceCommand("25.50", "food", "Restaurant A", null)
        viewModel.processVoiceCommand("30.00", "transport", "Taxi", null)
        viewModel.processVoiceCommand("15.75", "shopping", "Store", null)
        
        advanceUntilIdle()
        
        // Then - Should handle all requests (last one wins for state)
        verify(mockRepository, times(3)).addExpense(any())
        assertThat(viewModel.uiState.value.isProcessed).isTrue()
    }
    
    @Test
    fun `retry handles different failure scenarios`() = runTest {
        // Given - Network failure first, then success
        whenever(mockRepository.addExpense(any()))
            .thenReturn(Result.failure(Exception("Network timeout")))
            .thenReturn(Result.success(createSampleExpense()))
        
        // Initial failure
        viewModel.processVoiceCommand("25.50", "food", "Coffee Shop", "Morning coffee")
        advanceUntilIdle()
        assertThat(viewModel.uiState.value.errorMessage).isEqualTo("Network timeout")
        
        // When - Retry
        viewModel.retry()
        advanceUntilIdle()
        
        // Then - Should succeed
        assertThat(viewModel.uiState.value.isProcessed).isTrue()
        assertThat(viewModel.uiState.value.errorMessage).isNull()
        verify(mockRepository, times(2)).addExpense(any())
    }
    
    @Test
    fun `parseCategory handles multilingual input`() = runTest {
        // Given
        whenever(mockRepository.addExpense(any())).thenReturn(Result.success(createSampleExpense()))
        
        // Test English categories
        viewModel.processVoiceCommand("25.50", "groceries", null, null)
        advanceUntilIdle()
        verify(mockRepository).addExpense(argThat { it.category == "Grocery" })
        
        // Test alternative category names
        viewModel.processVoiceCommand("25.50", "transport", null, null)
        advanceUntilIdle()
        verify(mockRepository).addExpense(argThat { it.category == "Transportation" })
        
        // Test case insensitive
        viewModel.processVoiceCommand("25.50", "FOOD", null, null)
        advanceUntilIdle()
        verify(mockRepository).addExpense(argThat { it.category == "Food & Dining" })
    }
    
    private fun createSampleExpense(): Expense {
        val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())
        return Expense(
            id = "test-id",
            userId = "test-user",
            amount = BigDecimal("25.50"),
            currency = "USD",
            category = "Food & Dining",
            transactionDate = now,
            createdAt = now,
            updatedAt = now,
            source = "voice_assistant"
        )
    }
}