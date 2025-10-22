package com.justspent.app.utils

import com.justspent.app.data.model.Currency

/**
 * Utility for detecting currency from voice commands and text input
 */
object VoiceCurrencyDetector {

    /**
     * Detect currency from voice transcript or text input
     *
     * Supports:
     * - ISO codes (USD, AED, EUR, etc.)
     * - Currency symbols ($, د.إ, €, £, ₹, ﷼)
     * - Spoken names (dollar, dirham, euro, pound, rupee, riyal)
     * - Colloquial terms (buck, quid, etc.)
     *
     * @param text Input text from voice or manual entry
     * @param defaultCurrency Fallback currency if no match found
     * @return Detected currency or default
     */
    fun detectCurrency(text: String, defaultCurrency: Currency = Currency.USD): Currency {
        // First try the built-in detection from Currency model
        Currency.detectFromText(text)?.let { return it }

        // Additional detection patterns for voice input
        val lowercasedText = text.lowercase()

        // Check for amount patterns with currency (e.g., "50 dollars", "$100")
        val amountCurrencyPattern = Regex("""(\d+\.?\d*)\s*([a-zA-Z\$€£₹﷼د.إ]+)""")
        amountCurrencyPattern.find(lowercasedText)?.let { matchResult ->
            val currencyPart = matchResult.groupValues[2]
            Currency.detectFromText(currencyPart)?.let { return it }
        }

        // Check for currency at the end (e.g., "spent 50 in dollars")
        val endCurrencyPattern = Regex("""in\s+([a-zA-Z]+)$""")
        endCurrencyPattern.find(lowercasedText)?.let { matchResult ->
            val currencyPart = matchResult.groupValues[1]
            Currency.detectFromText(currencyPart)?.let { return it }
        }

        // Return default if no currency detected
        return defaultCurrency
    }

    /**
     * Extract amount and currency from voice command
     *
     * Examples:
     * - "spent 50 dollars" → (50.0, USD)
     * - "د.إ 100 for groceries" → (100.0, AED)
     * - "paid 25.50 euros" → (25.50, EUR)
     *
     * @param text Input text from voice command
     * @param defaultCurrency Fallback currency
     * @return Pair of amount and currency, or null if amount not found
     */
    fun extractAmountAndCurrency(
        text: String,
        defaultCurrency: Currency = Currency.USD
    ): Pair<Double, Currency>? {
        val lowercasedText = text.lowercase()

        // Pattern: number followed by currency
        // Matches: "50 dollars", "100 dirhams", "$50", "د.إ 100"
        val patterns = listOf(
            Regex("""(\d+\.?\d*)\s*([a-zA-Z\$€£₹﷼د.إ]+)"""),
            Regex("""([a-zA-Z\$€£₹﷼د.إ]+)\s*(\d+\.?\d*)""")
        )

        for (pattern in patterns) {
            pattern.find(text)?.let { matchResult ->
                val group1 = matchResult.groupValues[1]
                val group2 = matchResult.groupValues[2]

                // Determine which is amount and which is currency
                val amount = group1.toDoubleOrNull() ?: group2.toDoubleOrNull()
                val currencyText = if (amount == group1.toDoubleOrNull()) group2 else group1

                if (amount != null) {
                    val currency = Currency.detectFromText(currencyText) ?: defaultCurrency
                    return Pair(amount, currency)
                }
            }
        }

        // If no currency found, try to extract just the amount
        val amountPattern = Regex("""(\d+\.?\d*)""")
        amountPattern.find(lowercasedText)?.let { matchResult ->
            val amount = matchResult.groupValues[1].toDoubleOrNull()
            if (amount != null) {
                // Detect currency from the rest of the text
                val currency = detectCurrency(text, defaultCurrency)
                return Pair(amount, currency)
            }
        }

        return null
    }

    /**
     * Check if text contains a currency mention
     *
     * @param text Input text
     * @return true if currency is mentioned, false otherwise
     */
    fun containsCurrency(text: String): Boolean {
        return Currency.detectFromText(text) != null
    }

    /**
     * Replace currency symbols with ISO codes in text
     *
     * Useful for normalization before processing
     *
     * @param text Input text
     * @return Text with symbols replaced by codes
     */
    fun normalizeCurrencySymbols(text: String): String {
        var normalized = text

        Currency.all.forEach { currency ->
            normalized = normalized.replace(currency.symbol, currency.code)
        }

        return normalized
    }
}
