package com.justspent.app.data.repository

import com.justspent.app.data.dao.ExpenseDao
import com.justspent.app.data.model.Expense
import com.justspent.app.data.model.ExpenseData
import kotlinx.coroutines.flow.Flow
import kotlinx.datetime.Clock
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import java.math.BigDecimal
import javax.inject.Inject
import javax.inject.Singleton

interface ExpenseRepositoryInterface {
    fun getAllExpenses(): Flow<List<Expense>>
    fun getExpensesByCategory(category: String): Flow<List<Expense>>
    fun getTotalSpending(): Flow<BigDecimal?>
    suspend fun addExpense(expenseData: ExpenseData): Result<Expense>
    suspend fun deleteExpense(expense: Expense): Result<Unit>
    suspend fun updateExpense(expense: Expense): Result<Unit>
}

@Singleton
class ExpenseRepository @Inject constructor(
    private val expenseDao: ExpenseDao
) : ExpenseRepositoryInterface {
    
    override fun getAllExpenses(): Flow<List<Expense>> {
        return expenseDao.getAllExpenses()
    }
    
    override fun getExpensesByCategory(category: String): Flow<List<Expense>> {
        return expenseDao.getExpensesByCategory(category)
    }
    
    override fun getTotalSpending(): Flow<BigDecimal?> {
        return expenseDao.getAllTimeTotal()
    }
    
    override suspend fun addExpense(expenseData: ExpenseData): Result<Expense> {
        return try {
            val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())
            val expense = Expense(
                amount = expenseData.amount,
                currency = expenseData.currency,
                category = expenseData.category,
                merchant = expenseData.merchant,
                notes = expenseData.notes,
                transactionDate = expenseData.transactionDate,
                createdAt = now,
                updatedAt = now,
                source = expenseData.source,
                voiceTranscript = expenseData.voiceTranscript
            )
            
            expenseDao.insertExpense(expense)
            Result.success(expense)
        } catch (e: Exception) {
            Result.failure(ExpenseError.DatabaseError(e.message ?: "Unknown database error"))
        }
    }
    
    override suspend fun deleteExpense(expense: Expense): Result<Unit> {
        return try {
            expenseDao.deleteExpense(expense)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(ExpenseError.DatabaseError(e.message ?: "Failed to delete expense"))
        }
    }
    
    override suspend fun updateExpense(expense: Expense): Result<Unit> {
        return try {
            val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())
            val updatedExpense = expense.copy(updatedAt = now)
            expenseDao.updateExpense(updatedExpense)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(ExpenseError.DatabaseError(e.message ?: "Failed to update expense"))
        }
    }
}

sealed class ExpenseError : Exception() {
    data class DatabaseError(override val message: String) : ExpenseError()
    data class ValidationError(override val message: String) : ExpenseError()
    data class NetworkError(override val message: String) : ExpenseError()
}