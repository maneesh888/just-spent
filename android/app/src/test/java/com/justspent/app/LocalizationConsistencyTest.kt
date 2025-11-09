package com.justspent.app

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.justspent.app.utils.LocalizationManager
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * LocalizationConsistencyTest
 *
 * Tests to ensure Android loads localizations correctly from shared JSON
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class LocalizationConsistencyTest {

    private lateinit var context: Context
    private lateinit var localizationManager: LocalizationManager

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
        localizationManager = LocalizationManager.getInstance(context)
    }

    // MARK: - JSON Loading Tests

    /**
     * Test 1: Verify JSON file loads successfully
     */
    @Test
    fun testJSONLoadsSuccessfully() {
        // Should not crash and should return valid strings
        assertFalse(localizationManager.appTitle.isEmpty())
        assertFalse(localizationManager.appTitle.startsWith("["))
    }

    /**
     * Test 2: Verify app strings match JSON
     */
    @Test
    fun testAppStringsMatchJSON() {
        assertEquals("Just Spent", localizationManager.appTitle)
        assertEquals("Voice-enabled expense tracker", localizationManager.appSubtitle)
        assertEquals("Total", localizationManager.appTotalLabel)
    }

    /**
     * Test 3: Verify empty state strings match JSON
     */
    @Test
    fun testEmptyStateStringsMatchJSON() {
        assertEquals("No Expenses Yet", localizationManager.emptyStateNoExpenses)
        // Platform-specific Android value
        assertEquals(
            "Tap the microphone button to add an expense",
            localizationManager.emptyStateTapVoiceButton
        )
    }

    /**
     * Test 4: Verify button strings match JSON
     */
    @Test
    fun testButtonStringsMatchJSON() {
        assertEquals("OK", localizationManager.buttonOK)
        assertEquals("Cancel", localizationManager.buttonCancel)
        assertEquals("Retry", localizationManager.buttonRetry)
    }

    /**
     * Test 5: Verify voice strings match JSON
     */
    @Test
    fun testVoiceStringsMatchJSON() {
        // Should use proper ellipsis character
        assertEquals("Listening…", localizationManager.voiceListening)
        assertEquals("Processing…", localizationManager.voiceProcessing)

        // Verify it's NOT three dots
        assertNotEquals("Listening...", localizationManager.voiceListening)
    }

    /**
     * Test 6: Verify all categories match JSON
     */
    @Test
    fun testCategoryStringsMatchJSON() {
        assertEquals("Food & Dining", localizationManager.categoryFoodDining)
        assertEquals("Grocery", localizationManager.categoryGrocery)
        assertEquals("Transportation", localizationManager.categoryTransportation)
        assertEquals("Shopping", localizationManager.categoryShopping)
        assertEquals("Entertainment", localizationManager.categoryEntertainment)
        assertEquals("Bills & Utilities", localizationManager.categoryBills)
        assertEquals("Healthcare", localizationManager.categoryHealthcare)
        assertEquals("Education", localizationManager.categoryEducation)
        assertEquals("Other", localizationManager.categoryOther)
        assertEquals("Unknown", localizationManager.categoryUnknown)
    }

    /**
     * Test 7: Verify platform-specific strings use Android values
     */
    @Test
    fun testPlatformSpecificStringsUseAndroidValues() {
        val voiceAssistantName = localizationManager.get("voiceAssistant.name")
        assertEquals("Assistant", voiceAssistantName)
        assertNotEquals("Siri", voiceAssistantName) // iOS value
    }

    /**
     * Test 8: Verify dot-notation path navigation works
     */
    @Test
    fun testDotNotationPathNavigation() {
        assertEquals("Just Spent", localizationManager.get("app.title"))
        assertEquals("OK", localizationManager.get("buttons.ok"))
        assertEquals("Food & Dining", localizationManager.get("categories.foodDining"))
    }

    /**
     * Test 9: Verify missing keys return bracketed key
     */
    @Test
    fun testMissingKeysReturnBracketedKey() {
        val missingKey = localizationManager.get("nonexistent.key")
        assertEquals("[nonexistent.key]", missingKey)
    }

    /**
     * Test 10: Verify no empty strings
     */
    @Test
    fun testNoEmptyStrings() {
        val strings = listOf(
            localizationManager.appTitle,
            localizationManager.appSubtitle,
            localizationManager.buttonOK,
            localizationManager.buttonCancel,
            localizationManager.categoryFoodDining,
            localizationManager.categoryGrocery
        )

        for (string in strings) {
            assertFalse("Found empty string", string.isEmpty())
            assertFalse("Found unresolved key: $string", string.startsWith("["))
        }
    }

    /**
     * Test 11: Cross-platform consistency documentation
     */
    @Test
    fun testDocumentedCrossPlatformDifferences() {
        // Document intentional platform differences
        data class Difference(
            val key: String,
            val ios: String,
            val android: String,
            val reason: String
        )

        val differences = listOf(
            Difference(
                key = "emptyState.tapVoiceButton",
                ios = "iOS: Tap the voice button below to get started",
                android = "Android: Tap the microphone button to add an expense",
                reason = "Different UI terminology"
            ),
            Difference(
                key = "voiceAssistant.name",
                ios = "iOS: Siri",
                android = "Android: Assistant",
                reason = "Platform-specific branding"
            )
        )

        println("\n=== Cross-Platform Differences ===")
        for (diff in differences) {
            println("\nKey: ${diff.key}")
            println("  ${diff.ios}")
            println("  ${diff.android}")
            println("  Reason: ${diff.reason}")
        }
        println("\n===================================\n")

        // Verify Android uses correct platform-specific values
        assertEquals(
            "Tap the microphone button to add an expense",
            localizationManager.get("emptyState.tapVoiceButton")
        )
        assertEquals("Assistant", localizationManager.get("voiceAssistant.name"))
    }
}
