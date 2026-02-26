package com.justspent.expense.data.database

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import android.content.Context
import com.justspent.expense.data.converters.BigDecimalConverter
import com.justspent.expense.data.converters.LocalDateTimeConverter
import com.justspent.expense.data.converters.StringListConverter
import com.justspent.expense.data.dao.ExpenseDao
import com.justspent.expense.data.model.Expense

@Database(
    entities = [Expense::class],
    version = 1,
    exportSchema = false
)
@TypeConverters(
    BigDecimalConverter::class,
    LocalDateTimeConverter::class,
    StringListConverter::class
)
abstract class JustSpentDatabase : RoomDatabase() {
    abstract fun expenseDao(): ExpenseDao
    
    companion object {
        @Volatile
        private var INSTANCE: JustSpentDatabase? = null
        
        fun getDatabase(context: Context): JustSpentDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    JustSpentDatabase::class.java,
                    "just_spent_database"
                )
                    .fallbackToDestructiveMigration() // For development only
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }
}