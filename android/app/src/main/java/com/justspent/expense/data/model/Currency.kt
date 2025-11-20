@file:OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)

package com.justspent.expense.data.model

import android.content.Context
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.util.Locale

/**
 * Represents a currency in the Just Spent application
 * Loaded dynamically from currencies.json for flexibility and easy updates
 *
 * @property code ISO 4217 currency code
 * @property symbol Currency symbol for display
 * @property displayName Localized currency name in English
 * @property shortName Short display name for compact views
 * @property localeIdentifier Locale identifier for proper number formatting
 * @property isRTL Whether this currency uses right-to-left text direction
 * @property voiceKeywords Keywords for voice command detection
 */
@Serializable
data class Currency(
    val code: String,
    val symbol: String,
    val displayName: String,
    val shortName: String,
    val localeIdentifier: String,
    val isRTL: Boolean,
    val voiceKeywords: List<String>
) {
    /**
     * Locale object for formatting operations
     */
    val locale: Locale by lazy {
        val parts = localeIdentifier.split("_")
        when (parts.size) {
            1 -> Locale(parts[0])
            2 -> Locale(parts[0], parts[1])
            else -> Locale.US
        }
    }

    /**
     * Number of decimal places for this currency
     */
    val decimalPlaces: Int = 2

    /**
     * Decimal separator character
     * Always uses "." (Western/English format) for consistency across all currencies
     */
    val decimalSeparator: String = "."

    /**
     * Thousands grouping separator
     * Always uses "," (Western/English format) for consistency across all currencies
     */
    val groupingSeparator: String = ","

    // MARK: - Overrides

    override fun toString(): String = "$symbol $code"

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Currency) return false
        return code == other.code
    }

    override fun hashCode(): Int = code.hashCode()

    companion object {
        // Cached currencies loaded from JSON
        private var _allCurrencies: List<Currency>? = null

        /**
         * Initialize the currency system with context
         * Should be called once during app initialization
         */
        fun initialize(context: Context) {
            if (_allCurrencies == null) {
                android.util.Log.d("Currency", "🔄 Starting initialization...")
                _allCurrencies = CurrencyLoader.loadCurrencies(context)
                android.util.Log.d("Currency", "🔄 Initialization complete. Loaded ${_allCurrencies?.size ?: 0} currencies")
            } else {
                android.util.Log.w("Currency", "⚠️ Already initialized with ${_allCurrencies?.size ?: 0} currencies")
            }
        }

        /**
         * All supported currencies
         */
        val all: List<Currency>
            get() = _allCurrencies ?: throw IllegalStateException(
                "Currency system not initialized. Call Currency.initialize(context) first."
            )

        /**
         * Commonly used currencies (for onboarding UI)
         */
        val common: List<Currency>
            get() = all.filter { it.code in commonCodes }

        private val commonCodes = listOf("AED", "USD", "EUR", "GBP", "INR", "SAR", "JPY")

        /**
         * Default currency for new users (based on device locale)
         */
        val default: Currency
            get() {
                val deviceLocale = Locale.getDefault()
                val currencyCode = try {
                    java.util.Currency.getInstance(deviceLocale).currencyCode
                } catch (e: Exception) {
                    "USD"
                }

                return fromCode(currencyCode) ?: fromCode("USD")!!
            }

        /**
         * Create currency from ISO code string
         *
         * @param code ISO 4217 currency code
         * @return Currency object or null if invalid
         */
        fun fromCode(code: String): Currency? {
            return all.find { it.code.equals(code, ignoreCase = true) }
        }

        /**
         * Detect currency from text input (voice commands, manual entry)
         * Prioritizes common currencies (AED, USD, EUR, GBP, INR, SAR) before checking all currencies
         * Uses word boundary matching for better accuracy and prioritizes longer keywords
         *
         * @param text Input text to analyze
         * @return Detected currency or null if no match found
         */
        fun detectFromText(text: String): Currency? {
            val lowercasedText = text.lowercase()

            // Helper function to check if keyword matches (whole word or symbol)
            fun matchesKeyword(text: String, keyword: String): Boolean {
                val lowercaseKeyword = keyword.lowercase()

                // For single character or symbol keywords, use contains
                if (keyword.length <= 2 && keyword.any { !it.isLetterOrDigit() }) {
                    return text.contains(lowercaseKeyword)
                }

                // For word keywords, use word boundary matching
                return text.contains(Regex("\\b${Regex.escape(lowercaseKeyword)}\\b"))
            }

            // Helper function to find best match with tie-breaking logic
            fun findBestMatch(currencies: List<Currency>): Currency? {
                val matches = mutableListOf<Pair<Currency, String>>()

                for (currency in currencies) {
                    // Sort keywords by length (longest first) to prioritize specific phrases
                    // This ensures "australian dollars" is checked before "dollars"
                    val sortedKeywords = currency.voiceKeywords.sortedByDescending { it.length }

                    for (keyword in sortedKeywords) {
                        if (matchesKeyword(lowercasedText, keyword)) {
                            // Only add the first (longest) matching keyword for this currency
                            matches.add(currency to keyword)
                            break  // Stop checking other keywords for this currency
                        }
                    }
                }

                if (matches.isEmpty()) return null

                // Find max keyword length
                val maxLength = matches.maxOf { it.second.length }

                // Get all matches with max length
                val longestMatches = matches.filter { it.second.length == maxLength }

                // If only one longest match, return it
                if (longestMatches.size == 1) {
                    return longestMatches.first().first
                }

                // Tie-breaker: prefer common currencies (USD > AUD for "dollar")
                val commonMatch = longestMatches.firstOrNull { it.first.code in commonCodes }
                if (commonMatch != null) {
                    return commonMatch.first
                }

                // Otherwise return first match
                return longestMatches.first().first
            }

            // Search all currencies with intelligent tie-breaking
            // Prioritizes longest keywords, then common currencies
            return findBestMatch(all)
        }

        // Legacy object references for backward compatibility
        val AED: Currency get() = fromCode("AED")!!
        val USD: Currency get() = fromCode("USD")!!
        val EUR: Currency get() = fromCode("EUR")!!
        val GBP: Currency get() = fromCode("GBP")!!
        val INR: Currency get() = fromCode("INR")!!
        val SAR: Currency get() = fromCode("SAR")!!
    }
}

