package com.justspent.expense.data.dao

import androidx.room.*
import com.justspent.expense.data.model.Expense
import kotlinx.coroutines.flow.Flow
import kotlinx.datetime.LocalDateTime
import java.math.BigDecimal

@Dao
interface ExpenseDao {
    @Query("SELECT * FROM expenses WHERE user_id = :userId ORDER BY transaction_date DESC")
    fun getAllExpenses(userId: String = "default_user"): Flow<List<Expense>>
    
    @Query("SELECT * FROM expenses WHERE category = :category AND user_id = :userId ORDER BY transaction_date DESC")
    fun getExpensesByCategory(category: String, userId: String = "default_user"): Flow<List<Expense>>
    
    @Query("SELECT * FROM expenses WHERE transaction_date BETWEEN :startDate AND :endDate AND user_id = :userId ORDER BY transaction_date DESC")
    fun getExpensesByDateRange(
        startDate: LocalDateTime,
        endDate: LocalDateTime,
        userId: String = "default_user"
    ): Flow<List<Expense>>
    
    @Query("SELECT SUM(amount) FROM expenses WHERE user_id = :userId AND transaction_date >= :startDate")
    fun getTotalSpending(startDate: LocalDateTime, userId: String = "default_user"): Flow<BigDecimal?>
    
    @Query("SELECT SUM(amount) FROM expenses WHERE user_id = :userId")
    fun getAllTimeTotal(userId: String = "default_user"): Flow<BigDecimal?>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertExpense(expense: Expense): Long
    
    @Update
    suspend fun updateExpense(expense: Expense)
    
    @Delete
    suspend fun deleteExpense(expense: Expense)
    
    @Query("DELETE FROM expenses WHERE status = 'deleted' AND updated_at < :beforeDate")
    suspend fun cleanupDeletedExpenses(beforeDate: LocalDateTime)
    
    @Query("SELECT * FROM expenses WHERE id = :id")
    suspend fun getExpenseById(id: String): Expense?
    
    @Query("SELECT DISTINCT category FROM expenses WHERE user_id = :userId ORDER BY category ASC")
    fun getDistinctCategories(userId: String = "default_user"): Flow<List<String>>

    @Query("DELETE FROM expenses")
    suspend fun deleteAllExpenses()

    // Pagination queries
    @Query("SELECT * FROM expenses WHERE currency = :currency AND user_id = :userId ORDER BY transaction_date DESC LIMIT :limit OFFSET :offset")
    suspend fun getExpensesPaginated(
        currency: String,
        limit: Int,
        offset: Int,
        userId: String = "default_user"
    ): List<Expense>

    @Query("SELECT * FROM expenses WHERE currency = :currency AND transaction_date BETWEEN :startDate AND :endDate AND user_id = :userId ORDER BY transaction_date DESC LIMIT :limit OFFSET :offset")
    suspend fun getExpensesPaginatedWithDateFilter(
        currency: String,
        startDate: LocalDateTime,
        endDate: LocalDateTime,
        limit: Int,
        offset: Int,
        userId: String = "default_user"
    ): List<Expense>

    @Query("SELECT DISTINCT currency FROM expenses WHERE user_id = :userId ORDER BY currency")
    fun getDistinctCurrencies(userId: String = "default_user"): Flow<List<String>>

    @Query("SELECT SUM(amount) FROM expenses WHERE currency = :currency AND user_id = :userId")
    fun getTotalByCurrency(currency: String, userId: String = "default_user"): Flow<BigDecimal?>
}