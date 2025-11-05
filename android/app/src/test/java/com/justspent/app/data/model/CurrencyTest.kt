package com.justspent.app.data.model

import com.google.common.truth.Truth.assertThat
import org.junit.Test

/**
 * Comprehensive unit tests for Currency model
 * Tests currency properties, detection, and utility functions
 */
class CurrencyTest {

    // MARK: - Currency Properties Tests

    @Test
    fun `AED has correct properties`() {
        // Given
        val currency = Currency.AED

        // Then
        assertThat(currency.code).isEqualTo("AED")
        assertThat(currency.symbol).isEqualTo("د.إ")
        assertThat(currency.displayName).isEqualTo("UAE Dirham")
        assertThat(currency.shortName).isEqualTo("Dirham")
        assertThat(currency.isRTL).isTrue()
        assertThat(currency.decimalPlaces).isEqualTo(2)
        assertThat(currency.decimalSeparator).isEqualTo(".")
        assertThat(currency.groupingSeparator).isEqualTo(",")
    }

    @Test
    fun `USD has correct properties`() {
        // Given
        val currency = Currency.USD

        // Then
        assertThat(currency.code).isEqualTo("USD")
        assertThat(currency.symbol).isEqualTo("$")
        assertThat(currency.displayName).isEqualTo("US Dollar")
        assertThat(currency.shortName).isEqualTo("Dollar")
        assertThat(currency.isRTL).isFalse()
        assertThat(currency.decimalPlaces).isEqualTo(2)
    }

    @Test
    fun `EUR has correct properties`() {
        // Given
        val currency = Currency.EUR

        // Then
        assertThat(currency.code).isEqualTo("EUR")
        assertThat(currency.symbol).isEqualTo("€")
        assertThat(currency.displayName).isEqualTo("Euro")
        assertThat(currency.isRTL).isFalse()
    }

    @Test
    fun `GBP has correct properties`() {
        // Given
        val currency = Currency.GBP

        // Then
        assertThat(currency.code).isEqualTo("GBP")
        assertThat(currency.symbol).isEqualTo("£")
        assertThat(currency.displayName).isEqualTo("British Pound")
        assertThat(currency.isRTL).isFalse()
    }

    @Test
    fun `INR has correct properties`() {
        // Given
        val currency = Currency.INR

        // Then
        assertThat(currency.code).isEqualTo("INR")
        assertThat(currency.symbol).isEqualTo("₹")
        assertThat(currency.displayName).isEqualTo("Indian Rupee")
        assertThat(currency.isRTL).isFalse()
    }

    @Test
    fun `SAR has correct properties`() {
        // Given
        val currency = Currency.SAR

        // Then
        assertThat(currency.code).isEqualTo("SAR")
        assertThat(currency.symbol).isEqualTo("ر.س")
        assertThat(currency.displayName).isEqualTo("Saudi Riyal")
        assertThat(currency.isRTL).isTrue()
    }

    // MARK: - RTL Detection Tests

    @Test
    fun `only AED and SAR are RTL currencies`() {
        // Given
        val rtlCurrencies = Currency.all.filter { it.isRTL }

        // Then
        assertThat(rtlCurrencies).containsExactly(Currency.AED, Currency.SAR)
    }

    @Test
    fun `Western currencies are not RTL`() {
        // Given
        val westernCurrencies = listOf(
            Currency.USD, Currency.EUR, Currency.GBP, Currency.INR
        )

        westernCurrencies.forEach { currency ->
            // Then
            assertThat(currency.isRTL).isFalse()
        }
    }

    // MARK: - Decimal Consistency Tests

    @Test
    fun `all currencies use dot as decimal separator`() {
        // Given
        Currency.all.forEach { currency ->
            // Then
            assertThat(currency.decimalSeparator).isEqualTo(".")
        }
    }

    @Test
    fun `all currencies use comma as grouping separator`() {
        // Given
        Currency.all.forEach { currency ->
            // Then
            assertThat(currency.groupingSeparator).isEqualTo(",")
        }
    }

    @Test
    fun `all currencies have 2 decimal places`() {
        // Given
        Currency.all.forEach { currency ->
            // Then
            assertThat(currency.decimalPlaces).isEqualTo(2)
        }
    }

    // MARK: - Voice Keywords Tests

    @Test
    fun `AED has comprehensive voice keywords`() {
        // Given
        val currency = Currency.AED

        // Then
        assertThat(currency.voiceKeywords).contains("dirham")
        assertThat(currency.voiceKeywords).contains("dirhams")
        assertThat(currency.voiceKeywords).contains("aed")
        assertThat(currency.voiceKeywords).contains("د.إ")
    }

    @Test
    fun `USD has comprehensive voice keywords`() {
        // Given
        val currency = Currency.USD

        // Then
        assertThat(currency.voiceKeywords).contains("dollar")
        assertThat(currency.voiceKeywords).contains("dollars")
        assertThat(currency.voiceKeywords).contains("usd")
        assertThat(currency.voiceKeywords).contains("$")
        assertThat(currency.voiceKeywords).contains("buck")
        assertThat(currency.voiceKeywords).contains("bucks")
    }