/**
 * Internal data structure for JSON parsing
 */
@Serializable
private data class CurrenciesData(
    val version: String,
    val lastUpdated: String,
    val currencies: List<Currency>
)

/**
 * Utility object to load currencies from JSON asset file
 */
private object CurrencyLoader {
    private val json = Json { ignoreUnknownKeys = true }

    fun loadCurrencies(context: Context): List<Currency> {
        return try {
            android.util.Log.d("Currency", "📂 Searching for currencies.json in assets...")

            val jsonString = context.assets.open("currencies.json").bufferedReader().use { it.readText() }
            android.util.Log.d("Currency", "✅ Found currencies.json")
            android.util.Log.d("Currency", "📊 JSON file size: ${jsonString.length} characters")

            val data = json.decodeFromString<CurrenciesData>(jsonString)
            android.util.Log.d("Currency", "✅ Successfully decoded JSON")
            android.util.Log.d("Currency", "✅ Loaded ${data.currencies.size} currencies from JSON (version ${data.version})")
            android.util.Log.d("Currency", "✅ Sample currencies: ${data.currencies.take(3).map { it.code }.joinToString(", ")}")

            data.currencies
        } catch (e: kotlinx.serialization.SerializationException) {
            android.util.Log.e("Currency", "❌ JSON SERIALIZATION ERROR", e)
            android.util.Log.e("Currency", "   This usually means the JSON structure doesn't match the Currency data class")
            emptyList()
        } catch (e: java.io.FileNotFoundException) {
            android.util.Log.e("Currency", "❌ currencies.json NOT FOUND in assets folder", e)
            android.util.Log.e("Currency", "   Check if file exists: android/app/src/main/assets/currencies.json")
            emptyList()
        } catch (e: Exception) {
            android.util.Log.e("Currency", "❌ Failed to load currencies from JSON: ${e.javaClass.simpleName}", e)
            android.util.Log.e("Currency", "   Error message: ${e.message}")
            emptyList()
        }
    }
}

/**
 * Extension function to get Currency from String code
 */
fun String.toCurrency(): Currency? = Currency.fromCode(this)
