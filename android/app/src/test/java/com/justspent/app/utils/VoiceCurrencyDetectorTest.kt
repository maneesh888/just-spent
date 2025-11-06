package com.justspent.app.utils

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.google.common.truth.Truth.assertThat
import com.justspent.app.data.model.Currency
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Comprehensive unit tests for VoiceCurrencyDetector
 * Tests voice command parsing, currency detection, and amount extraction
 *
 * Robolectric configuration is in src/test/resources/robolectric.properties
 * which ensures proper access to assets folder for currency JSON loading
 */
@RunWith(RobolectricTestRunner::class)
class VoiceCurrencyDetectorTest {

    @Before
    fun setup() {
        // Initialize currency system with test context
        // This loads currencies from src/main/assets/currencies.json
        val context = ApplicationProvider.getApplicationContext<Context>()
        Currency.initialize(context)
    }

    // MARK: - Currency Detection Tests

    @Test
    fun `detectCurrency finds AED from dirham keyword`() {
        // Given
        val text = "I spent 100 dirhams on groceries"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.AED)
    }

    @Test
    fun `detectCurrency finds AED from dirhams plural`() {
        // Given
        val text = "paid 50 dirhams for taxi"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.AED)
    }

    @Test
    fun `detectCurrency finds AED from Arabic symbol`() {
        // Given
        val text = "spent د.إ 100 at the mall"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.AED)
    }

    @Test
    fun `detectCurrency finds AED from code`() {
        // Given
        val text = "AED 100 for shopping"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.AED)
    }

    @Test
    fun `detectCurrency finds USD from dollar keyword`() {
        // Given
        val text = "spent 50 dollars at Starbucks"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.USD)
    }

    @Test
    fun `detectCurrency finds USD from dollars plural`() {
        // Given
        val text = "paid 100 dollars for dinner"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.USD)
    }

    @Test
    fun `detectCurrency finds USD from symbol`() {
        // Given
        val text = "spent $50 on lunch"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.USD)
    }

    @Test
    fun `detectCurrency finds USD from buck slang`() {
        // Given
        val text = "that cost me 20 bucks"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.USD)
    }

    @Test
    fun `detectCurrency finds EUR from euro keyword`() {
        // Given
        val text = "I paid 75 euros for the ticket"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.EUR)
    }

    @Test
    fun `detectCurrency finds EUR from symbol`() {
        // Given
        val text = "spent €50 at the restaurant"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.EUR)
    }

    @Test
    fun `detectCurrency finds GBP from pound keyword`() {
        // Given
        val text = "I spent 45 pounds on groceries"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.GBP)
    }

    @Test
    fun `detectCurrency finds GBP from quid slang`() {
        // Given
        val text = "that'll be 20 quid"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.GBP)
    }

    @Test
    fun `detectCurrency finds GBP from symbol`() {
        // Given
        val text = "spent £100 at Marks and Spencer"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.GBP)
    }

    @Test
    fun `detectCurrency finds INR from rupee keyword`() {
        // Given
        val text = "I paid 500 rupees for the ride"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.INR)
    }

    @Test
    fun `detectCurrency finds INR from symbol`() {
        // Given
        val text = "spent ₹500 on groceries"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.INR)
    }

    @Test
    fun `detectCurrency finds INR from symbol with no space`() {
        // Given
        val text = "I just spent ₹20"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.INR)
    }

    @Test
    fun `detectCurrency finds INR from Rs abbreviation`() {
        // Given
        val text = "I spent Rs 500 on groceries"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.INR)
    }

    @Test
    fun `detectCurrency finds INR from alternative rupee symbol`() {
        // Given
        val text = "I spent ₨500 on groceries"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.INR)
    }

    @Test
    fun `detectCurrency finds SAR from riyal keyword`() {
        // Given
        val text = "I spent 100 riyals at the mall"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.SAR)
    }

    @Test
    fun `detectCurrency finds SAR from symbol`() {
        // Given
        val text = "paid ﷼100 for the service"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.SAR)
    }

    @Test
    fun `detectCurrency returns default when no currency found`() {
        // Given
        val text = "I spent 100 on groceries"
        val defaultCurrency = Currency.AED

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text, defaultCurrency)

        // Then
        assertThat(result).isEqualTo(Currency.AED)
    }

    @Test
    fun `detectCurrency is case insensitive`() {
        // Given
        val variations = listOf(
            "DOLLARS", "Dollars", "dollars", "DOLLars"
        )

        variations.forEach { variation ->
            // When
            val result = VoiceCurrencyDetector.detectCurrency("spent 100 $variation")

            // Then
            assertThat(result).isEqualTo(Currency.USD)
        }
    }

    // MARK: - Extract Amount and Currency Tests

    @Test
    fun `extractAmountAndCurrency parses amount before currency`() {
        // Given
        val text = "I spent 150 dirhams on groceries"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(150.0)
        assertThat(result?.second).isEqualTo(Currency.AED)
    }

    @Test
    fun `extractAmountAndCurrency parses decimal amounts`() {
        // Given
        val text = "I paid 99.99 dollars at Amazon"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(99.99)
        assertThat(result?.second).isEqualTo(Currency.USD)
    }

    @Test
    fun `extractAmountAndCurrency parses currency before amount`() {
        // Given
        val text = "I spent $50 on coffee"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(50.0)
        assertThat(result?.second).isEqualTo(Currency.USD)
    }

    @Test
    fun `extractAmountAndCurrency parses amount with dirham keyword`() {
        // Given
        val text = "spent 100 dirhams at Carrefour"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(100.0)
        assertThat(result?.second).isEqualTo(Currency.AED)
    }

    @Test
    fun `extractAmountAndCurrency handles amount with no currency using default`() {
        // Given
        val text = "I spent 50 on groceries"
        val defaultCurrency = Currency.AED

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text, defaultCurrency)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(50.0)
        assertThat(result?.second).isEqualTo(Currency.AED)
    }

    @Test
    fun `extractAmountAndCurrency handles EUR with keyword`() {
        // Given
        val text = "I paid 78.50 euros for dinner"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(78.50)
        assertThat(result?.second).isEqualTo(Currency.EUR)
    }

    @Test
    fun `extractAmountAndCurrency handles GBP with keyword`() {
        // Given
        val text = "spent 45.00 pounds at the train station"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(45.0)
        assertThat(result?.second).isEqualTo(Currency.GBP)
    }

    @Test
    fun `extractAmountAndCurrency handles INR with keyword`() {
        // Given
        val text = "I paid 500 rupees for the service"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(500.0)
        assertThat(result?.second).isEqualTo(Currency.INR)
    }

    @Test
    fun `extractAmountAndCurrency handles rupee symbol with no space`() {
        // Given
        val text = "I just spent ₹20"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(20.0)
        assertThat(result?.second).isEqualTo(Currency.INR)
    }

    @Test
    fun `extractAmountAndCurrency handles Rs abbreviation`() {
        // Given
        val text = "I spent Rs 500 on groceries"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(500.0)
        assertThat(result?.second).isEqualTo(Currency.INR)
    }

    @Test
    fun `extractAmountAndCurrency handles alternative rupee symbol`() {
        // Given
        val text = "I paid ₨250 for taxi"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(250.0)
        assertThat(result?.second).isEqualTo(Currency.INR)
    }

    @Test
    fun `extractAmountAndCurrency handles small decimal amounts`() {
        // Given
        val text = "that's 5.50 dollars"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(5.50)
        assertThat(result?.second).isEqualTo(Currency.USD)
    }

    @Test
    fun `extractAmountAndCurrency handles large amounts`() {
        // Given
        val text = "I paid 1234.56 euros for the laptop"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(1234.56)
        assertThat(result?.second).isEqualTo(Currency.EUR)
    }

    @Test
    fun `extractAmountAndCurrency returns null for text with no amount`() {
        // Given
        val text = "I spent some money on groceries"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNull()
    }

    @Test
    fun `extractAmountAndCurrency handles zero amount`() {
        // Given
        val text = "I spent 0 dollars"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(0.0)
        assertThat(result?.second).isEqualTo(Currency.USD)
    }

    // MARK: - Contains Currency Tests

    @Test
    fun `containsCurrency returns true when currency is present`() {
        // Given
        val texts = listOf(
            "spent 100 dirhams",
            "paid $50 for lunch",
            "€75 for the ticket",
            "100 rupees for groceries"
        )

        texts.forEach { text ->
            // When
            val result = VoiceCurrencyDetector.containsCurrency(text)

            // Then
            assertThat(result).isTrue()
        }
    }

    @Test
    fun `containsCurrency returns false when no currency present`() {
        // Given
        val text = "I spent 100 on groceries"

        // When
        val result = VoiceCurrencyDetector.containsCurrency(text)

        // Then
        assertThat(result).isFalse()
    }

    // MARK: - Normalize Currency Symbols Tests

    @Test
    fun `normalizeCurrencySymbols replaces AED symbol with code`() {
        // Given
        val text = "I spent د.إ 100 on groceries"

        // When
        val result = VoiceCurrencyDetector.normalizeCurrencySymbols(text)

        // Then
        assertThat(result).isEqualTo("I spent AED 100 on groceries")
    }

    @Test
    fun `normalizeCurrencySymbols replaces USD symbol with code`() {
        // Given
        val text = "I paid $50 for lunch"

        // When
        val result = VoiceCurrencyDetector.normalizeCurrencySymbols(text)

        // Then
        assertThat(result).isEqualTo("I paid USD50 for lunch")
    }

    @Test
    fun `normalizeCurrencySymbols replaces EUR symbol with code`() {
        // Given
        val text = "spent €75 at the restaurant"

        // When
        val result = VoiceCurrencyDetector.normalizeCurrencySymbols(text)

        // Then
        assertThat(result).isEqualTo("spent EUR75 at the restaurant")
    }

    @Test
    fun `normalizeCurrencySymbols replaces GBP symbol with code`() {
        // Given
        val text = "paid £45 for the ticket"

        // When
        val result = VoiceCurrencyDetector.normalizeCurrencySymbols(text)

        // Then
        assertThat(result).isEqualTo("paid GBP45 for the ticket")
    }

    @Test
    fun `normalizeCurrencySymbols replaces INR symbol with code`() {
        // Given
        val text = "spent ₹500 on shopping"

        // When
        val result = VoiceCurrencyDetector.normalizeCurrencySymbols(text)

        // Then
        assertThat(result).isEqualTo("spent INR500 on shopping")
    }

    @Test
    fun `normalizeCurrencySymbols handles multiple symbols`() {
        // Given
        val text = "I have $100 and €50"

        // When
        val result = VoiceCurrencyDetector.normalizeCurrencySymbols(text)

        // Then
        assertThat(result).isEqualTo("I have USD100 and EUR50")
    }

    @Test
    fun `normalizeCurrencySymbols leaves text unchanged when no symbols`() {
        // Given
        val text = "I spent 100 on groceries"

        // When
        val result = VoiceCurrencyDetector.normalizeCurrencySymbols(text)

        // Then
        assertThat(result).isEqualTo(text)
    }

    // MARK: - Real-world Voice Command Tests

    @Test
    fun `handles typical voice command - basic AED expense`() {
        // Given
        val text = "I just spent 150 dirhams on groceries at Carrefour"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(150.0)
        assertThat(result?.second).isEqualTo(Currency.AED)
    }

    @Test
    fun `handles typical voice command - USD with merchant`() {
        // Given
        val text = "I spent 45 dollars at McDonald's"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(45.0)
        assertThat(result?.second).isEqualTo(Currency.USD)
    }

    @Test
    fun `handles typical voice command - EUR with category`() {
        // Given
        val text = "paid 65 euros at pharmacy for medication"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(65.0)
        assertThat(result?.second).isEqualTo(Currency.EUR)
    }

    @Test
    fun `handles typical voice command - dirhams keyword`() {
        // Given
        val text = "spent 200 dirhams for gas at ENOC"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(200.0)
        assertThat(result?.second).isEqualTo(Currency.AED)
    }

    @Test
    fun `handles typical voice command - complex with decimal`() {
        // Given
        val text = "I just spent 130 dirhams and 50 fils at VOX Cinemas"

        // When - Note: Voice might say "130 dirhams and 50 fils" instead of 130.50
        // This test checks if we can at least extract the main amount
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(130.0) // Gets first number
        assertThat(result?.second).isEqualTo(Currency.AED)
    }

    // MARK: - Edge Case Tests

    @Test
    fun `handles empty string`() {
        // Given
        val text = ""

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNull()
    }

    @Test
    fun `handles whitespace only`() {
        // Given
        val text = "   "

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNull()
    }

    @Test
    fun `handles amount with leading zeros`() {
        // Given
        val text = "spent 050 dollars"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(50.0)
    }

    @Test
    fun `handles amount with trailing zeros`() {
        // Given
        val text = "spent 50.00 dollars"

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.first).isEqualTo(50.0)
    }

    @Test
    fun `detectCurrency handles compound currency names`() {
        // Given
        val text = "I spent 100 US dollars"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.USD)
    }

    @Test
    fun `detectCurrency handles british pound variation`() {
        // Given
        val text = "I spent 45 british pounds"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.GBP)
    }

    @Test
    fun `detectCurrency handles emirati dirham variation`() {
        // Given
        val text = "I spent 100 emirati dirhams"

        // When
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // Then
        assertThat(result).isEqualTo(Currency.AED)
    }

    @Test
    fun `extractAmountAndCurrency prioritizes explicit currency over default`() {
        // Given
        val text = "I spent 50 euros on dinner"
        val defaultCurrency = Currency.USD

        // When
        val result = VoiceCurrencyDetector.extractAmountAndCurrency(text, defaultCurrency)

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.second).isEqualTo(Currency.EUR) // Should use EUR, not default USD
    }
}
