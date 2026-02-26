package com.justspent.expense.di

import android.content.Context
import androidx.room.Room
import com.justspent.expense.data.dao.ExpenseDao
import com.justspent.expense.data.database.JustSpentDatabase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {
    
    @Provides
    @Singleton
    fun provideJustSpentDatabase(@ApplicationContext context: Context): JustSpentDatabase {
        return Room.databaseBuilder(
            context.applicationContext,
            JustSpentDatabase::class.java,
            "just_spent_database"
        )
            .fallbackToDestructiveMigration() // Remove in production
            .build()
    }
    
    @Provides
    fun provideExpenseDao(database: JustSpentDatabase): ExpenseDao {
        return database.expenseDao()
    }
}