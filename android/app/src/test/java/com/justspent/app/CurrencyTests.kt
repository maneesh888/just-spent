package com.justspent.app

import com.justspent.app.data.model.Currency
import com.justspent.app.utils.CurrencyFormatter
import com.justspent.app.utils.VoiceCurrencyDetector
import com.justspent.app.utils.formatted
import com.justspent.app.utils.formattedCompact
import com.justspent.app.utils.formattedDetailed
import org.junit.Assert.*
import org.junit.Test
import java.math.BigDecimal

/**
 * Comprehensive tests for currency functionality
 */
class CurrencyTests {

    // MARK: - Currency Model Tests

    @Test
    fun testCurrencyProperties() {
        // Test USD
        val usd = Currency.USD
        assertEquals("USD", usd.code)
        assertEquals("$", usd.symbol)
        assertEquals("US Dollar", usd.displayName)
        assertFalse(usd.isRTL)

        // Test AED
        val aed = Currency.AED
        assertEquals("AED", aed.code)
        assertEquals("د.إ", aed.symbol)
        assertEquals("UAE Dirham", aed.displayName)
        assertTrue(aed.isRTL)

        // Test EUR
        val eur = Currency.EUR
        assertEquals("EUR", eur.code)
        assertEquals("€", eur.symbol)
        assertEquals("Euro", eur.displayName)
        assertFalse(eur.isRTL)
    }

    @Test
    fun testCurrencyFromCode() {
        assertEquals(Currency.USD, Currency.fromCode("USD"))
        assertEquals(Currency.AED, Currency.fromCode("AED"))
        assertEquals(Currency.EUR, Currency.fromCode("EUR"))
        assertEquals(Currency.GBP, Currency.fromCode("GBP"))
        assertEquals(Currency.INR, Currency.fromCode("INR"))
        assertEquals(Currency.SAR, Currency.fromCode("SAR"))

        // Test case insensitivity
        assertEquals(Currency.USD, Currency.fromCode("usd"))
        assertEquals(Currency.AED, Currency.fromCode("Aed"))

        // Test invalid code
        assertNull(Currency.fromCode("INVALID"))
    }

    @Test
    fun testCurrencyDetectionFromText() {
        // Test symbol detection
        assertEquals(Currency.USD, Currency.detectFromText("$50"))
        assertEquals(Currency.AED, Currency.detectFromText("د.إ 100"))
        assertEquals(Currency.EUR, Currency.detectFromText("€25"))
        assertEquals(Currency.GBP, Currency.detectFromText("£20"))
        assertEquals(Currency.INR, Currency.detectFromText("₹500"))
        assertEquals(Currency.SAR, Currency.detectFromText("﷼50"))

        // Test name detection
        assertEquals(Currency.USD, Currency.detectFromText("50 dollars"))
        assertEquals(Currency.AED, Currency.detectFromText("100 dirhams"))
        assertEquals(Currency.EUR, Currency.detectFromText("25 euros"))
        assertEquals(Currency.GBP, Currency.detectFromText("20 pounds"))
        assertEquals(Currency.INR, Currency.detectFromText("500 rupees"))
        assertEquals(Currency.SAR, Currency.detectFromText("50 riyals"))

        // Test colloquial terms
        assertEquals(Currency.USD, Currency.detectFromText("50 bucks"))
        assertEquals(Currency.GBP, Currency.detectFromText("20 quid"))

        // Test no match
        assertNull(Currency.detectFromText("spent money"))
    }

    @Test
    fun testCurrencyVoiceKeywords() {
        val usd = Currency.USD
        assertTrue(usd.voiceKeywords.contains("usd"))
        assertTrue(usd.voiceKeywords.contains("dollar"))
        assertTrue(usd.voiceKeywords.contains("$"))

        val aed = Currency.AED
        assertTrue(aed.voiceKeywords.contains("aed"))
        assertTrue(aed.voiceKeywords.contains("dirham"))
        assertTrue(aed.voiceKeywords.contains("د.إ"))
    }

    // MARK: - Currency Formatter Tests

    @Test
    fun testBasicFormatting() {
        val amount = BigDecimal("1234.56")

        // USD
        val usdFormatted = CurrencyFormatter.format(
            amount = amount,
            currency = Currency.USD,
            showSymbol = true,
            showCode = false
        )
        assertTrue(usdFormatted.contains("$"))
        assertTrue(usdFormatted.contains("1,234.56") || usdFormatted.contains("1234.56"))

        // AED
        val aedFormatted = CurrencyFormatter.format(
            amount = amount,
            currency = Currency.AED,
            showSymbol = true,
            showCode = false
        )
        assertTrue(aedFormatted.contains("د.إ"))

        // EUR
        val eurFormatted = CurrencyFormatter.format(
            amount = amount,
            currency = Currency.EUR,
            showSymbol = true,
            showCode = false
        )
        assertTrue(eurFormatted.contains("€"))
    }

    @Test
    fun testFormattingWithCode() {
        val amount = BigDecimal("100.00")

        val formatted = CurrencyFormatter.format(
            amount = amount,
            currency = Currency.USD,
            showSymbol = true,
            showCode = true
        )

        assertTrue(formatted.contains("$"))
        assertTrue(formatted.contains("USD"))
    }

