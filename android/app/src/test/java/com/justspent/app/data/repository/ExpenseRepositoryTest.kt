package com.justspent.app.data.repository

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import com.justspent.app.data.dao.ExpenseDao
import com.justspent.app.data.model.Expense
import com.justspent.app.data.model.ExpenseData
import com.google.common.truth.Truth.assertThat
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
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
class ExpenseRepositoryTest {
    
    @get:Rule
    val instantExecutorRule = InstantTaskExecutorRule()
    
    private val testDispatcher = UnconfinedTestDispatcher()
    private val mockExpenseDao = mock<ExpenseDao>()
    private lateinit var repository: ExpenseRepository
    
    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        repository = ExpenseRepository(mockExpenseDao)
    }
    
    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }
    
    @Test
    fun `getAllExpenses returns empty list initially`() = runTest {
        // Given
        whenever(mockExpenseDao.getAllExpenses(any())).thenReturn(flowOf(emptyList()))
        
        // When
        val result = repository.getAllExpenses("test-user").first()
        
        // Then
        assertThat(result).isEmpty()
        verify(mockExpenseDao).getAllExpenses("test-user")
    }
    
    @Test
    fun `getExpensesByCategory filters correctly`() = runTest {
        // Given
        val foodExpense = createSampleExpense("1", category = "Food & Dining")
        whenever(mockExpenseDao.getExpensesByCategory("Food & Dining", "test-user"))
            .thenReturn(flowOf(listOf(foodExpense)))
        
        // When
        val result = repository.getExpensesByCategory("Food & Dining", "test-user").first()
        
        // Then
        assertThat(result).hasSize(1)
        assertThat(result.first().category).isEqualTo("Food & Dining")
        verify(mockExpenseDao).getExpensesByCategory("Food & Dining", "test-user")
    }
    
    @Test
    fun `getTotalSpending returns sum from dao`() = runTest {
        // Given
        val total = BigDecimal("150.50")
        whenever(mockExpenseDao.getTotalSpending("test-user")).thenReturn(flowOf(total))
        
        // When
        val result = repository.getTotalSpending("test-user").first()
        
        // Then
        assertThat(result).isEqualTo(total)
        verify(mockExpenseDao).getTotalSpending("test-user")
    }
    
    @Test
    fun `addExpense success creates expense with correct data`() = runTest {
        // Given
        val expenseData = ExpenseData(
            amount = BigDecimal("25.50"),
            currency = "USD",
            category = "Food & Dining",
            merchant = "Coffee Shop",
            notes = "Morning coffee",
            transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            source = "manual",
            voiceTranscript = null
        )
        whenever(mockExpenseDao.insertExpense(any())).thenReturn(1L)
        
        // When
        val result = repository.addExpense(expenseData)
        
        // Then
        assertThat(result.isSuccess).isTrue()
        val expense = result.getOrNull()!!
        assertThat(expense.amount).isEqualTo(BigDecimal("25.50"))
        assertThat(expense.currency).isEqualTo("USD")
        assertThat(expense.category).isEqualTo("Food & Dining")
        assertThat(expense.merchant).isEqualTo("Coffee Shop")
        assertThat(expense.source).isEqualTo("manual")
        verify(mockExpenseDao).insertExpense(any())
    }
    
    @Test
    fun `addExpense with voice transcript stores all data`() = runTest {
        // Given
        val expenseData = ExpenseData(
            amount = BigDecimal("30.00"),
            currency = "AED",
            category = "Grocery",
            merchant = "Supermarket",
            notes = "Weekly shopping",
            transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            source = "voice_assistant",
            voiceTranscript = "I just spent 30 dirhams on groceries at the supermarket"
        )
        whenever(mockExpenseDao.insertExpense(any())).thenReturn(1L)
        
        // When
        val result = repository.addExpense(expenseData)
        
        // Then
        assertThat(result.isSuccess).isTrue()
        val expense = result.getOrNull()!!
        assertThat(expense.source).isEqualTo("voice_assistant")
        assertThat(expense.voiceTranscript).isEqualTo("I just spent 30 dirhams on groceries at the supermarket")
        assertThat(expense.currency).isEqualTo("AED")
    }
    
    @Test
    fun `deleteExpense success removes expense`() = runTest {
        // Given
        val expense = createSampleExpense("1", category = "Transport")
        
        // When
        val result = repository.deleteExpense(expense)
        
        // Then
        assertThat(result.isSuccess).isTrue()
        verify(mockExpenseDao).deleteExpense(expense)
    }
    
    @Test
    fun `addExpense failure returns database error`() = runTest {
        // Given
        val expenseData = ExpenseData(
            amount = BigDecimal("25.50"),
            currency = "USD",
            category = "Food & Dining",
            transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            source = "manual"
        )
        whenever(mockExpenseDao.insertExpense(any())).thenThrow(RuntimeException("Database error"))
        
        // When
        val result = repository.addExpense(expenseData)
        
        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(ExpenseError.DatabaseError::class.java)
    }
    
    @Test
    fun `deleteExpense failure returns database error`() = runTest {
        // Given
        val expense = createSampleExpense("1")
        whenever(mockExpenseDao.deleteExpense(expense)).thenThrow(RuntimeException("Delete failed"))
        
        // When
        val result = repository.deleteExpense(expense)
        
        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(ExpenseError.DatabaseError::class.java)
    }
    
    @Test
    fun `updateExpense calls dao update with updated timestamp`() = runTest {
        // Given
        val expense = createSampleExpense("1")
        
        // When
        val result = repository.updateExpense(expense)
        
        // Then
        assertThat(result.isSuccess).isTrue()
        verify(mockExpenseDao).updateExpense(any())
    }
    
    @Test
    fun `addExpense with invalid amount fails gracefully`() = runTest {
        // Given
        val expenseData = ExpenseData(
            amount = BigDecimal("-25.50"), // Invalid negative amount
            currency = "USD",
            category = "Food & Dining",
            transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            source = "manual"
        )
        
        // When
        val result = repository.addExpense(expenseData)
        
        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(ExpenseError.ValidationError::class.java)
    }
    
    @Test
    fun `addExpense with empty category fails validation`() = runTest {
        // Given
        val expenseData = ExpenseData(
            amount = BigDecimal("25.50"),
            currency = "USD",
            category = "", // Invalid empty category
            transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            source = "manual"
        )
        
        // When
        val result = repository.addExpense(expenseData)
        
        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(ExpenseError.ValidationError::class.java)
    }
    
    @Test
    fun `getAllExpenses handles large dataset efficiently`() = runTest {
        // Given
        val largeExpenseList = (1..1000).map { index ->
            createSampleExpense(
                id = "expense-$index",
                amount = BigDecimal("${index * 10}.50")
            )
        }
        whenever(mockExpenseDao.getAllExpenses("test-user")).thenReturn(flowOf(largeExpenseList))
        
        // When
        val result = repository.getAllExpenses("test-user").first()
        
        // Then
        assertThat(result).hasSize(1000)
        assertThat(result.first().amount).isEqualTo(BigDecimal("10.50"))
        assertThat(result.last().amount).isEqualTo(BigDecimal("10000.50"))
    }
    
    @Test
    fun `repository handles concurrent operations correctly`() = runTest {
        // Given
        val expenseData1 = ExpenseData(
            amount = BigDecimal("25.50"),
            currency = "USD",
            category = "Food & Dining",
            transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            source = "manual"
        )
        val expenseData2 = ExpenseData(
            amount = BigDecimal("30.00"),
            currency = "AED",
            category = "Transport",
            transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            source = "voice_assistant"
        )
        
        whenever(mockExpenseDao.insertExpense(any())).thenReturn(1L, 2L)
        
        // When - Simulate concurrent operations
        val result1 = repository.addExpense(expenseData1)
        val result2 = repository.addExpense(expenseData2)
        
        // Then
        assertThat(result1.isSuccess).isTrue()
        assertThat(result2.isSuccess).isTrue()
        verify(mockExpenseDao, times(2)).insertExpense(any())
    }
    
    private fun createSampleExpense(
        id: String,
        category: String = "Food & Dining",
        amount: BigDecimal = BigDecimal("15.50")
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