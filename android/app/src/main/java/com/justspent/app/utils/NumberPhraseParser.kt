package com.justspent.app.utils

import java.math.BigDecimal
import java.util.Locale

/**
 * Comprehensive number phrase parser for voice recognition
 *
 * Supports:
 * - Basic numbers (one, two, three, etc.)
 * - Compound numbers (twenty-five, forty-two, etc.)
 * - Western scale: hundred, thousand, million, billion, trillion
 * - Indian scale: lakh, crore
 * - Fractional amounts (point five, and fifty cents, etc.)
 * - Multiple formats and natural language variations
 *
 * Examples:
 * - "two thousand" → 2000
 * - "five lakh" → 500000
 * - "two point five million" → 2500000
 * - "one hundred and fifty" → 150
 * - "twenty five thousand three hundred" → 25300
 * - "three crore" → 30000000
 *
 * @author Just Spent Team
 * @since 1.0.0
 */
object NumberPhraseParser {

    /**
     * Parse a text phrase containing number words into a BigDecimal
     *
     * @param text Input text containing number words
     * @param locale Locale for region-specific number parsing (for future use)
     * @return Parsed number as BigDecimal, or null if no valid number found
     */
    fun parse(text: String, locale: Locale = Locale.getDefault()): BigDecimal? {
        val normalizedText = normalizeText(text)

        // Try to extract numeric amount first (priority)
        extractNumericAmount(normalizedText)?.let { return it }

        // Try to parse written number phrases
        return parseWrittenNumber(normalizedText)
    }

    /**
     * Extract numeric amount from text (e.g., "2000", "2,000", "2000.50")
     */
    private fun extractNumericAmount(text: String): BigDecimal? {
        // Patterns for different numeric formats
        val patterns = listOf(
            // With thousand separators: 2,000 or 2,000.50
            Regex("""(\d{1,3}(?:,\d{3})+(?:\.\d+)?)"""),
            // Simple decimal: 2000.50
            Regex("""(\d+\.\d+)"""),
            // Simple integer: 2000
            Regex("""(\d+)""")
        )

        for (pattern in patterns) {
            val match = pattern.find(text)
            if (match != null) {
                try {
                    val amountStr = match.groupValues[1].replace(",", "")
                    return BigDecimal(amountStr)
                } catch (e: NumberFormatException) {
                    continue
                }
            }
        }

        return null
    }

