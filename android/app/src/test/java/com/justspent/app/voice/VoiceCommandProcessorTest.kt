package com.justspent.app.voice

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.google.common.truth.Truth.assertThat
import com.justspent.app.data.model.Currency
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.util.Locale

/**
 * Unit tests for VoiceCommandProcessor
 * Tests voice command parsing with default currency support
 */
@RunWith(RobolectricTestRunner::class)
class VoiceCommandProcessorTest {

    private lateinit var processor: VoiceCommandProcessor

    @Before
    fun setup() {
        // Initialize currency system with test context
        val context = ApplicationProvider.getApplicationContext<Context>()
        Currency.initialize(context)

        processor = VoiceCommandProcessor()
    }

    // MARK: - Currency Detection with Default Currency

    @Test
    fun `processVoiceCommand uses INR when rupee symbol is detected`() {
        // Given
        val command = "I spent ₹20 for tea"
        val defaultCurrency = "AED"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), defaultCurrency)

        // Then
        assertThat(result.isSuccess).isTrue()
        result.onSuccess { expenseData ->
            assertThat(expenseData.currency).isEqualTo("INR")
            assertThat(expenseData.amount.toDouble()).isEqualTo(20.0)
            assertThat(expenseData.category).isEqualTo("Food & Dining")
        }
    }

    @Test
    fun `processVoiceCommand uses INR when rupees keyword is detected`() {
        // Given
        val command = "I spent 20 rupees for tea"
        val defaultCurrency = "USD"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), defaultCurrency)

        // Then
        assertThat(result.isSuccess).isTrue()
        result.onSuccess { expenseData ->
            assertThat(expenseData.currency).isEqualTo("INR")
            assertThat(expenseData.amount.toDouble()).isEqualTo(20.0)
        }
    }

    @Test
    fun `processVoiceCommand uses default currency when no currency specified`() {
        // Given
        val command = "I spent 20 for tea"
        val defaultCurrency = "INR"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), defaultCurrency)

        // Then
        assertThat(result.isSuccess).isTrue()
        result.onSuccess { expenseData ->
            assertThat(expenseData.currency).isEqualTo("INR")
            assertThat(expenseData.amount.toDouble()).isEqualTo(20.0)
        }
    }

    @Test
    fun `processVoiceCommand uses AED when dirham is detected even if default is USD`() {
        // Given
        val command = "I spent 50 dirhams for groceries"
        val defaultCurrency = "USD"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), defaultCurrency)

        // Then
        assertThat(result.isSuccess).isTrue()
        result.onSuccess { expenseData ->
            assertThat(expenseData.currency).isEqualTo("AED")
            assertThat(expenseData.amount.toDouble()).isEqualTo(50.0)
        }
    }

    @Test
    fun `processVoiceCommand uses USD when dollar is detected even if default is INR`() {
        // Given
        val command = "I spent 100 dollars for shopping"
        val defaultCurrency = "INR"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), defaultCurrency)

        // Then
        assertThat(result.isSuccess).isTrue()
        result.onSuccess { expenseData ->
            assertThat(expenseData.currency).isEqualTo("USD")
            assertThat(expenseData.amount.toDouble()).isEqualTo(100.0)
        }
    }

    @Test
    fun `processVoiceCommand uses EUR when euro symbol is detected`() {
        // Given
        val command = "I spent €75 for dinner"
        val defaultCurrency = "USD"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), defaultCurrency)

        // Then
        assertThat(result.isSuccess).isTrue()
        result.onSuccess { expenseData ->
            assertThat(expenseData.currency).isEqualTo("EUR")
            assertThat(expenseData.amount.toDouble()).isEqualTo(75.0)
        }
    }

    @Test
    fun `processVoiceCommand uses GBP when pounds keyword is detected`() {
        // Given
        val command = "I spent 45 pounds for tickets"
        val defaultCurrency = "USD"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), defaultCurrency)

        // Then
        assertThat(result.isSuccess).isTrue()
        result.onSuccess { expenseData ->
            assertThat(expenseData.currency).isEqualTo("GBP")
            assertThat(expenseData.amount.toDouble()).isEqualTo(45.0)
        }
    }

    @Test
    fun `processVoiceCommand uses SAR when riyals keyword is detected`() {
        // Given
        val command = "I spent 100 riyals for transportation"
        val defaultCurrency = "USD"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), defaultCurrency)

        // Then
        assertThat(result.isSuccess).isTrue()
        result.onSuccess { expenseData ->
            assertThat(expenseData.currency).isEqualTo("SAR")
            assertThat(expenseData.amount.toDouble()).isEqualTo(100.0)
        }
    }

    // MARK: - Category Detection

    @Test
    fun `processVoiceCommand detects tea as Food & Dining category`() {
        // Given
        val command = "I spent 20 rupees for tea"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), "INR")

        // Then
        assertThat(result.isSuccess).isTrue()
        result.onSuccess { expenseData ->
            assertThat(expenseData.category).isEqualTo("Food & Dining")
        }
    }

    @Test
    fun `processVoiceCommand detects grocery category`() {
        // Given
        val command = "I spent 150 dirhams for groceries"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), "AED")

        // Then
        assertThat(result.isSuccess).isTrue()
        result.onSuccess { expenseData ->
            assertThat(expenseData.category).isEqualTo("Grocery")
        }
    }

    // MARK: - Amount Extraction

    @Test
    fun `processVoiceCommand extracts decimal amounts`() {
        // Given
        val command = "I spent 25.50 dollars for lunch"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), "USD")

        // Then
        assertThat(result.isSuccess).isTrue()
        result.onSuccess { expenseData ->
            assertThat(expenseData.amount.toDouble()).isEqualTo(25.50)
        }
    }

    @Test
    fun `processVoiceCommand extracts whole number amounts`() {
        // Given
        val command = "I spent 100 euros for shopping"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), "EUR")

        // Then
        assertThat(result.isSuccess).isTrue()
        result.onSuccess { expenseData ->
            assertThat(expenseData.amount.toDouble()).isEqualTo(100.0)
        }
    }

    // MARK: - Edge Cases

    @Test
    fun `processVoiceCommand fails with missing amount`() {
        // Given
        val command = "I spent some money for tea"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), "INR")

        // Then
        assertThat(result.isFailure).isTrue()
    }

    @Test
    fun `processVoiceCommand fails with invalid amount`() {
        // Given
        val command = "I spent abc dollars for lunch"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), "USD")

        // Then
        assertThat(result.isFailure).isTrue()
    }

    @Test
    fun `processVoiceCommand fails with amount exceeding maximum`() {
        // Given
        val command = "I spent 10000000 dollars for shopping"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), "USD")

        // Then
        assertThat(result.isFailure).isTrue()
    }

    // MARK: - User Reported Issue Test Cases

    @Test
    fun `ISSUE_FIX - user selects INR and says rupee symbol, expense should be in INR not USD`() {
        // Given - User selected INR as default currency
        val userDefaultCurrency = "INR"
        val command = "I spent ₹20 for a tea"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), userDefaultCurrency)

        // Then - Should detect INR from rupee symbol, NOT fall back to USD
        assertThat(result.isSuccess).isTrue()
        result.onSuccess { expenseData ->
            assertThat(expenseData.currency).isEqualTo("INR")
            assertThat(expenseData.currency).isNotEqualTo("USD")
            assertThat(expenseData.amount.toDouble()).isEqualTo(20.0)
            assertThat(expenseData.category).isEqualTo("Food & Dining")
        }
    }

    @Test
    fun `ISSUE_FIX - user selects AED but no currency in voice, should use AED as default`() {
        // Given - User selected AED as default currency
        val userDefaultCurrency = "AED"
        val command = "I spent 50 for groceries"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), userDefaultCurrency)

        // Then - Should use user's default (AED), not USD
        assertThat(result.isSuccess).isTrue()
        result.onSuccess { expenseData ->
            assertThat(expenseData.currency).isEqualTo("AED")
            assertThat(expenseData.currency).isNotEqualTo("USD")
            assertThat(expenseData.amount.toDouble()).isEqualTo(50.0)
        }
    }

    @Test
    fun `ISSUE_FIX - user selects INR but says dollars, should create USD expense in different list`() {
        // Given - User selected INR as default but explicitly says dollars
        val userDefaultCurrency = "INR"
        val command = "I spent 100 dollars for shopping"

        // When
        val result = processor.processVoiceCommand(command, Locale.getDefault(), userDefaultCurrency)

        // Then - Should detect USD from voice, ignoring default INR
        assertThat(result.isSuccess).isTrue()
        result.onSuccess { expenseData ->
            assertThat(expenseData.currency).isEqualTo("USD")
            assertThat(expenseData.currency).isNotEqualTo("INR")
            assertThat(expenseData.amount.toDouble()).isEqualTo(100.0)
            // This will create a new currency tab since it's different from default
        }
    }
}
