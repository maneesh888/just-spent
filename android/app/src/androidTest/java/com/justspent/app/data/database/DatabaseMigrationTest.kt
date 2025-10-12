package com.justspent.app.data.database

import androidx.room.Room
import androidx.room.testing.MigrationTestHelper
import androidx.sqlite.db.framework.FrameworkSQLiteOpenHelperFactory
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.google.common.truth.Truth.assertThat
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.IOException

@RunWith(AndroidJUnit4::class)
class DatabaseMigrationTest {
    
    private val TEST_DB = "migration-test"
    
    @get:Rule
    val helper: MigrationTestHelper = MigrationTestHelper(
        InstrumentationRegistry.getInstrumentation(),
        JustSpentDatabase::class.java,
        emptyList(),
        FrameworkSQLiteOpenHelperFactory()
    )
    
    @Test
    @Throws(IOException::class)
    fun `database creation includes all required tables`() {
        // Create latest version of the database
        val db = helper.createDatabase(TEST_DB, 1)
        
        // Verify expenses table exists
        val cursor = db.query("SELECT name FROM sqlite_master WHERE type='table' AND name='expenses'")
        assertThat(cursor.moveToFirst()).isTrue()
        assertThat(cursor.getString(0)).isEqualTo("expenses")
        cursor.close()
        
        db.close()
    }
    
    @Test
    fun `expenses table has correct columns`() {
        val db = helper.createDatabase(TEST_DB, 1)
        
        // Get table info
        val cursor = db.query("PRAGMA table_info(expenses)")
        val columns = mutableSetOf<String>()
        
        while (cursor.moveToNext()) {
            val columnName = cursor.getString(1) // Column name is at index 1
            columns.add(columnName)
        }
        cursor.close()
        
        // Verify required columns exist
        val expectedColumns = setOf(
            "id",
            "user_id", 
            "amount",
            "currency",
            "category",
            "merchant",
            "notes",
            "transaction_date",
            "created_at",
            "updated_at",
            "source",
            "voice_transcript",
            "status",
            "is_recurring",
            "recurring_id"
        )
        
        assertThat(columns).containsAtLeastElementsIn(expectedColumns)
        db.close()
    }
    
    @Test
    fun `database can insert and query expense`() {
        val db = helper.createDatabase(TEST_DB, 1)
        
        // Insert test expense
        db.execSQL("""
            INSERT INTO expenses (
                id, user_id, amount, currency, category, transaction_date, 
                created_at, updated_at, source, status, is_recurring
            ) VALUES (
                'test-id', 'user-1', '25.50', 'USD', 'Food & Dining', 
                '2024-01-01T12:00:00', '2024-01-01T12:00:00', '2024-01-01T12:00:00',
                'manual', 'active', 0
            )
        """)
        
        // Query the expense
        val cursor = db.query("SELECT * FROM expenses WHERE id = 'test-id'")
        assertThat(cursor.moveToFirst()).isTrue()
        
        // Verify data
        val idIndex = cursor.getColumnIndex("id")
        val amountIndex = cursor.getColumnIndex("amount")
        val categoryIndex = cursor.getColumnIndex("category")
        
        assertThat(cursor.getString(idIndex)).isEqualTo("test-id")
        assertThat(cursor.getString(amountIndex)).isEqualTo("25.50")
        assertThat(cursor.getString(categoryIndex)).isEqualTo("Food & Dining")
        
        cursor.close()
        db.close()
    }
    
    @Test
    fun `database can be opened with Room after creation`() {
        // Create database with helper
        helper.createDatabase(TEST_DB, 1).close()
        
        // Open with Room
        val roomDb = Room.databaseBuilder(
            InstrumentationRegistry.getInstrumentation().targetContext,
            JustSpentDatabase::class.java,
            TEST_DB
        ).build()
        
        // Verify we can access DAOs
        val expenseDao = roomDb.expenseDao()
        assertThat(expenseDao).isNotNull()
        
        roomDb.close()
    }
    
    // Future migration tests would go here
    // Example:
    // @Test
    // fun migrate1To2() {
    //     var db = helper.createDatabase(TEST_DB, 1)
    //     // Insert data in version 1 format
    //     db.close()
    //     
    //     db = helper.runMigrationsAndValidate(TEST_DB, 2, true, MIGRATION_1_2)
    //     // Verify data migrated correctly
    //     db.close()
    // }
}