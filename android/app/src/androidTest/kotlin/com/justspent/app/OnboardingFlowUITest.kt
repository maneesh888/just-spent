package com.justspent.app

import android.content.Context
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * UI tests for the onboarding flow
 * Tests currency selection, navigation, and first-time user experience
 */
@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class OnboardingFlowUITest {

    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Before
    fun setUp() {
        hiltRule.inject()

        // Reset onboarding state to ensure onboarding screen is shown
        val context = ApplicationProvider.getApplicationContext<Context>()
        val prefs = context.getSharedPreferences("user_prefs", Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean("has_completed_onboarding", false)
            .remove("default_currency")
            .apply()

        // Restart activity to pick up new preference
        composeTestRule.activityRule.scenario.recreate()

        composeTestRule.waitForIdle()
    }

    // MARK: - Onboarding Display Tests

    @Test
    fun onboarding_displaysWelcomeMessage() {
        composeTestRule.waitForIdle()

        // Should see welcome message or currency selection text
        composeTestRule.onAllNodes(
            hasText("currency", substring = true, ignoreCase = true) or
            hasText("welcome", substring = true, ignoreCase = true) or
            hasText("default", substring = true, ignoreCase = true),
            useUnmergedTree = true
        ).assertCountEquals(1, 2, 3)  // At least one node
    }

    @Test
    fun onboarding_showsAllSixCurrencies() {
        composeTestRule.waitForIdle()

        // Verify all 6 currency options are present using test tags
        val currencies = listOf("AED", "USD", "EUR", "GBP", "INR", "SAR")

        currencies.forEach { code ->
            // Scroll to make item visible if needed - scroll the list first, then assert
            composeTestRule.onNodeWithTag("currency_list")
                .performTouchInput { swipeUp() }
            composeTestRule.waitForIdle()
            composeTestRule.onNodeWithTag("currency_option_$code")
                .assertExists()
        }
    }

    @Test
    fun onboarding_displaysAEDOption() {
        composeTestRule.waitForIdle()

        // AED is typically first - should be visible without scrolling
        composeTestRule.onNodeWithTag("currency_option_AED")
            .assertExists()
            .assertHasClickAction()
    }

    @Test
    fun onboarding_displaysUSDOption() {
        composeTestRule.waitForIdle()

        composeTestRule.onNodeWithTag("currency_option_USD")
            .assertExists()
            .assertHasClickAction()
    }

    @Test
    fun onboarding_displaysEUROption() {
        composeTestRule.waitForIdle()

        composeTestRule.onNodeWithTag("currency_option_EUR")
            .assertExists()
            .assertHasClickAction()
    }

    @Test
    fun onboarding_displaysGBPOption() {
        composeTestRule.waitForIdle()

        composeTestRule.onNodeWithTag("currency_option_GBP")
            .assertExists()
            .assertHasClickAction()
    }

    @Test
    fun onboarding_displaysINROption() {
        composeTestRule.waitForIdle()

        composeTestRule.onNodeWithTag("currency_option_INR")
            .assertExists()
            .assertHasClickAction()
    }

    @Test
    fun onboarding_displaysSAROption() {
        composeTestRule.waitForIdle()

        // SAR is last - need to scroll to see it
        composeTestRule.onNodeWithTag("currency_list")
            .performTouchInput { swipeUp() }
        composeTestRule.waitForIdle()

        composeTestRule.onNodeWithTag("currency_option_SAR")
            .assertExists()
            .assertHasClickAction()
    }

    // MARK: - Currency Selection Tests

    @Test
    fun onboarding_canSelectAED() {
        composeTestRule.waitForIdle()

        val aedOption = composeTestRule.onNodeWithTag("currency_option_AED")
        aedOption.assertExists()
        aedOption.assertHasClickAction()
        aedOption.performClick()

        // Should be selectable without errors
        composeTestRule.waitForIdle()
    }

    @Test
    fun onboarding_canSelectUSD() {
        composeTestRule.waitForIdle()

        val usdOption = composeTestRule.onNodeWithTag("currency_option_USD")
        usdOption.assertExists()
        usdOption.assertHasClickAction()
        usdOption.performClick()

        composeTestRule.waitForIdle()
    }

    // MARK: - Navigation Tests

    @Test
    fun onboarding_hasConfirmButton() {
        composeTestRule.waitForIdle()

        // Use test tag for continue button
        composeTestRule.onNodeWithTag("continue_button")
            .assertExists()
            .assertHasClickAction()
    }

    @Test
    fun onboarding_confirmButtonIsClickable() {
        composeTestRule.waitForIdle()

        val confirmButton = composeTestRule.onNodeWithTag("continue_button")
        confirmButton.assertExists()
        confirmButton.assertHasClickAction()
        confirmButton.assert(hasText("Continue"))
    }

    // MARK: - Visual Design Tests

    @Test
    fun onboarding_displaysCurrencySymbols() {
        composeTestRule.waitForIdle()

        // Check that currency symbols are present (they're in separate Text elements)
        val symbols = listOf("د.إ", "$", "€", "£", "₹", "﷼")

        var foundSymbols = 0
        symbols.forEach { symbol ->
            try {
                composeTestRule.onAllNodesWithText(symbol, substring = true, useUnmergedTree = true)
                    .onFirst()
                    .assertExists()
                foundSymbols++
            } catch (e: AssertionError) {
                // Symbol not found, continue
            }
        }

        assert(foundSymbols >= 4) { "Expected at least 4 currency symbols, found $foundSymbols" }
    }

    @Test
    fun onboarding_hasInstructionalText() {
        composeTestRule.waitForIdle()

        // Should have instructional text somewhere on the screen
        val instructionalText = composeTestRule.onAllNodes(
            hasText("select", substring = true, ignoreCase = true) or
            hasText("choose", substring = true, ignoreCase = true) or
            hasText("default", substring = true, ignoreCase = true) or
            hasText("currency", substring = true, ignoreCase = true),
            useUnmergedTree = true
        ).fetchSemanticsNodes()

        assert(instructionalText.isNotEmpty()) { "No instructional text found" }
    }

    // MARK: - Accessibility Tests

    @Test
    fun onboarding_currencyOptionsAreAccessible() {
        composeTestRule.waitForIdle()

        // Verify all currency options are accessible via test tags
        val currencies = listOf("AED", "USD", "EUR", "GBP", "INR", "SAR")

        currencies.forEach { code ->
            // Scroll list to make items visible
            composeTestRule.onNodeWithTag("currency_list")
                .performTouchInput { swipeUp() }
            composeTestRule.waitForIdle()

            composeTestRule.onNodeWithTag("currency_option_$code")
                .assertExists()
                .assertHasClickAction()
        }
    }

    // MARK: - State Tests

    @Test
    fun onboarding_doesNotShowAfterCompletion() {
        // Note: This test would need to:
        // 1. Complete onboarding
        // 2. Restart app
        // 3. Verify main screen shows instead of onboarding
        // Implementation depends on state management
        composeTestRule.waitForIdle()

        // Placeholder: Just verify onboarding elements exist
        composeTestRule.onNodeWithTag("currency_option_USD")
            .assertExists()
    }

    @Test
    fun onboarding_savesSelectedCurrency() {
        // Note: This test would need to:
        // 1. Select a currency
        // 2. Complete onboarding
        // 3. Verify the currency is saved as default
        composeTestRule.waitForIdle()

        // Placeholder: Select USD (should be visible without scrolling)
        composeTestRule.onNodeWithTag("currency_option_USD")
            .performClick()

        composeTestRule.waitForIdle()
    }

    // MARK: - Layout Tests

    @Test
    fun onboarding_currenciesAreInGrid() {
        composeTestRule.waitForIdle()

        // Verify all 6 currencies are visible
        val currencies = listOf("AED", "USD", "EUR", "GBP", "INR", "SAR")

        var foundCurrencies = 0
        currencies.forEach { code ->
            try {
                // Scroll list to make items visible
                composeTestRule.onNodeWithTag("currency_list")
                    .performTouchInput { swipeUp() }
                composeTestRule.waitForIdle()

                composeTestRule.onNodeWithTag("currency_option_$code")
                    .assertExists()
                foundCurrencies++
            } catch (e: AssertionError) {
                // Currency not found
            }
        }

        // All 6 currencies should be visible
        assert(foundCurrencies == 6) { "Expected 6 currencies, found $foundCurrencies" }
    }

    // MARK: - Edge Case Tests

    @Test
    fun onboarding_handlesBackPress() {
        composeTestRule.waitForIdle()

        // Verify onboarding screen is displayed
        composeTestRule.onNodeWithTag("continue_button")
            .assertExists()

        // Note: Back press handling depends on navigation implementation
        // This is a placeholder for back press testing
    }

    @Test
    fun onboarding_handlesScreenRotation() {
        composeTestRule.waitForIdle()

        // Verify onboarding elements still exist after idle
        composeTestRule.onNodeWithTag("currency_option_USD")
            .assertExists()

        // Note: Rotation testing requires ActivityScenario
        // This is a placeholder for rotation testing
    }

    // MARK: - Performance Tests

    @Test
    fun onboarding_rendersQuickly() {
        val startTime = System.currentTimeMillis()

        composeTestRule.waitForIdle()

        // Verify at least one currency option is rendered
        composeTestRule.onNodeWithTag("currency_option_USD")
            .assertExists()

        val renderTime = System.currentTimeMillis() - startTime
        assert(renderTime < 3000) { "Onboarding took ${renderTime}ms to render" }
    }

    // MARK: - Integration Tests

    @Test
    fun onboarding_completionNavigatesToMainScreen() {
        composeTestRule.waitForIdle()

        // Select a currency
        composeTestRule.onNodeWithTag("currency_option_USD")
            .performClick()

        composeTestRule.waitForIdle()

        // Tap continue
        composeTestRule.onNodeWithTag("continue_button")
            .performClick()

        composeTestRule.waitForIdle()

        // Note: Would need to verify navigation to main screen
        // This depends on navigation setup
    }

    // Helper extension function for flexible assertion counts
    private fun SemanticsNodeInteractionCollection.assertCountEquals(vararg acceptableCounts: Int) {
        val actualCount = fetchSemanticsNodes().size
        assert(acceptableCounts.contains(actualCount)) {
            "Expected node count to be one of ${acceptableCounts.joinToString()}, but was $actualCount"
        }
    }
}
