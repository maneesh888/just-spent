package com.justspent.app.testutils

import com.justspent.app.data.model.Expense
import com.justspent.app.data.model.ExpenseData
import com.justspent.app.data.repository.ExpenseError
import com.justspent.app.data.repository.ExpenseRepositoryInterface
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import java.math.BigDecimal

/**
 * Mock implementation of ExpenseRepository for testing purposes.
 * Mirrors the iOS MockExpenseRepository patterns for consistency.
 */
class MockExpenseRepository : ExpenseRepositoryInterface {
    
    private val expenses = mutableListOf<Expense>()
    private var nextId = 1
    
    // Configuration for test scenarios
    var shouldSucceed = true
    var errorToReturn: Exception = ExpenseError.DatabaseError("Mock error")
    var simulateDelay = false
    var delayDuration = 100L
    
    // Call tracking for verification
    var addExpenseCalled = false
    var deleteExpenseCalled = false
    var updateExpenseCalled = false
    var getAllExpensesCalled = false
    var getExpensesByCategoryCalled = false
    var getTotalSpendingCalled = false
    
    // Data to return for specific test scenarios
    var expensesToReturn: List<Expense> = emptyList()
        set(value) {
            field = value
            expenses.clear()
            expenses.addAll(value)
        }
    
    var totalToReturn: BigDecimal = BigDecimal.ZERO
    
    override suspend fun addExpense(expenseData: ExpenseData): Result<Expense> {
        addExpenseCalled = true
        
        if (simulateDelay) {
            kotlinx.coroutines.delay(delayDuration)
        }
        
        return if (shouldSucceed) {
            val expense = createExpenseFromData(expenseData)
            expenses.add(expense)
            Result.success(expense)
        } else {
            Result.failure(errorToReturn)
        }
    }
    
    override suspend fun updateExpense(expense: Expense): Result<Expense> {
        updateExpenseCalled = true
        
        if (simulateDelay) {
            kotlinx.coroutines.delay(delayDuration)
        }
        
        return if (shouldSucceed) {
            val index = expenses.indexOfFirst { it.id == expense.id }
            if (index >= 0) {
                val updatedExpense = expense.copy(
                    updatedAt = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())
                )
                expenses[index] = updatedExpense
                Result.success(updatedExpense)
            } else {
                Result.failure(ExpenseError.NotFoundError("Expense not found"))
            }
        } else {
            Result.failure(errorToReturn)
        }
    }
    
    override suspend fun deleteExpense(expense: Expense): Result<Unit> {
        deleteExpenseCalled = true
        
        if (simulateDelay) {
            kotlinx.coroutines.delay(delayDuration)
        }
        
        return if (shouldSucceed) {
            expenses.removeAll { it.id == expense.id }
            Result.success(Unit)
        } else {
            Result.failure(errorToReturn)
        }
    }
    
    override fun getAllExpenses(userId: String): Flow<List<Expense>> {
        getAllExpensesCalled = true
        
        return if (shouldSucceed) {
            val userExpenses = expenses
                .filter { it.userId == userId }
                .sortedByDescending { it.transactionDate }
            flowOf(userExpenses)
        } else {
            throw errorToReturn
        }
    }
    
    override fun getExpensesByCategory(category: String, userId: String): Flow<List<Expense>> {
        getExpensesByCategoryCalled = true
        
        return if (shouldSucceed) {
            val categoryExpenses = expenses
                .filter { it.userId == userId && it.category == category }
                .sortedByDescending { it.transactionDate }
            flowOf(categoryExpenses)
        } else {
            throw errorToReturn
        }
    }
    
    override fun getTotalSpending(userId: String): Flow<BigDecimal> {
        getTotalSpendingCalled = true
        
        return if (shouldSucceed) {
            val total = expenses
                .filter { it.userId == userId }
                .sumOf { it.amount }
            flowOf(total)
        } else {
            throw errorToReturn
        }
    }
    
    // Helper methods for test setup
    fun reset() {
        expenses.clear()
        nextId = 1
        shouldSucceed = true
        simulateDelay = false
        delayDuration = 100L
        resetCallTracking()
    }
    
    fun resetCallTracking() {
        addExpenseCalled = false
        deleteExpenseCalled = false
        updateExpenseCalled = false
        getAllExpensesCalled = false
        getExpensesByCategoryCalled = false
        getTotalSpendingCalled = false
    }
    
    fun addSampleExpenses(userId: String, count: Int) {
        repeat(count) { index ->
            val expense = createSampleExpense(
                id = "sample-$index",
                userId = userId,
                amount = BigDecimal("${(index + 1) * 10}.50")
            )
            expenses.add(expense)
        }
    }
    
    fun getCallCount(): Map<String, Boolean> {
        return mapOf(
            "addExpense" to addExpenseCalled,
            "deleteExpense" to deleteExpenseCalled,
            "updateExpense" to updateExpenseCalled,
            "getAllExpenses" to getAllExpensesCalled,
            "getExpensesByCategory" to getExpensesByCategoryCalled,
            "getTotalSpending" to getTotalSpendingCalled
        )
    }
    
    private fun createExpenseFromData(expenseData: ExpenseData): Expense {
        val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())
        return Expense(
            id = "mock-${nextId++}",
            userId = "test-user", // Default test user
            amount = expenseData.amount,
            currency = expenseData.currency,
            category = expenseData.category,
            merchant = expenseData.merchant,
            description = expenseData.notes, // Map notes to description
            notes = expenseData.notes,
            transactionDate = expenseData.transactionDate,
            createdAt = now,
            updatedAt = now,
            source = expenseData.source,
            voiceTranscript = expenseData.voiceTranscript
        )
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
    
    // Builder pattern for easier test setup
    class Builder {
        private val mock = MockExpenseRepository()
        
        fun withSuccess(success: Boolean) = apply {
            mock.shouldSucceed = success
        }
        
        fun withError(error: Exception) = apply {
            mock.errorToReturn = error
        }
        
        fun withDelay(duration: Long) = apply {
            mock.simulateDelay = true
            mock.delayDuration = duration
        }
        
        fun withExpenses(expenses: List<Expense>) = apply {
            mock.expensesToReturn = expenses
        }
        
        fun withSampleExpenses(userId: String, count: Int) = apply {
            mock.addSampleExpenses(userId, count)
        }
        
        fun build(): MockExpenseRepository = mock
    }
    
    companion object {
        fun builder() = Builder()
        
        // Common test scenarios
        fun successfulRepository() = builder()
            .withSuccess(true)
            .build()
        
        fun failingRepository(error: Exception = ExpenseError.DatabaseError("Test error")) = builder()
            .withSuccess(false)
            .withError(error)
            .build()
        
        fun slowRepository(delayMs: Long = 1000L) = builder()
            .withSuccess(true)
            .withDelay(delayMs)
            .build()
        
        fun populatedRepository(userId: String, expenseCount: Int = 5) = builder()
            .withSuccess(true)
            .withSampleExpenses(userId, expenseCount)
            .build()
    }
}