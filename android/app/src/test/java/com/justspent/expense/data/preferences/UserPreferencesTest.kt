package com.justspent.expense.data.preferences

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.google.common.truth.Truth.assertThat
import com.justspent.expense.data.model.Currency
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Unit tests for UserPreferences
 *
 * Tests verify:
 * - Onboarding completion and currency selection
 * - Default currency initialization from locale
 * - Onboarding state reset functionality
 * - Shared preferences persistence
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class UserPreferencesTest {

    private lateinit var context: Context
    private lateinit var userPreferences: UserPreferences

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
        userPreferences = UserPreferences(context)

        // Clear any existing preferences
        context.getSharedPreferences("user_prefs", Context.MODE_PRIVATE)
            .edit()
            .clear()
            .commit()
    }

    @Test
    fun `hasCompletedOnboarding returns false by default`() = runBlocking {
        val result = userPreferences.hasCompletedOnboarding.first()
        assertThat(result).isFalse()
    }

    @Test
    fun `defaultCurrency returns Currency default by default`() = runBlocking {
        val result = userPreferences.defaultCurrency.first()
        assertThat(result).isEqualTo(Currency.default)
    }

    @Test
    fun `completeOnboarding sets hasCompletedOnboarding to true`() = runBlocking {
        userPreferences.completeOnboarding(Currency.USD)

        val result = userPreferences.hasCompletedOnboarding.first()
        assertThat(result).isTrue()
    }

    @Test
    fun `completeOnboarding sets default currency`() = runBlocking {
        userPreferences.completeOnboarding(Currency.EUR)

        val result = userPreferences.defaultCurrency.first()
        assertThat(result).isEqualTo(Currency.EUR)
    }

    @Test
    fun `setDefaultCurrency updates default currency`() = runBlocking {
        userPreferences.setDefaultCurrency(Currency.GBP)

        val result = userPreferences.defaultCurrency.first()
        assertThat(result).isEqualTo(Currency.GBP)
    }

    @Test
    fun `initializeDefaultCurrency sets currency from locale when not set`() {
        val result = userPreferences.initializeDefaultCurrency()

        assertThat(result).isNotNull()
        assertThat(result).isEqualTo(Currency.default)
    }

    @Test
    fun `initializeDefaultCurrency returns existing currency when already set`() = runBlocking {
        // First set a currency
        userPreferences.setDefaultCurrency(Currency.SAR)

        // Then initialize (should return existing)
        val result = userPreferences.initializeDefaultCurrency()

        assertThat(result).isEqualTo(Currency.SAR)
    }

    @Test
    fun `resetOnboarding clears hasCompletedOnboarding flag`() = runBlocking {
        // Complete onboarding first
        userPreferences.completeOnboarding(Currency.INR)
        assertThat(userPreferences.hasCompletedOnboarding.first()).isTrue()

        // Reset onboarding
        userPreferences.resetOnboarding()

        // Verify flag is cleared
        val result = userPreferences.hasCompletedOnboarding.first()
        assertThat(result).isFalse()
    }

    @Test
    fun `resetOnboarding removes default currency preference`() = runBlocking {
        // Set a default currency
        userPreferences.setDefaultCurrency(Currency.AED)
        assertThat(userPreferences.defaultCurrency.first()).isEqualTo(Currency.AED)

        // Reset onboarding
        userPreferences.resetOnboarding()

        // Verify currency is reset to default
        val result = userPreferences.defaultCurrency.first()
        assertThat(result).isEqualTo(Currency.default)
    }

    @Test
    fun `resetOnboarding uses synchronous commit for immediate persistence`() = runBlocking {
        // Complete onboarding
        userPreferences.completeOnboarding(Currency.USD)

        // Reset onboarding
        userPreferences.resetOnboarding()

        // Immediately create new instance to verify persistence
        val newUserPreferences = UserPreferences(context)

        // Verify reset persisted synchronously
        val hasCompleted = newUserPreferences.hasCompletedOnboarding.first()
        assertThat(hasCompleted).isFalse()
    }

    @Test
    fun `preferences persist across UserPreferences instances`() = runBlocking {
        // Set preferences in first instance
        userPreferences.completeOnboarding(Currency.EUR)

        // Create new instance
        val newUserPreferences = UserPreferences(context)

        // Verify preferences persisted
        assertThat(newUserPreferences.hasCompletedOnboarding.first()).isTrue()
        assertThat(newUserPreferences.defaultCurrency.first()).isEqualTo(Currency.EUR)
    }
}
