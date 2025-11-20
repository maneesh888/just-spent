package com.justspent.expense.utils

import com.justspent.expense.data.model.Currency

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
        val amountCurrencyPattern = Regex("""(\d+\.?\d*)\s*([a-zA-Z\$€£₹₨﷼د.إ]+)""")
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
        // Matches: "50 dollars", "100 dirhams", "$50", "د.إ 100", "₹20", "Rs 500"
        val patterns = listOf(
            // Specific currency symbol patterns (highest priority)
            Regex("""₹\s*(\d+\.?\d*)"""),         // ₹20, ₹ 500
            Regex("""₨\s*(\d+\.?\d*)"""),         // ₨20, ₨ 500
            Regex("""[Rr]s\.?\s+(\d+\.?\d*)"""),  // Rs 500, rs. 500 (with space)
            Regex("""\$(\d+\.?\d*)"""),           // $50
            Regex("""€(\d+\.?\d*)"""),            // €50
            Regex("""£(\d+\.?\d*)"""),            // £50
            Regex("""د\.إ\s*(\d+\.?\d*)"""),      // د.إ 100
            Regex("""﷼\s*(\d+\.?\d*)"""),         // ﷼100

            // Currency symbol before number
            Regex("""(\d+\.?\d*)\s*₹"""),
            Regex("""(\d+\.?\d*)\s*₨"""),
            Regex("""(\d+\.?\d*)\s+[Rr]s\.?"""),  // 500 Rs, 500 rs.

            // Number followed by currency keyword
            Regex("""(\d+\.?\d*)\s*([a-zA-Z\$€£₹₨﷼د.إ]+)"""),
            Regex("""([a-zA-Z\$€£₹₨﷼د.إ]+)\s*(\d+\.?\d*)""")
        )

        for (pattern in patterns) {
            pattern.find(text)?.let { matchResult ->
                // Handle specific symbol patterns (single capture group)
                if (matchResult.groupValues.size == 2) {
                    val amountStr = matchResult.groupValues[1]
                    val amount = amountStr.toDoubleOrNull()

                    if (amount != null) {
                        // Detect currency from the matched text
                        val currency = detectCurrency(matchResult.value, defaultCurrency)
                        return Pair(amount, currency)
                    }
                }

                // Handle two-group patterns
                if (matchResult.groupValues.size == 3) {
                    val group1 = matchResult.groupValues[1]
                    val group2 = matchResult.groupValues[2]

                    // Determine which is amount and which is currency
                    val amount = group1.toDoubleOrNull() ?: group2.toDoubleOrNull()

                    if (amount != null) {
                        // Use full text for currency detection to catch multi-word phrases like "australian dollars"
                        val currency = Currency.detectFromText(text) ?: defaultCurrency
                        return Pair(amount, currency)
                    }
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
     * Priority: USD first for $ symbol (most common), then other common currencies
     * Preserves spacing: "$50" → "USD50", "د.إ 100" → "AED 100"
     *
     * Uses placeholders to avoid double-replacement (e.g., EUR's R becoming ZAR)
     *
     * @param text Input text
     * @return Text with symbols replaced by codes
     */
    fun normalizeCurrencySymbols(text: String): String {
        var normalized = text
        val replacements = mutableMapOf<String, String>()
        var placeholderIndex = 0

        // First pass: Replace symbols with unique placeholders to avoid conflicts
        // Use emoji placeholders which won't conflict with any currency symbols
        // Process common currencies first for $ ambiguity (USD not AUD)
        Currency.common.forEach { currency ->
            if (normalized.contains(currency.symbol)) {
                val placeholder = "🪙${placeholderIndex++}🪙"
                replacements[placeholder] = currency.code
                normalized = normalized.replace(currency.symbol, placeholder)
            }
        }

        // Then process remaining currencies
        Currency.all.filterNot { it.code in listOf("AED", "USD", "EUR", "GBP", "INR", "SAR") }
            .forEach { currency ->
                if (normalized.contains(currency.symbol)) {
                    val placeholder = "🪙${placeholderIndex++}🪙"
                    replacements[placeholder] = currency.code
                    normalized = normalized.replace(currency.symbol, placeholder)
                }
            }

        // Second pass: Replace placeholders with actual currency codes
        replacements.forEach { (placeholder, code) ->
            normalized = normalized.replace(placeholder, code)
        }

        return normalized
    }
}
