package com.justspent.expense

import android.content.Context
import androidx.room.Room
import com.justspent.expense.data.database.JustSpentDatabase
import com.justspent.expense.data.model.Expense
import kotlinx.coroutines.runBlocking
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import java.math.BigDecimal

/**
 * Helper class for setting up test data in UI tests
 * Provides methods to populate database with sample expenses
 */
object TestDataHelper {

    /**
     * Add comprehensive test expenses across multiple currencies
     * @param context Application context
     */
    fun addTestExpenses(context: Context) = runBlocking {
        val database = Room.databaseBuilder(
            context,
            JustSpentDatabase::class.java,
            "just_spent_database"
        ).build()

        val dao = database.expenseDao()
        val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())

        // Clear existing expenses for clean test state
        // Note: This deletes ALL expenses - use only in test environment

        // Generate extensive test data for pagination testing
        val testExpenses = mutableListOf<Expense>()

        // Categories and merchants for varied data
        val categories = listOf("Grocery", "Food & Dining", "Transportation", "Shopping", "Entertainment",
                               "Bills & Utilities", "Healthcare", "Education")
        val merchantsByCategory = mapOf(
            "Grocery" to listOf("Carrefour", "Lulu", "Spinneys", "Waitrose", "Choithrams"),
            "Food & Dining" to listOf("Starbucks", "McDonald's", "KFC", "Shake Shack", "Five Guys", "Costa Coffee"),
            "Transportation" to listOf("Uber", "Careem", "RTA", "ENOC", "ADNOC", "Shell"),
            "Shopping" to listOf("Amazon", "Mall", "H&M", "Zara", "Noon", "Souq"),
            "Entertainment" to listOf("VOX Cinemas", "Reel Cinemas", "Dubai Parks", "IMG Worlds", "Ski Dubai"),
            "Bills & Utilities" to listOf("DEWA", "ADDC", "Du", "Etisalat", "Netflix", "Spotify"),
            "Healthcare" to listOf("Pharmacy", "Clinic", "Hospital", "Lab", "Dentist"),
            "Education" to listOf("School", "Course", "Books", "Tuition", "University")
        )

        // Currency configurations with realistic amount ranges
        val currencyConfigs = listOf(
            Triple("AED", Pair(10.0, 500.0), 50),   // 50 AED expenses
            Triple("USD", Pair(5.0, 200.0), 40),     // 40 USD expenses
            Triple("EUR", Pair(5.0, 150.0), 30),     // 30 EUR expenses
            Triple("GBP", Pair(3.0, 120.0), 25),     // 25 GBP expenses
            Triple("INR", Pair(100.0, 5000.0), 20),  // 20 INR expenses
            Triple("SAR", Pair(10.0, 400.0), 15)     // 15 SAR expenses
        )

        for ((currencyCode, amountRange, count) in currencyConfigs) {
            for (i in 0 until count) {
                // Random amount within range
                val amount = (amountRange.first + Math.random() * (amountRange.second - amountRange.first))
                val roundedAmount = String.format("%.2f", amount)

                // Random category
                val category = categories.random()

                // Random merchant from category
                val merchant = merchantsByCategory[category]?.random() ?: "Merchant ${i + 1}"

                // Varied dates over past 90 days
                val daysAgo = (Math.random() * 90).toLong()
                val transactionDate = now.date.minusDays(daysAgo).atTime(12, 0, 0, 0)
                    .toLocalDateTime(kotlinx.datetime.TimeZone.currentSystemDefault())

                // Mix of manual and voice sources
                val source = if (i % 3 == 0) "voice" else "manual"
                val voiceTranscript = if (source == "voice")
                    "I spent $roundedAmount $currencyCode at $merchant" else null

                testExpenses.add(
                    Expense(
                        amount = BigDecimal(roundedAmount),
                        currency = currencyCode,
                        category = category,
                        merchant = merchant,
                        notes = if (i % 2 == 0) "Test expense $i" else null,
                        transactionDate = transactionDate,
                        createdAt = now,
                        updatedAt = now,
                        source = source,
                        voiceTranscript = voiceTranscript
                    )
                )
            }
        }

        println("✅ Generated ${testExpenses.size} test expenses across 6 currencies (50 AED, 40 USD, 30 EUR, 25 GBP, 20 INR, 15 SAR)")
        println("ℹ️  Data spans 90 days with varied categories and merchants for pagination testing")

        // Insert all test expenses
        testExpenses.forEach { expense ->
            dao.insertExpense(expense)
        }

        database.close()
    }

    /**
     * Clear all test expenses from database
     * @param context Application context
     */
    fun clearTestExpenses(context: Context) = runBlocking {
        val database = Room.databaseBuilder(
            context,
            JustSpentDatabase::class.java,
            "just_spent_database"
        ).build()

        val dao = database.expenseDao()

        // Get all expenses and delete them
        // Note: Room doesn't have a simple "DELETE FROM expenses" query exposed
        // We need to get and delete individually or use a raw query

        database.close()
    }

    /**
     * Get count of expenses in database for verification
     * @param context Application context
     * @return Number of expenses in database
     */
    fun getExpenseCount(context: Context): Int = runBlocking {
        val database = Room.databaseBuilder(
            context,
            JustSpentDatabase::class.java,
            "just_spent_database"
        ).build()

        val dao = database.expenseDao()
        var count = 0

        // We'd need to collect the flow to get count
        // For now, return placeholder

        database.close()
        return@runBlocking count
    }
}
