package com.justspent.app.data.preferences

import android.content.Context
import android.content.SharedPreferences
import com.justspent.app.data.model.Currency
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * User preferences manager for Just Spent app
 * Handles onboarding state and default currency selection
 */
@Singleton
class UserPreferences @Inject constructor(
    @ApplicationContext context: Context
) {
    private val prefs: SharedPreferences = context.getSharedPreferences(
        PREFS_NAME,
        Context.MODE_PRIVATE
    )

    private val _hasCompletedOnboarding = MutableStateFlow(
        prefs.getBoolean(KEY_HAS_COMPLETED_ONBOARDING, false)
    )
    val hasCompletedOnboarding: StateFlow<Boolean> = _hasCompletedOnboarding.asStateFlow()

    private val _defaultCurrency = MutableStateFlow(
        Currency.fromCode(prefs.getString(KEY_DEFAULT_CURRENCY, Currency.default.code) ?: Currency.default.code)
            ?: Currency.default
    )
    val defaultCurrency: StateFlow<Currency> = _defaultCurrency.asStateFlow()

    /**
     * Complete onboarding and save default currency
     */
    fun completeOnboarding(defaultCurrency: Currency) {
        prefs.edit()
            .putBoolean(KEY_HAS_COMPLETED_ONBOARDING, true)
            .putString(KEY_DEFAULT_CURRENCY, defaultCurrency.code)
            .apply()

        _hasCompletedOnboarding.value = true
        _defaultCurrency.value = defaultCurrency
    }

    /**
     * Set default currency (can be changed after onboarding)
     */
    fun setDefaultCurrency(currency: Currency) {
        prefs.edit()
            .putString(KEY_DEFAULT_CURRENCY, currency.code)
            .apply()

        _defaultCurrency.value = currency
    }

    /**
     * Initialize default currency based on device locale if not already set.
     * This ensures the app ALWAYS has a default currency, making modules independent.
     *
     * Should be called on app launch before checking onboarding state.
     *
     * @return The initialized or existing default currency
     */
    fun initializeDefaultCurrency(): Currency {
        val existingCurrency = prefs.getString(KEY_DEFAULT_CURRENCY, null)

        if (existingCurrency == null) {
            // No default currency set - detect from device locale
            val localeCurrency = Currency.default // Already implements locale detection

            prefs.edit()
                .putString(KEY_DEFAULT_CURRENCY, localeCurrency.code)
                .apply()

            _defaultCurrency.value = localeCurrency

            android.util.Log.d(TAG, "Initialized default currency from locale: ${localeCurrency.code}")
            return localeCurrency
        }

        // Default currency already set - return existing
        val currency = Currency.fromCode(existingCurrency) ?: Currency.default
        android.util.Log.d(TAG, "Using existing default currency: ${currency.code}")
        return currency
    }

    /**
     * Reset onboarding state (for testing)
     */
    fun resetOnboarding() {
        prefs.edit()
            .putBoolean(KEY_HAS_COMPLETED_ONBOARDING, false)
            .remove(KEY_DEFAULT_CURRENCY)
            .apply()

        _hasCompletedOnboarding.value = false
        _defaultCurrency.value = Currency.default
    }

    companion object {
        private const val PREFS_NAME = "user_prefs"
        private const val KEY_HAS_COMPLETED_ONBOARDING = "has_completed_onboarding"
        private const val KEY_DEFAULT_CURRENCY = "default_currency"
        private const val TAG = "UserPreferences"
    }
}
