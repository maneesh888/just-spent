package com.justspent.expense.data.dao

import androidx.room.*
import com.justspent.expense.data.model.User
import kotlinx.coroutines.flow.Flow

/**
 * Data Access Object for User operations
 */
@Dao
interface UserDao {

    /**
     * Get the current user (assuming single-user app for now)
     */
    @Query("SELECT * FROM users LIMIT 1")
    fun getCurrentUser(): Flow<User?>

    /**
     * Get user by ID
     */
    @Query("SELECT * FROM users WHERE id = :userId")
    fun getUserById(userId: String): Flow<User?>

    /**
     * Insert a new user
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(user: User): Long

    /**
     * Update an existing user
     */
    @Update
    suspend fun update(user: User)

    /**
     * Delete a user
     */
    @Delete
    suspend fun delete(user: User)

    /**
     * Check if a user exists
     */
    @Query("SELECT COUNT(*) FROM users")
    suspend fun getUserCount(): Int
}
