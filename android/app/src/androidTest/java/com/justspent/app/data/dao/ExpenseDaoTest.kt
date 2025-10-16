package com.justspent.app.data.dao

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.justspent.app.data.database.JustSpentDatabase
import com.justspent.app.data.model.Expense
import com.google.common.truth.Truth.assertThat
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.math.BigDecimal

@RunWith(AndroidJUnit4::class)
class ExpenseDaoTest {
    
    @get:Rule
    val instantExecutorRule = InstantTaskExecutorRule()
    
    private lateinit var database: JustSpentDatabase
    private lateinit var expenseDao: ExpenseDao
    
    @Before
    fun setup() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            JustSpentDatabase::class.java
        ).allowMainThreadQueries().build()
        
        expenseDao = database.expenseDao()
    }
    
    @After
    fun tearDown() {
        database.close()
    }
    
    @Test
    fun insertAndRetrieveExpense() = runTest {
        // Given
        val expense = createSampleExpense("1")
        
        // When
        expenseDao.insertExpense(expense)
        val expenses = expenseDao.getAllExpenses().first()
        
        // Then
        assertThat(expenses).hasSize(1)
        assertThat(expenses[0]).isEqualTo(expense)
    }
    
    @Test
    fun insertMultipleExpensesOrderedByDateDesc() = runTest {
        // Given
        val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())
        val expense1 = createSampleExpense("1", transactionDate = now.minusDays(2))
        val expense2 = createSampleExpense("2", transactionDate = now.minusDays(1))
        val expense3 = createSampleExpense("3", transactionDate = now)
        
        // When
        expenseDao.insertExpense(expense1)
        expenseDao.insertExpense(expense2)
        expenseDao.insertExpense(expense3)
        val expenses = expenseDao.getAllExpenses().first()
        
        // Then
        assertThat(expenses).hasSize(3)
        assertThat(expenses[0]).isEqualTo(expense3) // Most recent first
        assertThat(expenses[1]).isEqualTo(expense2)
        assertThat(expenses[2]).isEqualTo(expense1)
    }
    
    @Test
    fun getExpensesByCategory() = runTest {
        // Given
        val foodExpense = createSampleExpense("1", category = "Food & Dining")
        val transportExpense = createSampleExpense("2", category = "Transportation")
        
        // When
        expenseDao.insertExpense(foodExpense)
        expenseDao.insertExpense(transportExpense)
        val foodExpenses = expenseDao.getExpensesByCategory("Food & Dining").first()
        
        // Then
        assertThat(foodExpenses).hasSize(1)
        assertThat(foodExpenses[0]).isEqualTo(foodExpense)
    }
    
    @Test
    fun getTotalSpending() = runTest {
        // Given
        val expense1 = createSampleExpense("1", amount = BigDecimal("15.50"))
        val expense2 = createSampleExpense("2", amount = BigDecimal("25.75"))
        
        // When
        expenseDao.insertExpense(expense1)
        expenseDao.insertExpense(expense2)
        val total = expenseDao.getAllTimeTotal().first()
        
        // Then
        assertThat(total).isEqualTo(BigDecimal("41.25"))
    }
    
    @Test
    fun updateExpense() = runTest {
        // Given
        val expense = createSampleExpense("1")
        expenseDao.insertExpense(expense)
        
        // When
        val updatedExpense = expense.copy(amount = BigDecimal("99.99"))
        expenseDao.updateExpense(updatedExpense)
        val expenses = expenseDao.getAllExpenses().first()
        
        // Then
        assertThat(expenses).hasSize(1)
        assertThat(expenses[0].amount).isEqualTo(BigDecimal("99.99"))
    }
    
    @Test
    fun deleteExpense() = runTest {
        // Given
        val expense = createSampleExpense("1")
        expenseDao.insertExpense(expense)
        assertThat(expenseDao.getAllExpenses().first()).hasSize(1)
        
        // When
        expenseDao.deleteExpense(expense)
        val expenses = expenseDao.getAllExpenses().first()
        
        // Then
        assertThat(expenses).isEmpty()
    }
    
    @Test
    fun getExpenseById() = runTest {
        // Given
        val expense = createSampleExpense("test-id")
        expenseDao.insertExpense(expense)
        
        // When
        val retrievedExpense = expenseDao.getExpenseById("test-id")
        
        // Then
        assertThat(retrievedExpense).isEqualTo(expense)
    }
    
    @Test
    fun getDistinctCategories() = runTest {
        // Given
        expenseDao.insertExpense(createSampleExpense("1", category = "Food & Dining"))
        expenseDao.insertExpense(createSampleExpense("2", category = "Transportation"))
        expenseDao.insertExpense(createSampleExpense("3", category = "Food & Dining"))
        
        // When
        val categories = expenseDao.getDistinctCategories().first()
        
        // Then
        assertThat(categories).containsExactly("Food & Dining", "Transportation")
    }
    
    private fun createSampleExpense(
        id: String,
        category: String = "Food & Dining",
        amount: BigDecimal = BigDecimal("15.50"),
        transactionDate: kotlinx.datetime.LocalDateTime = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())
    ): Expense {
        return Expense(
            id = id,
            amount = amount,
            currency = "USD",
            category = category,
            merchant = "Test Merchant",
            transactionDate = transactionDate,
            createdAt = transactionDate,
            updatedAt = transactionDate,
            source = "manual"
        )
    }
    
    private fun kotlinx.datetime.LocalDateTime.minusDays(days: Int): kotlinx.datetime.LocalDateTime {
        // Simple implementation for testing
        return kotlinx.datetime.LocalDateTime(
            year = this.year,
            monthNumber = this.monthNumber,
            dayOfMonth = this.dayOfMonth - days,
            hour = this.hour,
            minute = this.minute,
            second = this.second,
            nanosecond = this.nanosecond
        )
    }
}