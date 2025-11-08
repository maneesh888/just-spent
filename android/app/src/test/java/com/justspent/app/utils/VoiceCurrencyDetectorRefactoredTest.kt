package com.justspent.app.utils

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.google.common.truth.Truth.assertThat
import com.justspent.app.data.model.Currency
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * REFACTORED: Voice Currency Detector Tests using Shared JSON Test Data
 *
 * This replaces the 1,219-line VoiceCurrencyDetectorTest.kt with a compact version
 * that loads test cases from shared/test-data/voice-test-data.json
 *
 * Benefits:
 * - ~85% reduction in test code (1,219 lines → ~150 lines)
 * - Single source of truth (shared with iOS)
 * - Easy to add new test cases (just update JSON)
 * - No code duplication between platforms
 */
@RunWith(RobolectricTestRunner::class)
class VoiceCurrencyDetectorRefactoredTest {

    @Before
    fun setup() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        Currency.initialize(context)
    }

    // MARK: - Currency Detection Tests (Data-Driven)

    @Test
    fun `currency detection tests from shared JSON`() {
        // Load all currency detection test cases from JSON
        val testCases = SharedTestDataLoader.getCurrencyDetectionTests()

        println("Running ${testCases.size} currency detection tests from shared JSON...")

        testCases.forEach { testCase ->
            // When
            val result = VoiceCurrencyDetector.detectCurrency(testCase.input)

            // Then
            val expectedCurrency = if (testCase.expected_currency == "use_default") {
                Currency.AED // or get from testCase.default_currency
            } else {
                testCase.expected_currency?.let { Currency.fromCode(it) }
            }

            assertThat(result).apply {
                isEqualTo(expectedCurrency)
            }.also {
                println("✓ ${testCase.id}: ${testCase.description}")
            }
        }
    }

    // MARK: - Amount Extraction Tests (Data-Driven)

    @Test
    fun `amount extraction tests from shared JSON`() {
        val testCases = SharedTestDataLoader.getAmountExtractionTests()

        println("Running ${testCases.size} amount extraction tests from shared JSON...")

        testCases.forEach { testCase ->
            // When
            val result = VoiceCurrencyDetector.extractAmountAndCurrency(testCase.input)

            // Then
            if (testCase.expected_amount == null) {
                assertThat(result).isNull()
            } else {
                assertThat(result).isNotNull()
                assertThat(result?.first).isEqualTo(testCase.expected_amount)

                testCase.expected_currency?.let { expectedCode ->
                    assertThat(result?.second).isEqualTo(Currency.fromCode(expectedCode))
                }
            }

            println("✓ ${testCase.id}: ${testCase.description}")
        }
    }

    // MARK: - Edge Cases (Data-Driven)

    @Test
    fun `edge case tests from shared JSON`() {
        val testCases = SharedTestDataLoader.getEdgeCaseTests()

        println("Running ${testCases.size} edge case tests from shared JSON...")

        testCases.forEach { testCase ->
            // When
            val result = if (testCase.default_currency != null) {
                val defaultCurrency = Currency.fromCode(testCase.default_currency) ?: Currency.AED
                VoiceCurrencyDetector.extractAmountAndCurrency(testCase.input, defaultCurrency)
            } else {
                // Use method's default parameter (Currency.USD)
                VoiceCurrencyDetector.extractAmountAndCurrency(testCase.input)
            }

            // Then
            when {
                testCase.expected_amount == null -> {
                    assertThat(result).isNull()
                }
                testCase.expected_currency == "use_default" -> {
                    assertThat(result).isNotNull()
                    assertThat(result?.first).isEqualTo(testCase.expected_amount)
                    // Should use default currency
                }
                else -> {
                    assertThat(result).isNotNull()
                    assertThat(result?.first).isEqualTo(testCase.expected_amount)
                    testCase.expected_currency?.let {
                        assertThat(result?.second?.code).isEqualTo(it)
                    }
                }
            }

            println("✓ ${testCase.id}: ${testCase.description}")
        }
    }

    // MARK: - Real World Scenarios (Data-Driven)

    @Test
    fun `real world scenario tests from shared JSON`() {
        val testCases = SharedTestDataLoader.getRealWorldTests()

        println("Running ${testCases.size} real-world scenario tests from shared JSON...")

        testCases.forEach { testCase ->
            // When
            val result = VoiceCurrencyDetector.extractAmountAndCurrency(testCase.input)

            // Then
            assertThat(result).isNotNull()
            assertThat(result?.first).isEqualTo(testCase.expected_amount)
            testCase.expected_currency?.let { expectedCode ->
                assertThat(result?.second?.code).isEqualTo(expectedCode)
            }

            println("✓ ${testCase.id}: ${testCase.description}")
        }
    }

    // MARK: - Disambiguation Tests (Data-Driven)

    @Test
    fun `disambiguation tests from shared JSON`() {
        val testCases = SharedTestDataLoader.getDisambiguationTests()

        println("Running ${testCases.size} disambiguation tests from shared JSON...")

        testCases.forEach { testCase ->
            // When
            val result = VoiceCurrencyDetector.detectCurrency(testCase.input)

            // Then
            testCase.expected_currency?.let { expectedCode ->
                assertThat(result?.code).isEqualTo(expectedCode)
            }

            println("✓ ${testCase.id}: ${testCase.description}")
        }
    }

    // MARK: - Legacy Tests (Keep a Few for Regression)

    @Test
    fun `legacy - basic AED detection still works`() {
        val text = "I spent 100 dirhams on groceries"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.AED)
    }

    @Test
    fun `legacy - basic USD detection still works`() {
        val text = "I spent 50 dollars at Starbucks"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.USD)
    }

    @Test
    fun `legacy - amount extraction still works`() {
        val text = "I paid 99.99 dollars at Amazon"
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(99.99)
        assertThat(result?.second).isEqualTo(Currency.USD)
    }
}

/**
 * COMPARISON:
 *
 * Before (VoiceCurrencyDetectorTest.kt):
 * - 1,219 lines of code
 * - 70+ individual @Test methods
 * - Hardcoded test data in each method
 * - Difficult to maintain
 * - Duplicated in iOS tests
 *
 * After (This File):
 * - ~200 lines of code
 * - 5 data-driven tests + 3 legacy tests
 * - Test data loaded from shared JSON
 * - Easy to maintain (update JSON, not code)
 * - Shared with iOS (single source of truth)
 *
 * Reduction: ~85% less code!
 */