    /**
     * Parse written number phrases into numeric value
     * Handles complex multi-scale numbers like "two thousand five hundred"
     */
    private fun parseWrittenNumber(text: String): BigDecimal? {
        val words = text.split(Regex("""\s+|-"""))
            .map { it.lowercase().trim() }
            .filter { it.isNotEmpty() }

        if (words.isEmpty()) return null

        var total = 0.0
        var current = 0.0
        var fractionalPart: Double? = null
        var inFractionalSection = false

        for (i in words.indices) {
            val word = words[i]

            when {
                // Handle "and" separator (common in British English)
                word == "and" -> {
                    // Just skip "and" connectors
                    continue
                }

                // Handle fractional indicators
                word == "point" -> {
                    // Next words are decimal places
                    inFractionalSection = true
                    if (current > 0) {
                        total += current
                        current = 0.0
                    }
                    continue
                }

                // Handle "cents" or "paise" (fractional currency)
                word in listOf("cents", "cent", "paise", "paisa") -> {
                    // Previous number was in cents
                    if (current > 0) {
                        fractionalPart = current / 100.0
                        current = 0.0
                    }
                    continue
                }

                // Handle basic number words (0-19)
                basicNumbers.containsKey(word) -> {
                    val value = basicNumbers[word]!!
                    if (inFractionalSection) {
                        // Building decimal places digit by digit
                        fractionalPart = (fractionalPart ?: 0.0) * 10 + value
                    } else {
                        current += value
                    }
                }

                // Handle tens (20, 30, 40, etc.)
                tensNumbers.containsKey(word) -> {
                    current += tensNumbers[word]!!
                }

                // Handle hundred
                word == "hundred" -> {
                    if (current == 0.0) current = 1.0 // "hundred" alone = 100
                    current *= 100
                }

                // Handle thousand
                word in listOf("thousand", "thousands") -> {
                    if (current == 0.0) current = 1.0 // "thousand" alone = 1000
                    current *= 1000
                    total += current
                    current = 0.0
                }

                // Handle lakh (Indian numbering system)
                word in listOf("lakh", "lakhs", "lac", "lacs") -> {
                    if (current == 0.0) current = 1.0 // "lakh" alone = 100,000
                    current *= 100000
                    total += current
                    current = 0.0
                }

                // Handle crore (Indian numbering system)
                word in listOf("crore", "crores") -> {
                    if (current == 0.0) current = 1.0 // "crore" alone = 10,000,000
                    current *= 10000000
                    total += current
                    current = 0.0
                }

                // Handle million
                word in listOf("million", "millions") -> {
                    if (current == 0.0) current = 1.0 // "million" alone = 1,000,000
                    current *= 1000000
                    total += current
                    current = 0.0
                }

                // Handle billion
                word in listOf("billion", "billions") -> {
                    if (current == 0.0) current = 1.0
                    current *= 1000000000
                    total += current
                    current = 0.0
                }

                // Handle trillion
                word in listOf("trillion", "trillions") -> {
                    if (current == 0.0) current = 1.0
                    current *= 1000000000000
                    total += current
                    current = 0.0
                }
            }
        }

        // Add any remaining current value
        total += current

        // Combine whole and fractional parts
        if (fractionalPart != null) {
            // Normalize fractional part (e.g., "point five" = 0.5, not 0.05)
            val normalizedFraction = if (inFractionalSection && fractionalPart < 1.0) {
                fractionalPart
            } else if (fractionalPart >= 1.0 && fractionalPart < 100.0) {
                // e.g., "fifty cents" = 0.50
                fractionalPart / 100.0
            } else {
                fractionalPart
            }
            total += normalizedFraction
        }

        return if (total > 0) BigDecimal.valueOf(total) else null
    }

    /**
     * Normalize input text for better parsing
     * - Convert to lowercase
     * - Remove extra spaces
     * - Handle common speech-to-text variations
     */
    private fun normalizeText(text: String): String {
        return text
            .lowercase()
            .trim()
            // Handle hyphenated numbers
            .replace("-", " ")
            // Remove common filler words
            .replace(Regex("""\b(just|spent|paid|cost|costs|pay)\b"""), "")
            // Remove currency names for cleaner parsing
            .replace(Regex("""\b(dollars?|dirhams?|euros?|pounds?|rupees?|riyals?|aed|usd|eur|gbp|inr|sar)\b"""), "")
            // Normalize multiple spaces
            .replace(Regex("""\s+"""), " ")
            .trim()
    }

    /**
     * Check if text likely contains a number phrase
     */
    fun containsNumberPhrase(text: String): Boolean {
        val normalizedText = normalizeText(text)
        val words = normalizedText.split(Regex("""\s+"""))

        // Check if any word is a number word or multiplier
        return words.any { word ->
            basicNumbers.containsKey(word) ||
            tensNumbers.containsKey(word) ||
            multipliers.contains(word)
        }
    }

    /**
     * Extract amount from complex voice commands
     * Handles patterns like "I spent two thousand dirhams on groceries"
     */
    fun extractAmountFromCommand(command: String): BigDecimal? {
        val normalizedCommand = command.lowercase()

        // Try to extract amount substring between action words and currency/category
        val amountPatterns = listOf(
            // "spent [amount] dirhams"
            Regex("""(?:spent|spend|paid|pay|cost)\s+(.*?)\s+(?:dollars?|dirhams?|euros?|pounds?|rupees?|aed|usd|eur|gbp|inr|sar)"""),
            // "spent [amount] on"
            Regex("""(?:spent|spend|paid|pay|cost)\s+(.*?)\s+(?:on|for|at)"""),
            // "[amount] for/on"
            Regex("""^(.*?)\s+(?:for|on|at)""")
        )

        for (pattern in amountPatterns) {
            val match = pattern.find(normalizedCommand)
            if (match != null) {
                val amountText = match.groupValues[1].trim()
                parse(amountText)?.let { return it }
            }
        }

        // Fallback: try to parse the entire command
        return parse(normalizedCommand)
    }

