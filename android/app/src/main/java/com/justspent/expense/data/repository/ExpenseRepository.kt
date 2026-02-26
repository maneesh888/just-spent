package com.justspent.expense.data.repository

import com.justspent.expense.data.dao.ExpenseDao
import com.justspent.expense.data.model.Expense
import com.justspent.expense.data.model.ExpenseData
import com.justspent.expense.utils.DateFilter
import com.justspent.expense.utils.DateFilterUtils
import kotlinx.coroutines.flow.Flow
import kotlinx.datetime.Clock
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toKotlinLocalDateTime
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

    // Pagination methods
    suspend fun loadExpensesPage(
        currency: String,
        dateFilter: DateFilter,
        page: Int,
        pageSize: Int = 20
    ): Result<List<Expense>>

    fun getDistinctCurrencies(): Flow<List<String>>
    fun getTotalByCurrency(currency: String): Flow<BigDecimal?>
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

    override suspend fun loadExpensesPage(
        currency: String,
        dateFilter: DateFilter,
        page: Int,
        pageSize: Int
    ): Result<List<Expense>> {
        return try {
            val offset = page * pageSize
            val expenses = when (val dateRange = DateFilterUtils.dateRange(dateFilter)) {
                null -> {
                    // No date filter - get all expenses for currency
                    expenseDao.getExpensesPaginated(
                        currency = currency,
                        limit = pageSize,
                        offset = offset
                    )
                }
                else -> {
                    // Apply date filter - convert Java LocalDateTime to Kotlin LocalDateTime
                    expenseDao.getExpensesPaginatedWithDateFilter(
                        currency = currency,
                        startDate = dateRange.first.toKotlinLocalDateTime(),
                        endDate = dateRange.second.toKotlinLocalDateTime(),
                        limit = pageSize,
                        offset = offset
                    )
                }
            }
            Result.success(expenses)
        } catch (e: Exception) {
            Result.failure(ExpenseError.DatabaseError(e.message ?: "Failed to load expenses page"))
        }
    }

    override fun getDistinctCurrencies(): Flow<List<String>> {
        return expenseDao.getDistinctCurrencies()
    }

    override fun getTotalByCurrency(currency: String): Flow<BigDecimal?> {
        return expenseDao.getTotalByCurrency(currency)
    }
}

sealed class ExpenseError : Exception() {
    data class DatabaseError(override val message: String) : ExpenseError()
    data class ValidationError(override val message: String) : ExpenseError()
    data class NetworkError(override val message: String) : ExpenseError()
}