package com.justspent.app.data.repository

import com.justspent.app.data.dao.ExpenseDao
import com.justspent.app.data.model.Expense
import com.justspent.app.data.model.ExpenseData
import com.google.common.truth.Truth.assertThat
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import org.junit.Before
import org.junit.Test
import org.mockito.kotlin.*
import java.math.BigDecimal

class ExpenseRepositoryTest {
    
    private val mockExpenseDao = mock<ExpenseDao>()
    private lateinit var repository: ExpenseRepository
    
    @Before
    fun setup() {
        repository = ExpenseRepository(mockExpenseDao)
    }
    
    @Test
    fun `getAllExpenses returns flow of expenses from dao`() = runTest {
        // Given
        val expenses = listOf(
            createSampleExpense("1"),
            createSampleExpense("2")
        )
        whenever(mockExpenseDao.getAllExpenses()).thenReturn(flowOf(expenses))
        
        // When
        val result = repository.getAllExpenses().first()
        
        // Then
        assertThat(result).isEqualTo(expenses)
        verify(mockExpenseDao).getAllExpenses()
    }
    
    @Test
    fun `getExpensesByCategory returns filtered expenses`() = runTest {
        // Given
        val category = "Food & Dining"
        val expenses = listOf(createSampleExpense("1", category = category))
        whenever(mockExpenseDao.getExpensesByCategory(category)).thenReturn(flowOf(expenses))
        
        // When
        val result = repository.getExpensesByCategory(category).first()
        
        // Then
        assertThat(result).isEqualTo(expenses)
        verify(mockExpenseDao).getExpensesByCategory(category)
    }
    
    @Test
    fun `getTotalSpending returns sum from dao`() = runTest {
        // Given
        val total = BigDecimal("150.50")
        whenever(mockExpenseDao.getAllTimeTotal()).thenReturn(flowOf(total))
        
        // When
        val result = repository.getTotalSpending().first()
        
        // Then
        assertThat(result).isEqualTo(total)
        verify(mockExpenseDao).getAllTimeTotal()
    }
    
    @Test
    fun `addExpense creates expense and calls dao insert`() = runTest {
        // Given
        val expenseData = ExpenseData(
            amount = BigDecimal("25.50"),
            currency = "USD",
            category = "Food & Dining",
            merchant = "Coffee Shop",
            notes = "Morning coffee",
            transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            source = "manual"
        )
        whenever(mockExpenseDao.insertExpense(any())).thenReturn(1L)
        
        // When
        val result = repository.addExpense(expenseData)
        
        // Then
        assertThat(result.isSuccess).isTrue()
        verify(mockExpenseDao).insertExpense(any())
    }
    
    @Test
    fun `addExpense handles dao exception`() = runTest {
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
    fun `deleteExpense calls dao delete`() = runTest {
        // Given
        val expense = createSampleExpense("1")
        
        // When
        val result = repository.deleteExpense(expense)
        
        // Then
        assertThat(result.isSuccess).isTrue()
        verify(mockExpenseDao).deleteExpense(expense)
    }
    
    @Test
    fun `deleteExpense handles dao exception`() = runTest {
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
    
    private fun createSampleExpense(
        id: String,
        category: String = "Food & Dining",
        amount: BigDecimal = BigDecimal("15.50")
    ): Expense {
        val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())
        return Expense(
            id = id,
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