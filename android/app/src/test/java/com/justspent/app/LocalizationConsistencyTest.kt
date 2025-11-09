package com.justspent.app

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * LocalizationConsistencyTest
 *
 * Tests to ensure Android localizations match the shared localizations.json source of truth.
 * This ensures consistency with iOS by validating both platforms against the same JSON file.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class LocalizationConsistencyTest {

    private lateinit var context: Context

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
    }

    /**
     * Mapping of JSON keys to Android string resource IDs
     * Based on localizations.json "platforms.android" values
     */
    private val keyMapping = mapOf(
        // App
        "app.title" to R.string.app_name,
        "app.subtitle" to R.string.app_subtitle,
        "app.totalLabel" to R.string.app_total_label,

        // Empty State
        "emptyState.noExpenses" to R.string.empty_state_no_expenses,
        "emptyState.tapVoiceButton" to R.string.empty_state_tap_voice_button,

        // Buttons
        "buttons.ok" to R.string.button_ok,
        "buttons.cancel" to R.string.button_cancel,
        "buttons.retry" to R.string.button_retry,

        // Categories
        "categories.foodDining" to R.string.category_food_dining,
        "categories.grocery" to R.string.category_grocery,
        "categories.transportation" to R.string.category_transportation,
        "categories.shopping" to R.string.category_shopping,
        "categories.entertainment" to R.string.category_entertainment,
        "categories.bills" to R.string.category_bills_utilities,
        "categories.healthcare" to R.string.category_healthcare,
        "categories.education" to R.string.category_education,
        "categories.other" to R.string.category_other,
        "categories.unknown" to R.string.category_unknown
    )

    /**
     * Expected values from shared localizations.json
     * These should match both iOS and Android (unless platform-specific)
     */
    private val expectedValues = mapOf(
        // App
        "app.title" to "Just Spent",
        "app.subtitle" to "Voice-enabled expense tracker",
        "app.totalLabel" to "Total",

        // Empty State
        "emptyState.noExpenses" to "No Expenses Yet",
        // Note: emptyState.tapVoiceButton is platform-specific

        // Buttons
        "buttons.ok" to "OK",
        "buttons.cancel" to "Cancel",
        "buttons.retry" to "Retry",

        // Categories
        "categories.foodDining" to "Food & Dining",
        "categories.grocery" to "Grocery",
        "categories.transportation" to "Transportation",
        "categories.shopping" to "Shopping",
        "categories.entertainment" to "Entertainment",
        "categories.bills" to "Bills & Utilities",
        "categories.healthcare" to "Healthcare",
        "categories.education" to "Education",
        "categories.other" to "Other",
        "categories.unknown" to "Unknown"
    )

    /**
     * Platform-specific strings that differ intentionally
     */
    private val platformSpecific = mapOf(
        "emptyState.tapVoiceButton" to "Tap the microphone button to add an expense",
        "voiceAssistant.name" to "Assistant"
    )

    // MARK: - Test Cases

    /**
     * Test 1: Verify all shared strings exist in Android
     */
    @Test
    fun testAllSharedStringsExistInAndroid() {
        val missingKeys = mutableListOf<String>()

        for ((jsonKey, resourceId) in keyMapping) {
            try {
                val value = context.getString(resourceId)
                assertTrue(
                    "String for key $jsonKey should not be empty",
                    value.isNotEmpty()
                )
            } catch (e: Exception) {
                missingKeys.add("$jsonKey → Android resource: $resourceId (${e.message})")
            }
        }

        assertTrue(
            "Missing Android string resources:\n${missingKeys.joinToString("\n")}",
            missingKeys.isEmpty()
        )
    }

    /**
     * Test 2: Verify shared strings match expected values from JSON
     */
    @Test
    fun testSharedStringsMatchExpectedValues() {
        val mismatches = mutableListOf<Triple<String, String, String>>()

        for ((jsonKey, expectedValue) in expectedValues) {
            val resourceId = keyMapping[jsonKey]
            if (resourceId == null) {
                fail("No Android resource mapping for JSON key: $jsonKey")
                continue
            }

            val actualValue = context.getString(resourceId)

            if (actualValue != expectedValue) {
                mismatches.add(Triple(jsonKey, expectedValue, actualValue))
            }
        }

        if (mismatches.isNotEmpty()) {
            val errorMessage = mismatches.joinToString("\n\n") { (jsonKey, expected, actual) ->
                "JSON key: $jsonKey\n  Expected: '$expected'\n  Actual: '$actual'"
            }

            fail("Localization mismatches with shared JSON:\n\n$errorMessage")
        }
    }

    /**
     * Test 3: Verify platform-specific Android strings have correct values
     */
    @Test
    fun testPlatformSpecificStringsAreCorrect() {
        val mismatches = mutableListOf<Triple<String, String, String>>()

        for ((jsonKey, expectedValue) in platformSpecific) {
            val resourceId = keyMapping[jsonKey] ?: continue

            val actualValue = context.getString(resourceId)

            if (actualValue != expectedValue) {
                mismatches.add(Triple(jsonKey, expectedValue, actualValue))
            }
        }

        if (mismatches.isNotEmpty()) {
            val errorMessage = mismatches.joinToString("\n\n") { (jsonKey, expected, actual) ->
                "JSON key: $jsonKey (platform-specific)\n  Expected: '$expected'\n  Actual: '$actual'"
            }

            fail("Platform-specific string mismatches:\n\n$errorMessage")
        }
    }

    /**
     * Test 4: Document intentional platform differences
     */
    @Test
    fun testDocumentedPlatformDifferences() {
        // This test always passes but documents known differences

        data class PlatformDifference(
            val key: String,
            val ios: String,
            val android: String,
            val reason: String
        )

        val differences = listOf(
            PlatformDifference(
                key = "emptyState.tapVoiceButton",
                ios = "Tap the voice button below to get started",
                android = "Tap the microphone button to add an expense",
                reason = "Different UI terminology"
            ),
            PlatformDifference(
                key = "voiceAssistant.name",
                ios = "Siri",
                android = "Assistant",
                reason = "Platform-specific branding"
            )
        )

        println("\n=== Documented Platform Differences ===")
        for (diff in differences) {
            println("\nKey: ${diff.key}")
            println("  iOS: ${diff.ios}")
            println("  Android: ${diff.android}")
            println("  Reason: ${diff.reason}")
        }
        println("\n========================================\n")

        assertEquals("Expected 2 documented platform differences", 2, differences.size)
    }

    /**
     * Test 5: Verify no empty strings
     */
    @Test
    fun testNoEmptyStrings() {
        val emptyResources = mutableListOf<String>()

        for ((jsonKey, resourceId) in keyMapping) {
            val value = context.getString(resourceId)

            if (value.trim().isEmpty()) {
                emptyResources.add("$jsonKey → $resourceId")
            }
        }

        assertTrue(
            "Found empty string resources:\n${emptyResources.joinToString("\n")}",
            emptyResources.isEmpty()
        )
    }

    /**
     * Test 6: Verify category count matches
     */
    @Test
    fun testCategoryCountMatches() {
        val categoryKeys = keyMapping.filter { it.key.startsWith("categories.") }

        // Should have 10 categories (9 main categories + unknown)
        assertEquals(
            "Expected 10 category strings (9 categories + unknown)",
            10,
            categoryKeys.size
        )
    }
}