    @Test
    fun `GBP has comprehensive voice keywords`() {
        // Given
        val currency = Currency.GBP

        // Then
        assertThat(currency.voiceKeywords).contains("pound")
        assertThat(currency.voiceKeywords).contains("pounds")
        assertThat(currency.voiceKeywords).contains("gbp")
        assertThat(currency.voiceKeywords).contains("quid")
        assertThat(currency.voiceKeywords).contains("sterling")
    }

    // MARK: - All Currencies List Tests

    @Test
    fun `all contains exactly 6 currencies`() {
        // Given/When
        val count = Currency.all.size

        // Then
        assertThat(count).isEqualTo(6)
    }

    @Test
    fun `all contains expected currencies`() {
        // Given
        val expected = listOf(
            Currency.AED, Currency.USD, Currency.EUR,
            Currency.GBP, Currency.INR, Currency.SAR
        )

        // Then
        assertThat(Currency.all).containsExactlyElementsIn(expected)
    }

    // MARK: - fromCode Tests

    @Test
    fun `fromCode returns correct currency for uppercase code`() {
        // Given/When
        val result = Currency.fromCode("AED")

        // Then
        assertThat(result).isEqualTo(Currency.AED)
    }

    @Test
    fun `fromCode returns correct currency for lowercase code`() {
        // Given/When
        val result = Currency.fromCode("usd")

        // Then
        assertThat(result).isEqualTo(Currency.USD)
    }

    @Test
    fun `fromCode returns correct currency for mixed case code`() {
        // Given/When
        val result = Currency.fromCode("Eur")

        // Then
        assertThat(result).isEqualTo(Currency.EUR)
    }

    @Test
    fun `fromCode returns null for invalid code`() {
        // Given/When
        val result = Currency.fromCode("INVALID")

        // Then
        assertThat(result).isNull()
    }

    @Test
    fun `fromCode works for all supported currencies`() {
        // Given
        val codes = listOf("AED", "USD", "EUR", "GBP", "INR", "SAR")

        codes.forEach { code ->
            // When
            val result = Currency.fromCode(code)

            // Then
            assertThat(result).isNotNull()
            assertThat(result?.code).isEqualTo(code)
        }
    }

    // MARK: - detectFromText Tests

    @Test
    fun `detectFromText finds currency from dirham keyword`() {
        // Given
        val text = "I spent 100 dirhams on groceries"

        // When
        val result = Currency.detectFromText(text)

        // Then
        assertThat(result).isEqualTo(Currency.AED)
    }

    @Test
    fun `detectFromText finds currency from dollar keyword`() {
        // Given
        val text = "I paid 50 dollars at Starbucks"

        // When
        val result = Currency.detectFromText(text)

        // Then
        assertThat(result).isEqualTo(Currency.USD)
    }

    @Test
    fun `detectFromText finds currency from euro keyword`() {
        // Given
        val text = "I spent 75 euros on dinner"

        // When
        val result = Currency.detectFromText(text)

        // Then
        assertThat(result).isEqualTo(Currency.EUR)
    }

    @Test
    fun `detectFromText finds currency from pound keyword`() {
        // Given
        val text = "I paid 45 pounds for the ticket"

        // When
        val result = Currency.detectFromText(text)

        // Then
        assertThat(result).isEqualTo(Currency.GBP)
    }

    @Test
    fun `detectFromText finds currency from rupee keyword`() {
        // Given
        val text = "I spent 500 rupees on shopping"

        // When
        val result = Currency.detectFromText(text)

        // Then
        assertThat(result).isEqualTo(Currency.INR)
    }

    @Test
    fun `detectFromText finds currency from riyal keyword`() {
        // Given
        val text = "I paid 100 riyals for the service"

        // When
        val result = Currency.detectFromText(text)

        // Then
        assertThat(result).isEqualTo(Currency.SAR)
    }

    @Test
    fun `detectFromText finds currency from symbol`() {
        // Given
        val symbolTests = mapOf(
            "$100 for lunch" to Currency.USD,
            "€75 for dinner" to Currency.EUR,
            "£45 for the ticket" to Currency.GBP,
            "₹500 for shopping" to Currency.INR,
            "د.إ 100 for groceries" to Currency.AED,
            "﷼100 for the service" to Currency.SAR
        )

        symbolTests.forEach { (text, expected) ->
            // When
            val result = Currency.detectFromText(text)

            // Then
            assertThat(result).isEqualTo(expected)
        }
    }

    @Test
    fun `detectFromText is case insensitive`() {
        // Given
        val variations = listOf(
            "DOLLARS", "Dollars", "dollars", "DOLLars"
        )

        variations.forEach { variation ->
            // When
            val result = Currency.detectFromText("spent 100 $variation")

            // Then
            assertThat(result).isEqualTo(Currency.USD)
        }
    }

    @Test
    fun `detectFromText returns null when no currency found`() {
        // Given
        val text = "I spent 100 on groceries"

        // When
        val result = Currency.detectFromText(text)

        // Then
        assertThat(result).isNull()
    }

