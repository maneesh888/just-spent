package com.justspent.expense.ui.onboarding

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.google.common.truth.Truth.assertThat
import com.justspent.expense.utils.LocalizationManager
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Unit tests for CurrencyOnboardingScreen localization
 *
 * These tests verify that all localization keys used in the onboarding screen
 * are present in the shared localizations.json file and return non-empty values.
 *
 * This provides unit test coverage for the localization.get() calls in the UI.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class CurrencyOnboardingScreenLocalizationTest {

    private lateinit var context: Context
    private lateinit var localization: LocalizationManager

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
        localization = LocalizationManager.getInstance(context)
    }

    @Test
    fun `localization key onboarding_welcomeTitle returns non-empty value`() {
        val result = localization.get("onboarding.welcomeTitle")
        assertThat(result).isNotEmpty()
        assertThat(result).contains("Welcome")
    }

    @Test
    fun `localization key onboarding_welcomeSubtitle returns non-empty value`() {
        val result = localization.get("onboarding.welcomeSubtitle")
        assertThat(result).isNotEmpty()
        assertThat(result).contains("pre-selected")
    }

    @Test
    fun `localization key onboarding_helperText returns non-empty value`() {
        val result = localization.get("onboarding.helperText")
        assertThat(result).isNotEmpty()
        assertThat(result).contains("currency")
    }

    @Test
    fun `localization key onboarding_continueButton returns non-empty value`() {
        val result = localization.get("onboarding.continueButton")
        assertThat(result).isNotEmpty()
        assertThat(result).isEqualTo("Continue")
    }

    @Test
    fun `all onboarding localization keys return expected strings`() {
        // Verify all keys used in CurrencyOnboardingScreen.kt
        val welcomeTitle = localization.get("onboarding.welcomeTitle")
        val welcomeSubtitle = localization.get("onboarding.welcomeSubtitle")
        val helperText = localization.get("onboarding.helperText")
        val continueButton = localization.get("onboarding.continueButton")

        // Assert all are non-empty
        assertThat(welcomeTitle).isNotEmpty()
        assertThat(welcomeSubtitle).isNotEmpty()
        assertThat(helperText).isNotEmpty()
        assertThat(continueButton).isNotEmpty()

        // Assert expected content
        assertThat(welcomeTitle).isEqualTo("Welcome to Just Spent!")
        assertThat(welcomeSubtitle).contains("We've pre-selected your currency")
        assertThat(helperText).contains("You can choose a different currency")
        assertThat(continueButton).isEqualTo("Continue")
    }
}
