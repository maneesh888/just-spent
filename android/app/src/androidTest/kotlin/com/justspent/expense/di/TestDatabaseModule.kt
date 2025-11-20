package com.justspent.expense.di

import android.content.Context
import androidx.room.Room
import com.justspent.expense.data.database.JustSpentDatabase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import dagger.hilt.testing.TestInstallIn
import javax.inject.Singleton

/**
 * Test database module for instrumentation tests
 * Replaces the production DatabaseModule with in-memory database for testing
 */
@Module
@TestInstallIn(
    components = [SingletonComponent::class],
    replaces = [DatabaseModule::class]
)
object TestDatabaseModule {

    @Provides
    @Singleton
    fun provideTestDatabase(
        @ApplicationContext context: Context
    ): JustSpentDatabase {
        return Room.inMemoryDatabaseBuilder(
            context,
            JustSpentDatabase::class.java
        )
            .allowMainThreadQueries() // Allow main thread queries for tests
            .build()
    }

    @Provides
    @Singleton
    fun provideExpenseDao(database: JustSpentDatabase) = database.expenseDao()
}
