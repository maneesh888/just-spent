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

    // MARK: - Comprehensive Voice Recognition Tests for All 36 Currencies

    @Test
    fun `detectCurrency finds JPY from yen keyword`() {
        val text = "I spent 1000 yen on sushi"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("JPY"))
    }

    @Test
    fun `detectCurrency finds JPY from symbol`() {
        val text = "paid ¥5000 for hotel"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("JPY"))
    }

    @Test
    fun `detectCurrency finds CNY from yuan keyword`() {
        val text = "I spent 500 yuan on shopping"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("CNY"))
    }

    @Test
    fun `detectCurrency finds CNY from renminbi keyword`() {
        val text = "paid 300 renminbi for dinner"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("CNY"))
    }

    @Test
    fun `detectCurrency finds CAD from canadian dollar keyword`() {
        val text = "I spent 75 canadian dollars"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("CAD"))
    }

    @Test
    fun `detectCurrency finds CAD from loonie keyword`() {
        val text = "that cost 20 loonies"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("CAD"))
    }

    @Test
    fun `detectCurrency finds AUD from australian dollar keyword`() {
        val text = "I paid 150 australian dollars"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("AUD"))
    }

    @Test
    fun `detectCurrency finds AUD from aussie dollar keyword`() {
        val text = "spent 50 aussie dollars"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("AUD"))
    }

    @Test
    fun `detectCurrency finds CHF from swiss franc keyword`() {
        val text = "I spent 100 swiss francs on watch"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("CHF"))
    }

    @Test
    fun `detectCurrency finds CHF from franc keyword with word boundary`() {
        val text = "paid 200 francs at Geneva"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("CHF"))
    }

    @Test
    fun `detectCurrency finds SEK from krona keyword`() {
        val text = "I spent 500 swedish krona"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("SEK"))
    }

    @Test
    fun `detectCurrency finds NOK from norwegian krone keyword`() {
        val text = "paid 400 norwegian krone"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("NOK"))
    }

    @Test
    fun `detectCurrency finds DKK from danish krone keyword`() {
        val text = "I spent 300 danish krone"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("DKK"))
    }

    @Test
    fun `detectCurrency finds NZD from new zealand dollar keyword`() {
        val text = "paid 80 new zealand dollars"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("NZD"))
    }

    @Test
    fun `detectCurrency finds NZD from kiwi dollar keyword`() {
        val text = "spent 50 kiwi dollars"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("NZD"))
    }

    @Test
    fun `detectCurrency finds SGD from singapore dollar keyword`() {
        val text = "I paid 120 singapore dollars"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("SGD"))
    }

    @Test
    fun `detectCurrency finds HKD from hong kong dollar keyword`() {
        val text = "spent 500 hong kong dollars"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("HKD"))
    }

    @Test
    fun `detectCurrency finds KRW from won keyword`() {
        val text = "I spent 50000 won in Seoul"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("KRW"))
    }

    @Test
    fun `detectCurrency finds KRW from korean won keyword`() {
        val text = "paid 25000 korean won"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("KRW"))
    }

    @Test
    fun `detectCurrency finds BRL from real keyword`() {
        val text = "I spent 200 reais on groceries"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("BRL"))
    }

    @Test
    fun `detectCurrency finds BRL from brazilian real keyword`() {
        val text = "paid 150 brazilian real"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("BRL"))
    }

    @Test
    fun `detectCurrency finds MXN from peso keyword`() {
        val text = "I spent 500 pesos in Mexico"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("MXN"))
    }

    @Test
    fun `detectCurrency finds MXN from mexican peso keyword`() {
        val text = "paid 300 mexican pesos"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("MXN"))
    }

    @Test
    fun `detectCurrency finds RUB from ruble keyword`() {
        val text = "I spent 5000 rubles in Moscow"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("RUB"))
    }

    @Test
    fun `detectCurrency finds RUB from rouble keyword`() {
        val text = "paid 3000 roubles for hotel"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("RUB"))
    }

    @Test
    fun `detectCurrency finds ZAR from rand keyword`() {
        val text = "I spent 800 rand in Cape Town"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("ZAR"))
    }

    @Test
    fun `detectCurrency finds ZAR from south african rand keyword`() {
        val text = "paid 500 south african rand"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("ZAR"))
    }

    @Test
    fun `detectCurrency finds THB from baht keyword`() {
        val text = "I spent 2000 baht in Bangkok"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("THB"))
    }

    @Test
    fun `detectCurrency finds MYR from ringgit keyword`() {
        val text = "paid 300 ringgit in Kuala Lumpur"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("MYR"))
    }

    @Test
    fun `detectCurrency finds IDR from rupiah keyword`() {
        val text = "I spent 500000 rupiah in Bali"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("IDR"))
    }

    @Test
    fun `detectCurrency finds PHP from philippine peso keyword`() {
        val text = "paid 2000 philippine pesos"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("PHP"))
    }

    @Test
    fun `detectCurrency finds VND from dong keyword`() {
        val text = "I spent 500000 dong in Hanoi"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("VND"))
    }

    @Test
    fun `detectCurrency finds TRY from lira keyword`() {
        val text = "I spent 500 liras in Istanbul"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("TRY"))
    }

    @Test
    fun `detectCurrency finds TRY from turkish lira keyword`() {
        val text = "paid 300 turkish lira"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("TRY"))
    }

    @Test
    fun `detectCurrency finds PLN from zloty keyword`() {
        val text = "I spent 400 zlotys in Warsaw"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("PLN"))
    }

    @Test
    fun `detectCurrency finds CZK from koruna keyword`() {
        val text = "paid 1000 korunas in Prague"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("CZK"))
    }

    @Test
    fun `detectCurrency finds CZK from crown keyword`() {
        val text = "I spent 500 crowns on dinner"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("CZK"))
    }

    @Test
    fun `detectCurrency finds HUF from forint keyword`() {
        val text = "paid 15000 forints in Budapest"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("HUF"))
    }

    @Test
    fun `detectCurrency finds RON from leu keyword`() {
        val text = "I spent 200 lei in Bucharest"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("RON"))
    }

    @Test
    fun `detectCurrency finds RON from romanian leu keyword`() {
        val text = "paid 150 romanian leu"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("RON"))
    }

    @Test
    fun `detectCurrency finds BHD from bahraini dinar keyword`() {
        val text = "I spent 50 bahraini dinars"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("BHD"))
    }

    @Test
    fun `detectCurrency finds KWD from kuwaiti dinar keyword`() {
        val text = "paid 30 kuwaiti dinars"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("KWD"))
    }

    @Test
    fun `detectCurrency finds OMR from omani rial keyword`() {
        val text = "I spent 40 omani rials"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("OMR"))
    }

    @Test
    fun `detectCurrency finds QAR from qatari riyal keyword`() {
        val text = "paid 200 qatari riyals"
        val result = VoiceCurrencyDetector.detectCurrency(text)
        assertThat(result).isEqualTo(Currency.fromCode("QAR"))
    }

    // MARK: - extractAmountAndCurrency Tests for All Currencies

    @Test
    fun `extractAmountAndCurrency handles all 36 currencies with keywords`() {
        // Given - Map of voice commands to expected currencies
        val testCases = mapOf(
            "spent 100 dirhams" to "AED",
            "paid 75 australian dollars" to "AUD",
            "50 bahraini dinars" to "BHD",
            "200 brazilian real" to "BRL",
            "80 canadian dollars" to "CAD",
            "150 swiss francs" to "CHF",
            "500 yuan" to "CNY",
            "1000 korunas" to "CZK",
            "300 danish krone" to "DKK",
            "75 euros" to "EUR",
            "45 pounds" to "GBP",
            "500 hong kong dollars" to "HKD",
            "15000 forints" to "HUF",
            "500000 rupiah" to "IDR",
            "500 rupees" to "INR",
            "1000 yen" to "JPY",
            "50000 won" to "KRW",
            "30 kuwaiti dinars" to "KWD",
            "500 mexican pesos" to "MXN",
            "300 ringgit" to "MYR",
            "400 norwegian krone" to "NOK",
            "80 new zealand dollars" to "NZD",
            "40 omani rials" to "OMR",
            "2000 philippine pesos" to "PHP",
            "400 zlotys" to "PLN",
            "200 qatari riyals" to "QAR",
            "200 romanian leu" to "RON",
            "5000 rubles" to "RUB",
            "100 saudi riyals" to "SAR",
            "500 swedish krona" to "SEK",
            "120 singapore dollars" to "SGD",
            "2000 baht" to "THB",
            "500 turkish lira" to "TRY",
            "50 dollars" to "USD",
            "500000 dong" to "VND",
            "800 south african rand" to "ZAR"
        )

        testCases.forEach { (text, expectedCode) ->
            // When
            val result = VoiceCurrencyDetector.extractAmountAndCurrency("I $text")

            // Then
            assertThat(result).isNotNull()
            assertThat(result?.second?.code).isEqualTo(expectedCode)
        }
    }

    // MARK: - Disambiguation Tests (Word Boundary Validation)

    @Test
    fun `detectCurrency distinguishes between similar currency keywords`() {
        // Test that word boundaries prevent false matches
        val testCases = mapOf(
            "I spent swiss francs" to "CHF",  // Not "franc" matching other currencies
            "paid in canadian dollars" to "CAD",  // Not "dollar" matching USD/AUD/etc
            "used indian rupees" to "INR",  // Not "rupee" matching IDR
            "bought with norwegian krone" to "NOK",  // Not "krone" matching DKK/SEK
            "paid bahraini dinars" to "BHD",  // Not "dinar" matching KWD
            "spent omani rials" to "OMR",  // Not "rial" matching QAR
            "used mexican pesos" to "MXN"  // Not "peso" matching PHP
        )

        testCases.forEach { (text, expectedCode) ->
            val result = VoiceCurrencyDetector.detectCurrency(text)
            assertThat(result?.code).isEqualTo(expectedCode)
        }
    }

    @Test
    fun `detectCurrency prioritizes longer keywords for specificity`() {
        // "swiss franc" should win over "franc" alone
        val text1 = "I spent 100 swiss francs"
        val result1 = VoiceCurrencyDetector.detectCurrency(text1)
        assertThat(result1?.code).isEqualTo("CHF")

        // "canadian dollar" should be detected correctly
        val text2 = "paid with canadian dollars"
        val result2 = VoiceCurrencyDetector.detectCurrency(text2)
        assertThat(result2?.code).isEqualTo("CAD")

        // "south african rand" should match completely
        val text3 = "used south african rand"
        val result3 = VoiceCurrencyDetector.detectCurrency(text3)
        assertThat(result3?.code).isEqualTo("ZAR")
    }

    @Test
    fun `detectCurrency prioritizes common currencies when ambiguous`() {
        // When multiple currencies match, common currencies (AED, USD, EUR, GBP, INR, SAR) should win
        val text = "I spent dollars"
        val result = VoiceCurrencyDetector.detectCurrency(text)

        // USD is common, so should be detected over AUD/CAD/HKD/SGD/NZD
        assertThat(result?.code).isEqualTo("USD")
    }
}