    @Test
    fun `detectFromText finds slang keywords`() {
        // Given
        val slangTests = mapOf(
            "that cost 20 bucks" to Currency.USD,
            "I paid 50 quid" to Currency.GBP
        )

        slangTests.forEach { (text, expected) ->
            // When
            val result = Currency.detectFromText(text)

            // Then
            assertThat(result).isEqualTo(expected)
        }
    }

    // MARK: - toString Tests

    @Test
    fun `toString returns symbol and code`() {
        // Given
        val currency = Currency.AED

        // When
        val result = currency.toString()

        // Then
        assertThat(result).isEqualTo("د.إ AED")
    }

    @Test
    fun `toString format consistent across currencies`() {
        // Given
        Currency.all.forEach { currency ->
            // When
            val result = currency.toString()

            // Then
            assertThat(result).contains(currency.symbol)
            assertThat(result).contains(currency.code)
        }
    }

    // MARK: - Equality Tests

    @Test
    fun `same currency equals itself`() {
        // Given
        val currency1 = Currency.AED
        val currency2 = Currency.AED

        // Then
        assertThat(currency1).isEqualTo(currency2)
        assertThat(currency1 == currency2).isTrue()
    }

    @Test
    fun `different currencies are not equal`() {
        // Given
        val currency1 = Currency.AED
        val currency2 = Currency.USD

        // Then
        assertThat(currency1).isNotEqualTo(currency2)
        assertThat(currency1.equals(currency2)).isFalse()
    }

    @Test
    fun `hashCode is consistent with equals`() {
        // Given
        val currency1 = Currency.AED
        val currency2 = Currency.AED
        val currency3 = Currency.USD

        // Then
        assertThat(currency1.hashCode()).isEqualTo(currency2.hashCode())
        assertThat(currency1.hashCode()).isNotEqualTo(currency3.hashCode())
    }

    // MARK: - Extension Function Tests

    @Test
    fun `toCurrency extension converts valid code`() {
        // Given
        val code = "USD"

        // When
        val result = code.toCurrency()

        // Then
        assertThat(result).isEqualTo(Currency.USD)
    }

    @Test
    fun `toCurrency extension returns null for invalid code`() {
        // Given
        val code = "INVALID"

        // When
        val result = code.toCurrency()

        // Then
        assertThat(result).isNull()
    }

    @Test
    fun `toCurrency extension is case insensitive`() {
        // Given
        val codes = listOf("aed", "AED", "Aed", "aEd")

        codes.forEach { code ->
            // When
            val result = code.toCurrency()

            // Then
            assertThat(result).isEqualTo(Currency.AED)
        }
    }

    // MARK: - Locale Tests

    @Test
    fun `AED has correct locale`() {
        // Given
        val currency = Currency.AED

        // When
        val locale = currency.locale

        // Then
        assertThat(locale.language).isEqualTo("ar")
        assertThat(locale.country).isEqualTo("AE")
    }

    @Test
    fun `USD has correct locale`() {
        // Given
        val currency = Currency.USD

        // When
        val locale = currency.locale

        // Then
        assertThat(locale.language).isEqualTo("en")
        assertThat(locale.country).isEqualTo("US")
    }

    @Test
    fun `all currencies have valid locales`() {
        // Given
        Currency.all.forEach { currency ->
            // When
            val locale = currency.locale

            // Then
            assertThat(locale.language).isNotEmpty()
            assertThat(locale.country).isNotEmpty()
        }
    }

    // MARK: - Real-world Scenario Tests

    @Test
    fun `can detect all 6 currencies from test data commands`() {
        // Given - From AddTestDataTest voice transcripts
        val voiceCommands = mapOf(
            "I spent 150 dirhams on groceries at Carrefour" to Currency.AED,
            "200 dirhams for gas" to Currency.AED,
            "45 dollars at McDonald's" to Currency.USD,
            "I spent 21 dollars on Uber" to Currency.USD,
            "65 euros at pharmacy" to Currency.EUR,
            "45 pounds for train" to Currency.GBP
        )

        voiceCommands.forEach { (command, expected) ->
            // When
            val result = Currency.detectFromText(command)

            // Then
            assertThat(result).isEqualTo(expected)
        }
    }

    @Test
    fun `handles edge case with compound currency names`() {
        // Given
        val compoundNames = mapOf(
            "US dollar" to Currency.USD,
            "British pound" to Currency.GBP,
            "Emirati dirham" to Currency.AED,
            "Saudi riyal" to Currency.SAR,
            "Indian rupee" to Currency.INR
        )

        compoundNames.forEach { (name, expected) ->
            // When
            val result = Currency.detectFromText("I spent 100 $name")

            // Then
            assertThat(result).isEqualTo(expected)
        }
    }

    @Test
    fun `default currency is not null`() {
        // When
        val defaultCurrency = Currency.default

        // Then
        assertThat(defaultCurrency).isNotNull()
        assertThat(Currency.all).contains(defaultCurrency)
    }
}
