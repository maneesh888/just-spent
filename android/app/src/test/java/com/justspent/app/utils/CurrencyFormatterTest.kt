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
import java.math.BigDecimal

/**
 * Comprehensive unit tests for CurrencyFormatter
 * Tests formatting, parsing, and edge cases for all supported currencies
 *
 * Robolectric configuration is in src/test/resources/robolectric.properties
 * which ensures proper access to assets folder for currency JSON loading
 */
@RunWith(RobolectricTestRunner::class)
class CurrencyFormatterTest {

    @Before
    fun setup() {
        // Initialize currency system with test context
        // This loads currencies from src/main/assets/currencies.json
        val context = ApplicationProvider.getApplicationContext<Context>()
        Currency.initialize(context)
    }

    // MARK: - AED Formatting Tests

    @Test
    fun `formatAED with symbol shows correct format`() {
        // Given
        val amount = BigDecimal("1234.56")
        val currency = Currency.AED

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = true)

        // Then
        assertThat(result).isEqualTo("د.إ 1,234.56")
    }

    @Test
    fun `formatAED without symbol shows correct format`() {
        // Given
        val amount = BigDecimal("1234.56")
        val currency = Currency.AED

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = false)

        // Then
        assertThat(result).isEqualTo("1,234.56")
    }

    @Test
    fun `formatAED with code shows correct format`() {
        // Given
        val amount = BigDecimal("1234.56")
        val currency = Currency.AED

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = true, showCode = true)

        // Then
        assertThat(result).isEqualTo("د.إ 1,234.56 (AED)")
    }

    // MARK: - USD Formatting Tests

    @Test
    fun `formatUSD with symbol shows correct format`() {
        // Given
        val amount = BigDecimal("1234.56")
        val currency = Currency.USD

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = true)

        // Then
        assertThat(result).isEqualTo("$1,234.56")
    }

    @Test
    fun `formatUSD without grouping for small amount`() {
        // Given
        val amount = BigDecimal("50.00")
        val currency = Currency.USD

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = true)

        // Then
        assertThat(result).isEqualTo("$50.00")
    }

    // MARK: - EUR Formatting Tests

    @Test
    fun `formatEUR with symbol shows correct format`() {
        // Given
        val amount = BigDecimal("1234.56")
        val currency = Currency.EUR

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = true)

        // Then
        assertThat(result).isEqualTo("1,234.56€")
    }

    // MARK: - GBP Formatting Tests

    @Test
    fun `formatGBP with symbol shows correct format`() {
        // Given
        val amount = BigDecimal("1234.56")
        val currency = Currency.GBP

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = true)

        // Then
        assertThat(result).isEqualTo("£1,234.56")
    }

    // MARK: - INR Formatting Tests

    @Test
    fun `formatINR with symbol shows correct format`() {
        // Given
        val amount = BigDecimal("1234.56")
        val currency = Currency.INR

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = true)

        // Then
        assertThat(result).isEqualTo("₹1,234.56")
    }

    // MARK: - SAR Formatting Tests

    @Test
    fun `formatSAR with symbol shows correct format`() {
        // Given
        val amount = BigDecimal("1234.56")
        val currency = Currency.SAR

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = true)

        // Then
        assertThat(result).isEqualTo("ر.س 1,234.56")
    }

    // MARK: - Decimal Places Tests

    @Test
    fun `format always shows 2 decimal places`() {
        // Given
        val currencies = listOf(
            Currency.AED, Currency.USD, Currency.EUR,
            Currency.GBP, Currency.INR, Currency.SAR
        )
        val amount = BigDecimal("100")

        currencies.forEach { currency ->
            // When
            val result = CurrencyFormatter.format(amount, currency, showSymbol = false)

            // Then
            assertThat(result).endsWith(".00")
        }
    }

    @Test
    fun `format rounds to 2 decimal places`() {
        // Given
        val amount = BigDecimal("100.999")
        val currency = Currency.USD

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = false)

        // Then
        assertThat(result).isEqualTo("101.00")
    }

    @Test
    fun `format handles very small amounts`() {
        // Given
        val amount = BigDecimal("0.01")
        val currency = Currency.USD

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = true)

        // Then
        assertThat(result).isEqualTo("$0.01")
    }

    // MARK: - Large Number Tests

    @Test
    fun `format handles millions with proper grouping`() {
        // Given
        val amount = BigDecimal("1234567.89")
        val currency = Currency.USD

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = false)

        // Then
        assertThat(result).isEqualTo("1,234,567.89")
    }

    @Test
    fun `format handles billions with proper grouping`() {
        // Given
        val amount = BigDecimal("9876543210.12")
        val currency = Currency.AED

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = false)

        // Then
        assertThat(result).isEqualTo("9,876,543,210.12")
    }

    // MARK: - Zero and Negative Tests

    @Test
    fun `format handles zero correctly`() {
        // Given
        val amount = BigDecimal.ZERO
        val currency = Currency.USD

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = true)

        // Then
        assertThat(result).isEqualTo("$0.00")
    }

    @Test
    fun `format handles negative amounts`() {
        // Given
        val amount = BigDecimal("-100.50")
        val currency = Currency.USD

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = true)

        // Then
        assertThat(result).contains("-")
        assertThat(result).contains("100.50")
    }

    // MARK: - Compact Format Tests

    @Test
    fun `formatCompact uses symbol without code`() {
        // Given
        val amount = BigDecimal("150.00")
        val currency = Currency.AED

        // When
        val result = CurrencyFormatter.formatCompact(amount, currency)

        // Then
        assertThat(result).isEqualTo("د.إ 150.00")
        assertThat(result).doesNotContain("AED")
    }

    // MARK: - Detailed Format Tests

    @Test
    fun `formatDetailed includes both symbol and code`() {
        // Given
        val amount = BigDecimal("150.00")
        val currency = Currency.AED

        // When
        val result = CurrencyFormatter.formatDetailed(amount, currency)

        // Then
        assertThat(result).contains("د.إ")
        assertThat(result).contains("AED")
        assertThat(result).contains("150.00")
    }

    // MARK: - Parse Tests

    @Test
    fun `parse extracts amount from AED formatted string`() {
        // Given
        val formattedString = "د.إ 1,234.56"
        val currency = Currency.AED

        // When
        val result = CurrencyFormatter.parse(formattedString, currency)

        // Then
        assertThat(result).isEqualTo(BigDecimal("1234.56"))
    }

    @Test
    fun `parse extracts amount from USD formatted string`() {
        // Given
        val formattedString = "$1,234.56"
        val currency = Currency.USD

        // When
        val result = CurrencyFormatter.parse(formattedString, currency)

        // Then
        assertThat(result).isEqualTo(BigDecimal("1234.56"))
    }

    @Test
    fun `parse handles string without symbol`() {
        // Given
        val formattedString = "1,234.56"
        val currency = Currency.USD

        // When
        val result = CurrencyFormatter.parse(formattedString, currency)

        // Then
        assertThat(result).isEqualTo(BigDecimal("1234.56"))
    }

    @Test
    fun `parse returns null for invalid string`() {
        // Given
        val invalidString = "invalid amount"
        val currency = Currency.USD

        // When
        val result = CurrencyFormatter.parse(invalidString, currency)

        // Then
        assertThat(result).isNull()
    }

    @Test
    fun `parse handles EUR symbol after amount`() {
        // Given
        val formattedString = "1,234.56€"
        val currency = Currency.EUR

        // When
        val result = CurrencyFormatter.parse(formattedString, currency)

        // Then
        assertThat(result).isEqualTo(BigDecimal("1234.56"))
    }

    // MARK: - Extension Function Tests

    @Test
    fun `BigDecimal formatted extension works correctly`() {
        // Given
        val amount = BigDecimal("100.00")
        val currency = Currency.USD

        // When
        val result = amount.formatted(currency)

        // Then
        assertThat(result).isEqualTo("$100.00")
    }

    @Test
    fun `BigDecimal formattedCompact extension works correctly`() {
        // Given
        val amount = BigDecimal("100.00")
        val currency = Currency.AED

        // When
        val result = amount.formattedCompact(currency)

        // Then
        assertThat(result).isEqualTo("د.إ 100.00")
    }

    @Test
    fun `BigDecimal formattedDetailed extension works correctly`() {
        // Given
        val amount = BigDecimal("100.00")
        val currency = Currency.USD

        // When
        val result = amount.formattedDetailed(currency)

        // Then
        assertThat(result).contains("$100.00")
        assertThat(result).contains("USD")
    }

    @Test
    fun `String parsedAsCurrency extension works correctly`() {
        // Given
        val formattedString = "$100.00"
        val currency = Currency.USD

        // When
        val result = formattedString.parsedAsCurrency(currency)

        // Then
        assertThat(result).isEqualTo(BigDecimal("100.00"))
    }

    // MARK: - Consistency Tests

    @Test
    fun `all currencies use dot as decimal separator`() {
        // Given
        val amount = BigDecimal("1234.56")
        val currencies = listOf(
            Currency.AED, Currency.USD, Currency.EUR,
            Currency.GBP, Currency.INR, Currency.SAR
        )

        currencies.forEach { currency ->
            // When
            val result = CurrencyFormatter.format(amount, currency, showSymbol = false)

            // Then
            assertThat(result).contains(".")
            assertThat(result).doesNotContain(",34") // Ensures comma is grouping, not decimal
        }
    }

    @Test
    fun `all currencies use comma for thousands grouping`() {
        // Given
        val amount = BigDecimal("1234.56")
        val currencies = listOf(
            Currency.AED, Currency.USD, Currency.EUR,
            Currency.GBP, Currency.INR, Currency.SAR
        )

        currencies.forEach { currency ->
            // When
            val result = CurrencyFormatter.format(amount, currency, showSymbol = false)

            // Then
            assertThat(result).contains("1,234.56")
        }
    }

    @Test
    fun `format and parse are symmetric`() {
        // Given
        val originalAmount = BigDecimal("1234.56")
        val currencies = listOf(
            Currency.AED, Currency.USD, Currency.EUR,
            Currency.GBP, Currency.INR, Currency.SAR
        )

        currencies.forEach { currency ->
            // When
            val formatted = CurrencyFormatter.format(originalAmount, currency, showSymbol = true)
            val parsed = CurrencyFormatter.parse(formatted, currency)

            // Then
            assertThat(parsed).isEqualTo(originalAmount)
        }
    }

    // MARK: - Edge Case Tests

    @Test
    fun `format handles very large numbers`() {
        // Given
        val amount = BigDecimal("999999999999.99")
        val currency = Currency.USD

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = false)

        // Then
        assertThat(result).isEqualTo("999,999,999,999.99")
    }

    @Test
    fun `format handles fractional cents correctly`() {
        // Given
        val amount = BigDecimal("100.505") // Should round to 100.51
        val currency = Currency.USD

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = false)

        // Then
        assertThat(result).isEqualTo("100.51")
    }

    @Test
    fun `format handles banker's rounding midpoint`() {
        // Given
        val amount = BigDecimal("100.125") // Midpoint - should round up to 100.13
        val currency = Currency.USD

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = false)

        // Then
        assertThat(result).isEqualTo("100.13")
    }

    // MARK: - Real-world Scenario Tests

    @Test
    fun `format matches UI design spec for AED total`() {
        // Given - From UI design spec example
        val amount = BigDecimal("400.00")
        val currency = Currency.AED

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = true)

        // Then
        assertThat(result).isEqualTo("د.إ 400.00")
    }

    @Test
    fun `format matches UI design spec for USD total`() {
        // Given - From UI design spec example
        val amount = BigDecimal("144.99")
        val currency = Currency.USD

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = true)

        // Then
        assertThat(result).isEqualTo("$144.99")
    }

    @Test
    fun `formatCompact suitable for expense row display`() {
        // Given - Typical expense row amounts
        val amounts = listOf(
            BigDecimal("150.00"),
            BigDecimal("50.00"),
            BigDecimal("200.00")
        )
        val currency = Currency.AED

        amounts.forEach { amount ->
            // When
            val result = CurrencyFormatter.formatCompact(amount, currency)

            // Then
            assertThat(result).startsWith("د.إ")
            assertThat(result).doesNotContain("AED") // Compact = no code
            assertThat(result).matches("""د\.إ \d{1,3}(,\d{3})*\.\d{2}""")
        }
    }

    @Test
    fun `parse handles whitespace variations`() {
        // Given
        val variations = listOf(
            "$100.00",
            "$ 100.00",
            "$  100.00",
            "  $100.00  "
        )
        val currency = Currency.USD

        variations.forEach { variation ->
            // When
            val result = CurrencyFormatter.parse(variation, currency)

            // Then
            assertThat(result).isEqualTo(BigDecimal("100.00"))
        }
    }

    // MARK: - All 36 Currencies Formatting Tests

    @Test
    fun `format works correctly for all 36 supported currencies`() {
        // Given - Test amount
        val amount = BigDecimal("1234.56")

        // Map of currency codes to expected formatted outputs (with symbol)
        val expectedFormats = mapOf(
            "AED" to "د.إ 1,234.56",
            "AUD" to "$1,234.56",
            "BHD" to ".د.ب 1,234.56",
            "BRL" to "R$1,234.56",
            "CAD" to "$1,234.56",
            "CHF" to "CHF 1,234.56",
            "CNY" to "¥1,234.56",
            "CZK" to "Kč 1,234.56",
            "DKK" to "kr 1,234.56",
            "EUR" to "1,234.56€",
            "GBP" to "£1,234.56",
            "HKD" to "$1,234.56",
            "HUF" to "Ft 1,234.56",
            "IDR" to "Rp 1,234.56",
            "INR" to "₹1,234.56",
            "JPY" to "¥1,234.56",
            "KRW" to "₩1,234.56",
            "KWD" to "د.ك 1,234.56",
            "MXN" to "$1,234.56",
            "MYR" to "RM 1,234.56",
            "NOK" to "kr 1,234.56",
            "NZD" to "$1,234.56",
            "OMR" to "ر.ع. 1,234.56",
            "PHP" to "₱1,234.56",
            "PLN" to "zł 1,234.56",
            "QAR" to "ر.ق 1,234.56",
            "RON" to "lei 1,234.56",
            "RUB" to "₽1,234.56",
            "SAR" to "ر.س 1,234.56",
            "SEK" to "kr 1,234.56",
            "SGD" to "$1,234.56",
            "THB" to "฿1,234.56",
            "TRY" to "₺1,234.56",
            "USD" to "$1,234.56",
            "VND" to "₫1,234.56",
            "ZAR" to "R 1,234.56"
        )

        expectedFormats.forEach { (code, expectedOutput) ->
            // When
            val currency = Currency.fromCode(code)
            assertThat(currency).isNotNull()

            val result = CurrencyFormatter.format(amount, currency!!, showSymbol = true)

            // Then
            assertThat(result)
                .withMessage("Currency $code formatting failed")
                .isEqualTo(expectedOutput)
        }
    }

    @Test
    fun `format without symbol works for all 36 currencies`() {
        // Given
        val amount = BigDecimal("1234.56")

        Currency.all.forEach { currency ->
            // When
            val result = CurrencyFormatter.format(amount, currency, showSymbol = false)

            // Then - All should use consistent formatting
            assertThat(result)
                .withMessage("Currency ${currency.code} failed")
                .isEqualTo("1,234.56")
        }
    }

    @Test
    fun `formatCompact works for all 36 currencies`() {
        // Given
        val amount = BigDecimal("150.00")

        Currency.all.forEach { currency ->
            // When
            val result = CurrencyFormatter.formatCompact(amount, currency)

            // Then - Should include symbol but not code
            assertThat(result)
                .withMessage("Currency ${currency.code} failed")
                .contains("150.00")
            assertThat(result)
                .withMessage("Currency ${currency.code} should not include code in compact format")
                .doesNotContain(currency.code)
        }
    }

    @Test
    fun `formatDetailed works for all 36 currencies`() {
        // Given
        val amount = BigDecimal("150.00")

        Currency.all.forEach { currency ->
            // When
            val result = CurrencyFormatter.formatDetailed(amount, currency)

            // Then - Should include both symbol and code
            assertThat(result)
                .withMessage("Currency ${currency.code} failed")
                .contains("150.00")
            assertThat(result)
                .withMessage("Currency ${currency.code} should include code in detailed format")
                .contains(currency.code)
        }
    }

    @Test
    fun `parse works for all 36 currencies`() {
        // Given
        val amount = BigDecimal("1234.56")

        Currency.all.forEach { currency ->
            // When
            val formatted = CurrencyFormatter.format(amount, currency, showSymbol = true)
            val parsed = CurrencyFormatter.parse(formatted, currency)

            // Then - Should parse back to original amount
            assertThat(parsed)
                .withMessage("Currency ${currency.code} parsing failed from '$formatted'")
                .isEqualTo(amount)
        }
    }

    @Test
    fun `zero amount formats correctly for all 36 currencies`() {
        // Given
        val amount = BigDecimal.ZERO

        Currency.all.forEach { currency ->
            // When
            val result = CurrencyFormatter.format(amount, currency, showSymbol = true)

            // Then - Should show 0.00 with proper symbol
            assertThat(result)
                .withMessage("Currency ${currency.code} failed")
                .contains("0.00")
            assertThat(result)
                .withMessage("Currency ${currency.code} should include symbol")
                .isNotEqualTo("0.00") // Should have symbol
        }
    }

    @Test
    fun `large amounts format correctly for all 36 currencies`() {
        // Given - One million
        val amount = BigDecimal("1000000.00")

        Currency.all.forEach { currency ->
            // When
            val result = CurrencyFormatter.format(amount, currency, showSymbol = false)

            // Then - Should have proper grouping
            assertThat(result)
                .withMessage("Currency ${currency.code} failed")
                .isEqualTo("1,000,000.00")
        }
    }

    @Test
    fun `RTL currencies format correctly`() {
        // Given - RTL currencies in our list
        val rtlCurrencies = listOf("AED", "SAR", "BHD", "KWD", "OMR", "QAR")
        val amount = BigDecimal("100.00")

        rtlCurrencies.forEach { code ->
            // When
            val currency = Currency.fromCode(code)
            assertThat(currency).isNotNull()
            assertThat(currency!!.isRTL).isTrue()

            val result = CurrencyFormatter.format(amount, currency, showSymbol = true)

            // Then - Should format correctly (symbol typically before amount for RTL)
            assertThat(result)
                .withMessage("RTL Currency $code failed")
                .contains("100.00")
            assertThat(result)
                .withMessage("RTL Currency $code should include symbol")
                .contains(currency.symbol)
        }
    }

    @Test
    fun `decimal rounding works consistently for all currencies`() {
        // Given - Amount requiring rounding
        val amount = BigDecimal("100.999")

        Currency.all.forEach { currency ->
            // When
            val result = CurrencyFormatter.format(amount, currency, showSymbol = false)

            // Then - All should round to 101.00
            assertThat(result)
                .withMessage("Currency ${currency.code} rounding failed")
                .isEqualTo("101.00")
        }
    }

    // MARK: - Symbol Position Tests

    @Test
    fun `EUR symbol appears after amount`() {
        // Given
        val amount = BigDecimal("100.00")
        val currency = Currency.EUR

        // When
        val result = CurrencyFormatter.format(amount, currency, showSymbol = true)

        // Then - EUR symbol should be after amount
        assertThat(result).isEqualTo("100.00€")
    }

    @Test
    fun `dollar currencies have symbol before amount`() {
        // Given - Dollar currencies
        val dollarCurrencies = listOf("USD", "AUD", "CAD", "HKD", "SGD", "NZD")
        val amount = BigDecimal("100.00")

        dollarCurrencies.forEach { code ->
            // When
            val currency = Currency.fromCode(code)
            val result = CurrencyFormatter.format(amount, currency!!, showSymbol = true)

            // Then - Should start with $
            assertThat(result)
                .withMessage("Dollar currency $code failed")
                .startsWith("$")
        }
    }

    @Test
    fun `yen currencies share same symbol`() {
        // Given - JPY and CNY both use ¥
        val yenCurrencies = listOf("JPY", "CNY")
        val amount = BigDecimal("1000.00")

        yenCurrencies.forEach { code ->
            // When
            val currency = Currency.fromCode(code)
            val result = CurrencyFormatter.format(amount, currency!!, showSymbol = true)

            // Then - Should contain ¥ symbol
            assertThat(result)
                .withMessage("Yen currency $code failed")
                .contains("¥")
        }
    }

    @Test
    fun `scandinavian currencies use kr symbol`() {
        // Given - SEK, NOK, DKK all use kr
        val krCurrencies = listOf("SEK", "NOK", "DKK")
        val amount = BigDecimal("500.00")

        krCurrencies.forEach { code ->
            // When
            val currency = Currency.fromCode(code)
            val result = CurrencyFormatter.format(amount, currency!!, showSymbol = true)

            // Then - Should contain kr symbol
            assertThat(result)
                .withMessage("Scandinavian currency $code failed")
                .contains("kr")
        }
    }
}
