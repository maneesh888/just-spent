package com.justspent.expense.ui.preferences

import androidx.lifecycle.ViewModel
import com.justspent.expense.data.preferences.UserPreferences
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject
import com.justspent.expense.data.model.Currency

/**
 * ViewModel wrapper for UserPreferences to provide easy access in Compose
 */
@HiltViewModel
class UserPreferencesViewModel @Inject constructor(
    private val userPreferences: UserPreferences
) : ViewModel() {

    val hasCompletedOnboarding: StateFlow<Boolean> = userPreferences.hasCompletedOnboarding
    val defaultCurrency: StateFlow<Currency> = userPreferences.defaultCurrency

    fun completeOnboarding(defaultCurrency: Currency) {
        userPreferences.completeOnboarding(defaultCurrency)
    }

    fun setDefaultCurrency(currency: Currency) {
        userPreferences.setDefaultCurrency(currency)
    }

    fun initializeDefaultCurrency(): Currency {
        return userPreferences.initializeDefaultCurrency()
    }

    fun resetOnboarding() {
        userPreferences.resetOnboarding()
    }
}