    @Test
    fun testCompactFormatting() {
        val amount = BigDecimal("50.25")

        val compact = CurrencyFormatter.formatCompact(amount, Currency.USD)
        assertTrue(compact.contains("$"))
        assertTrue(compact.contains("50.25"))
    }

    @Test
    fun testDetailedFormatting() {
        val amount = BigDecimal("75.50")

        val detailed = CurrencyFormatter.formatDetailed(amount, Currency.GBP)
        assertTrue(detailed.contains("£"))
        assertTrue(detailed.contains("GBP"))
    }

    @Test
    fun testExtensionFunctions() {
        val amount = BigDecimal("100.00")

        val formatted = amount.formatted(Currency.USD)
        assertTrue(formatted.contains("$"))

        val compact = amount.formattedCompact(Currency.AED)
        assertTrue(compact.contains("د.إ"))

        val detailed = amount.formattedDetailed(Currency.EUR)
        assertTrue(detailed.contains("€"))
        assertTrue(detailed.contains("EUR"))
    }

    @Test
    fun testCurrencyParsing() {
        // Test parsing formatted currency
        val parsed = CurrencyFormatter.parse("$100.50", Currency.USD)
        assertEquals(BigDecimal("100.50"), parsed)

        // Test parsing with different symbols
        val parsedAED = CurrencyFormatter.parse("د.إ 250.75", Currency.AED)
        assertEquals(BigDecimal("250.75"), parsedAED)

        // Test parsing just numbers
        val parsedPlain = CurrencyFormatter.parse("50.25", Currency.USD)
        assertEquals(BigDecimal("50.25"), parsedPlain)
    }

    // MARK: - Voice Currency Detector Tests

    @Test
    fun testSimpleAmountCurrencyExtraction() {
        // Test "50 dollars"
        val result1 = VoiceCurrencyDetector.extractAmountAndCurrency("50 dollars")
        assertNotNull(result1)
        assertEquals(50.0, result1!!.first, 0.01)
        assertEquals(Currency.USD, result1.second)

        // Test "د.إ 100"
        val result2 = VoiceCurrencyDetector.extractAmountAndCurrency("د.إ 100")
        assertNotNull(result2)
        assertEquals(100.0, result2!!.first, 0.01)
        assertEquals(Currency.AED, result2.second)
    }

    @Test
    fun testComplexVoiceCommandExtraction() {
        // Test full sentence
        val result1 = VoiceCurrencyDetector.extractAmountAndCurrency(
            "I just spent 25.50 euros on groceries"
        )
        assertNotNull(result1)
        assertEquals(25.50, result1!!.first, 0.01)
        assertEquals(Currency.EUR, result1.second)

        // Test with merchant
        val result2 = VoiceCurrencyDetector.extractAmountAndCurrency(
            "Paid 20 pounds at the store"
        )
        assertNotNull(result2)
        assertEquals(20.0, result2!!.first, 0.01)
        assertEquals(Currency.GBP, result2.second)
    }

    @Test
    fun testCurrencyDetectionWithoutAmount() {
        val usd = VoiceCurrencyDetector.detectCurrency(
            text = "spent some dollars",
            defaultCurrency = Currency.AED
        )
        assertEquals(Currency.USD, usd)

        val aed = VoiceCurrencyDetector.detectCurrency(
            text = "paid in dirhams",
            defaultCurrency = Currency.USD
        )
        assertEquals(Currency.AED, aed)

        // Test default fallback
        val defaultCurrency = VoiceCurrencyDetector.detectCurrency(
            text = "spent money",
            defaultCurrency = Currency.GBP
        )
        assertEquals(Currency.GBP, defaultCurrency)
    }

    @Test
    fun testContainsCurrency() {
        assertTrue(VoiceCurrencyDetector.containsCurrency("50 dollars"))
        assertTrue(VoiceCurrencyDetector.containsCurrency("د.إ 100"))
        assertTrue(VoiceCurrencyDetector.containsCurrency("paid in euros"))
        assertFalse(VoiceCurrencyDetector.containsCurrency("spent money"))
    }

    @Test
    fun testNormalizeCurrencySymbols() {
        val normalized = VoiceCurrencyDetector.normalizeCurrencySymbols(
            "$50 and €25 and د.إ 100"
        )
        assertTrue(normalized.contains("USD"))
        assertTrue(normalized.contains("EUR"))
        assertTrue(normalized.contains("AED"))
    }

    // MARK: - Integration Tests

    @Test
    fun testEndToEndCurrencyFlow() {
        // Simulate voice command: "I spent 50 dirhams on groceries"
        val voiceCommand = "I spent 50 dirhams on groceries"

        // 1. Detect currency
        val currency = Currency.detectFromText(voiceCommand)
        assertNotNull(currency)
        assertEquals(Currency.AED, currency)

        // 2. Extract amount
        val extraction = VoiceCurrencyDetector.extractAmountAndCurrency(voiceCommand)
        assertNotNull(extraction)
        assertEquals(50.0, extraction!!.first, 0.01)
        assertEquals(Currency.AED, extraction.second)

        // 3. Format for display
        val formatted = CurrencyFormatter.formatCompact(
            BigDecimal(extraction.first.toString()),
            extraction.second
        )
        assertTrue(formatted.contains("د.إ"))
        assertTrue(formatted.contains("50"))
    }
}
