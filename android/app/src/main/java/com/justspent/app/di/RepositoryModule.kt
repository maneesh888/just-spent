package com.justspent.app.di

import com.justspent.app.data.repository.ExpenseRepository
import com.justspent.app.data.repository.ExpenseRepositoryInterface
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    
    @Binds
    @Singleton
    abstract fun bindExpenseRepository(
        expenseRepository: ExpenseRepository
    ): ExpenseRepositoryInterface
}