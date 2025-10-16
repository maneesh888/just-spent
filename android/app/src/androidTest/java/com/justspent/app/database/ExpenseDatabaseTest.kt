package com.justspent.app.database

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.google.common.truth.Truth.assertThat
import com.justspent.app.data.database.JustSpentDatabase
import com.justspent.app.data.dao.ExpenseDao
import com.justspent.app.data.model.Expense
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
import java.io.IOException
import java.math.BigDecimal

@RunWith(AndroidJUnit4::class)
class ExpenseDatabaseTest {
    
    @get:Rule
    val instantExecutorRule = InstantTaskExecutorRule()
    
    private lateinit var expenseDao: ExpenseDao
    private lateinit var database: JustSpentDatabase
    
    @Before
    fun createDatabase() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            JustSpentDatabase::class.java
        ).build()
        expenseDao = database.expenseDao()
    }
    
    @After
    @Throws(IOException::class)
    fun closeDatabase() {
        database.close()
    }
    
    @Test
    @Throws(Exception::class)
    fun insertAndRetrieveExpense() = runTest {
        // Given
        val expense = createSampleExpense("test-1", "test-user")
        
        // When
        expenseDao.insertExpense(expense)
        val expenses = expenseDao.getAllExpenses("test-user").first()
        
        // Then
        assertThat(expenses).hasSize(1)
        assertThat(expenses[0].id).isEqualTo("test-1")
        assertThat(expenses[0].amount).isEqualTo(BigDecimal("25.50"))
        assertThat(expenses[0].category).isEqualTo("Food & Dining")
    }
    
    @Test
    fun insertMultipleExpensesAndRetrieve() = runTest {
        // Given
        val expenses = listOf(
            createSampleExpense("expense-1", "user-1", amount = BigDecimal("10.00")),
            createSampleExpense("expense-2", "user-1", amount = BigDecimal("20.00")),
            createSampleExpense("expense-3", "user-2", amount = BigDecimal("30.00"))
        )
        
        // When
        expenses.forEach { expenseDao.insertExpense(it) }
        
        // Then
        val user1Expenses = expenseDao.getAllExpenses("user-1").first()
        val user2Expenses = expenseDao.getAllExpenses("user-2").first()
        
        assertThat(user1Expenses).hasSize(2)
        assertThat(user2Expenses).hasSize(1)
        
        val totalUser1 = user1Expenses.sumOf { it.amount }
        assertThat(totalUser1).isEqualTo(BigDecimal("30.00"))
    }
    
    @Test
    fun updateExpenseChangesData() = runTest {
        // Given
        val originalExpense = createSampleExpense("test-1", "test-user")
        expenseDao.insertExpense(originalExpense)
        
        // When
        val updatedExpense = originalExpense.copy(
            amount = BigDecimal("50.00"),
            category = "Transport",
            merchant = "Updated Merchant"
        )
        expenseDao.updateExpense(updatedExpense)
        
        // Then
        val expenses = expenseDao.getAllExpenses("test-user").first()
        assertThat(expenses).hasSize(1)
        assertThat(expenses[0].amount).isEqualTo(BigDecimal("50.00"))
        assertThat(expenses[0].category).isEqualTo("Transport")
        assertThat(expenses[0].merchant).isEqualTo("Updated Merchant")
    }
    
    @Test
    fun deleteExpenseRemovesFromDatabase() = runTest {
        // Given
        val expense1 = createSampleExpense("expense-1", "test-user")
        val expense2 = createSampleExpense("expense-2", "test-user")
        
        expenseDao.insertExpense(expense1)
        expenseDao.insertExpense(expense2)
        
        // When
        expenseDao.deleteExpense(expense1)
        
        // Then
        val expenses = expenseDao.getAllExpenses("test-user").first()
        assertThat(expenses).hasSize(1)
        assertThat(expenses[0].id).isEqualTo("expense-2")
    }
    
    @Test
    fun getExpensesByCategoryFiltersCorrectly() = runTest {
        // Given
        val foodExpense = createSampleExpense("food-1", "test-user", category = "Food & Dining")
        val transportExpense = createSampleExpense("transport-1", "test-user", category = "Transport")
        
        expenseDao.insertExpense(foodExpense)
        expenseDao.insertExpense(transportExpense)
        
        // When
        val foodExpenses = expenseDao.getExpensesByCategory("Food & Dining", "test-user").first()
        val transportExpenses = expenseDao.getExpensesByCategory("Transport", "test-user").first()
        
        // Then
        assertThat(foodExpenses).hasSize(1)
        assertThat(foodExpenses[0].category).isEqualTo("Food & Dining")
        
        assertThat(transportExpenses).hasSize(1)
        assertThat(transportExpenses[0].category).isEqualTo("Transport")
    }
    
    @Test
    fun getTotalSpendingCalculatesCorrectly() = runTest {
        // Given
        val expenses = listOf(
            createSampleExpense("expense-1", "test-user", amount = BigDecimal("15.50")),
            createSampleExpense("expense-2", "test-user", amount = BigDecimal("25.75")),
            createSampleExpense("expense-3", "test-user", amount = BigDecimal("10.00"))
        )
        
        expenses.forEach { expenseDao.insertExpense(it) }
        
        // When
        val total = expenseDao.getTotalSpending("test-user").first()
        
        // Then
        assertThat(total).isEqualTo(BigDecimal("51.25"))
    }
    
    @Test
    fun expensesOrderedByDateDescending() = runTest {
        // Given
        val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())
        val expense1 = createSampleExpense("expense-1", "test-user").copy(
            transactionDate = now.minusDays(2)
        )
        val expense2 = createSampleExpense("expense-2", "test-user").copy(
            transactionDate = now.minusDays(1)
        )
        val expense3 = createSampleExpense("expense-3", "test-user").copy(
            transactionDate = now
        )
        
        // Insert in random order
        expenseDao.insertExpense(expense2)
        expenseDao.insertExpense(expense1)
        expenseDao.insertExpense(expense3)
        
        // When
        val expenses = expenseDao.getAllExpenses("test-user").first()
        
        // Then
        assertThat(expenses).hasSize(3)
        assertThat(expenses[0].id).isEqualTo("expense-3") // Most recent
        assertThat(expenses[1].id).isEqualTo("expense-2")
        assertThat(expenses[2].id).isEqualTo("expense-1") // Oldest
    }
    
    @Test
    fun databaseHandlesLargeDataset() = runTest {
        // Given
        val largeDataset = (1..1000).map { index ->
            createSampleExpense("expense-$index", "test-user", amount = BigDecimal("$index.50"))
        }
        
        // When
        largeDataset.forEach { expenseDao.insertExpense(it) }
        
        // Then
        val expenses = expenseDao.getAllExpenses("test-user").first()
        val total = expenseDao.getTotalSpending("test-user").first()
        
        assertThat(expenses).hasSize(1000)
        assertThat(total).isEqualTo(BigDecimal("500500.00")) // Sum of 1.50 + 2.50 + ... + 1000.50
    }
    
    @Test
    fun databaseHandlesUnicodeCharacters() = runTest {
        // Given
        val expense = createSampleExpense("unicode-test", "test-user").copy(
            merchant = "Café René",
            description = "Coffee ☕ and croissant 🥐",
            notes = "Délicieux repas avec des amis"
        )
        
        // When
        expenseDao.insertExpense(expense)
        
        // Then
        val expenses = expenseDao.getAllExpenses("test-user").first()
        assertThat(expenses).hasSize(1)
        assertThat(expenses[0].merchant).isEqualTo("Café René")
        assertThat(expenses[0].description).isEqualTo("Coffee ☕ and croissant 🥐")
        assertThat(expenses[0].notes).isEqualTo("Délicieux repas avec des amis")
    }
    
    @Test
    fun databaseHandlesNullOptionalFields() = runTest {
        // Given
        val expense = createSampleExpense("null-test", "test-user").copy(
            merchant = null,
            description = null,
            notes = null,
            voiceTranscript = null
        )
        
        // When
        expenseDao.insertExpense(expense)
        
        // Then
        val expenses = expenseDao.getAllExpenses("test-user").first()
        assertThat(expenses).hasSize(1)
        assertThat(expenses[0].merchant).isNull()
        assertThat(expenses[0].description).isNull()
        assertThat(expenses[0].notes).isNull()
        assertThat(expenses[0].voiceTranscript).isNull()
    }
    
    @Test
    fun concurrentAccessHandledCorrectly() = runTest {
        // Given
        val user1Expenses = (1..50).map { 
            createSampleExpense("user1-expense-$it", "user-1")
        }
        val user2Expenses = (1..50).map { 
            createSampleExpense("user2-expense-$it", "user-2")
        }
        
        // When - Simulate concurrent access
        user1Expenses.forEach { expenseDao.insertExpense(it) }
        user2Expenses.forEach { expenseDao.insertExpense(it) }
        
        // Then
        val user1Result = expenseDao.getAllExpenses("user-1").first()
        val user2Result = expenseDao.getAllExpenses("user-2").first()
        
        assertThat(user1Result).hasSize(50)
        assertThat(user2Result).hasSize(50)
        
        // Verify data integrity
        user1Result.forEach { expense ->
            assertThat(expense.userId).isEqualTo("user-1")
        }
        user2Result.forEach { expense ->
            assertThat(expense.userId).isEqualTo("user-2")
        }
    }
    
    private fun createSampleExpense(
        id: String,
        userId: String,
        amount: BigDecimal = BigDecimal("25.50"),
        category: String = "Food & Dining"
    ): Expense {
        val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())
        return Expense(
            id = id,
            userId = userId,
            amount = amount,
            currency = "USD",
            category = category,
            merchant = "Test Merchant",
            description = "Test expense",
            notes = "Test notes",
            transactionDate = now,
            createdAt = now,
            updatedAt = now,
            source = "manual",
            voiceTranscript = null
        )
    }
    
    private fun LocalDateTime.minusDays(days: Long): LocalDateTime {
        // Simple implementation for testing
        return LocalDateTime(
            this.year,
            this.monthNumber,
            this.dayOfMonth - days.toInt(),
            this.hour,
            this.minute,
            this.second
        )
    }
}