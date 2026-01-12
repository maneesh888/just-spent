package com.justspent.expense.di

import com.justspent.expense.data.repository.ExpenseRepository
import com.justspent.expense.data.repository.ExpenseRepositoryInterface
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