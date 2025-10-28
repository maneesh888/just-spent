package com.justspent.app

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.justspent.app.data.database.JustSpentDatabase
import com.justspent.app.data.model.Expense
import kotlinx.coroutines.runBlocking
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import org.junit.Test
import org.junit.runner.RunWith
import java.math.BigDecimal

/**
 * Test class to add sample test data to the database
 * Run this ONCE before running UI tests to populate database with expenses
 *
 * Usage: ./test.sh ui -c AddTestDataTest
 */
@RunWith(AndroidJUnit4::class)
class AddTestDataTest {

    @Test
    fun addSampleExpensesToDatabase() = runBlocking {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val database = Room.databaseBuilder(
            context,
            JustSpentDatabase::class.java,
            "just_spent_database"
        ).build()

        val dao = database.expenseDao()
        val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())

        val testExpenses = listOf(
            // AED Expenses (5 items)
            Expense(
                amount = BigDecimal("150.00"),
                currency = "AED",
                category = "Grocery",
                merchant = "Carrefour",
                notes = "Weekly groceries",
                transactionDate = now,
                createdAt = now,
                updatedAt = now,
                source = "voice",
                voiceTranscript = "I spent 150 dirhams on groceries at Carrefour"
            ),
            Expense(
                amount = BigDecimal("50.00"),
                currency = "AED",
                category = "Food & Dining",
                merchant = "Starbucks",
                notes = "Morning coffee",
                transactionDate = now,
                createdAt = now,
                updatedAt = now,
                source = "manual"
            ),
            Expense(
                amount = BigDecimal("200.00"),
                currency = "AED",
                category = "Transportation",
                merchant = "ENOC",
                notes = "Gas refill",
                transactionDate = now,
                createdAt = now,
                updatedAt = now,
                source = "voice",
                voiceTranscript = "200 dirhams for gas"
            ),
            Expense(
                amount = BigDecimal("120.00"),
                currency = "AED",
                category = "Shopping",
                merchant = "H&M",
                notes = "Clothes shopping",
                transactionDate = now,
                createdAt = now,
                updatedAt = now,
                source = "manual"
            ),
            Expense(
                amount = BigDecimal("130.50"),
                currency = "AED",
                category = "Entertainment",
                merchant = "VOX Cinemas",
                notes = "Movie tickets",
                transactionDate = now,
                createdAt = now,
                updatedAt = now,
                source = "voice",
                voiceTranscript = "I just spent 130 dirhams and 50 fils at VOX Cinemas"
            ),

            // USD Expenses (4 items)
            Expense(
                amount = BigDecimal("99.99"),
                currency = "USD",
                category = "Shopping",
                merchant = "Amazon",
                notes = "Online shopping",
                transactionDate = now,
                createdAt = now,
                updatedAt = now,
                source = "manual"
            ),
            Expense(
                amount = BigDecimal("45.00"),
                currency = "USD",
                category = "Food & Dining",
                merchant = "McDonald's",
                notes = "Lunch",
                transactionDate = now,
                createdAt = now,
                updatedAt = now,
                source = "voice",
                voiceTranscript = "45 dollars at McDonald's"
            ),
            Expense(
                amount = BigDecimal("120.00"),
                currency = "USD",
                category = "Bills & Utilities",
                merchant = "Electricity Company",
                notes = "Monthly electricity bill",
                transactionDate = now,
                createdAt = now,
                updatedAt = now,
                source = "manual"
            ),
            Expense(
                amount = BigDecimal("21.00"),
                currency = "USD",
                category = "Transportation",
                merchant = "Uber",
                notes = "Ride to office",
                transactionDate = now,
                createdAt = now,
                updatedAt = now,
                source = "voice",
                voiceTranscript = "I spent 21 dollars on Uber"
            ),

            // EUR Expenses (3 items)
            Expense(
                amount = BigDecimal("78.50"),
                currency = "EUR",
                category = "Food & Dining",
                merchant = "Local Restaurant",
                notes = "Dinner with friends",
                transactionDate = now,
                createdAt = now,
                updatedAt = now,
                source = "manual"
            ),
            Expense(
                amount = BigDecimal("65.00"),
                currency = "EUR",
                category = "Healthcare",
                merchant = "Pharmacy",
                notes = "Medication",
                transactionDate = now,
                createdAt = now,
                updatedAt = now,
                source = "voice",
                voiceTranscript = "65 euros at pharmacy"
            ),
            Expense(
                amount = BigDecimal("55.00"),
                currency = "EUR",
                category = "Entertainment",
                merchant = "Concert Hall",
                notes = "Concert tickets",
                transactionDate = now,
                createdAt = now,
                updatedAt = now,
                source = "manual"
            ),

            // GBP Expenses (2 items)
            Expense(
                amount = BigDecimal("44.99"),
                currency = "GBP",
                category = "Shopping",
                merchant = "Marks & Spencer",
                notes = "Groceries",
                transactionDate = now,
                createdAt = now,
                updatedAt = now,
                source = "manual"
            ),
            Expense(
                amount = BigDecimal("45.00"),
                currency = "GBP",
                category = "Transportation",
                merchant = "National Rail",
                notes = "Train ticket",
                transactionDate = now,
                createdAt = now,
                updatedAt = now,
                source = "voice",
                voiceTranscript = "45 pounds for train"
            )
        )

        // Insert all test expenses
        println("Adding ${testExpenses.size} test expenses to database...")
        testExpenses.forEach { expense ->
            dao.insertExpense(expense)
            println("Added: ${expense.amount} ${expense.currency} - ${expense.category}")
        }

        println("✅ Successfully added ${testExpenses.size} test expenses!")
        println("Test data summary:")
        println("  - AED: 5 expenses (د.إ 650.50)")
        println("  - USD: 4 expenses ($285.99)")
        println("  - EUR: 3 expenses (€198.50)")
        println("  - GBP: 2 expenses (£89.99)")

        database.close()
    }
}