    // ===========================================
    // Number Word Mappings
    // ===========================================

    /**
     * Basic number words (0-19)
     */
    private val basicNumbers = mapOf(
        "zero" to 0.0,
        "one" to 1.0,
        "two" to 2.0,
        "three" to 3.0,
        "four" to 4.0,
        "five" to 5.0,
        "six" to 6.0,
        "seven" to 7.0,
        "eight" to 8.0,
        "nine" to 9.0,
        "ten" to 10.0,
        "eleven" to 11.0,
        "twelve" to 12.0,
        "thirteen" to 13.0,
        "fourteen" to 14.0,
        "fifteen" to 15.0,
        "sixteen" to 16.0,
        "seventeen" to 17.0,
        "eighteen" to 18.0,
        "nineteen" to 19.0,
        // Common alternatives and misspellings
        "a" to 1.0,  // "a hundred" = "one hundred"
        "an" to 1.0  // "an hour" etc.
    )

    /**
     * Tens place words (20, 30, 40, etc.)
     */
    private val tensNumbers = mapOf(
        "twenty" to 20.0,
        "thirty" to 30.0,
        "forty" to 40.0,
        "fifty" to 50.0,
        "sixty" to 60.0,
        "seventy" to 70.0,
        "eighty" to 80.0,
        "ninety" to 90.0
    )

    /**
     * Scale multipliers
     */
    private val multipliers = setOf(
        "hundred", "thousand", "thousands",
        "lakh", "lakhs", "lac", "lacs",
        "crore", "crores",
        "million", "millions",
        "billion", "billions",
        "trillion", "trillions"
    )

    // ===========================================
    // Testing & Validation Helpers
    // ===========================================

    /**
     * Validate that a number phrase parses correctly
     * Useful for testing and debugging
     */
    fun validate(phrase: String, expectedValue: Double): Boolean {
        val parsed = parse(phrase)
        return parsed != null && parsed.toDouble() == expectedValue
    }

    /**
     * Get example phrases for testing
     */
    fun getExamplePhrases(): Map<String, Double> {
        return mapOf(
            // Basic numbers
            "five" to 5.0,
            "fifteen" to 15.0,
            "twenty" to 20.0,
            "twenty five" to 25.0,
            "ninety nine" to 99.0,

            // Hundreds
            "one hundred" to 100.0,
            "two hundred" to 200.0,
            "five hundred and fifty" to 550.0,
            "nine hundred ninety nine" to 999.0,

            // Thousands
            "one thousand" to 1000.0,
            "two thousand" to 2000.0,
            "ten thousand" to 10000.0,
            "twenty five thousand" to 25000.0,
            "one hundred thousand" to 100000.0,
            "two thousand five hundred" to 2500.0,

            // Lakhs (Indian system)
            "one lakh" to 100000.0,
            "five lakh" to 500000.0,
            "ten lakh" to 1000000.0,
            "twenty five lakh" to 2500000.0,

            // Crores (Indian system)
            "one crore" to 10000000.0,
            "two crore" to 20000000.0,
            "five crore" to 50000000.0,

            // Millions
            "one million" to 1000000.0,
            "two million" to 2000000.0,
            "five million" to 5000000.0,
            "ten million" to 10000000.0,

            // Billions
            "one billion" to 1000000000.0,
            "two billion" to 2000000000.0,

            // Complex combinations
            "two thousand five hundred and fifty" to 2550.0,
            "one million two hundred thousand" to 1200000.0,
            "five lakh fifty thousand" to 550000.0,

            // Decimals
            "five point five" to 5.5,
            "two point five million" to 2500000.0,
            "one point two five" to 1.25,

            // With "and" connector
            "one hundred and twenty" to 120.0,
            "two thousand and five" to 2005.0
        )
    }
}
