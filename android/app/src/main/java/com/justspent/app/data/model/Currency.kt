package com.justspent.app.data.model

import java.util.Locale

/**
 * Represents supported currencies in the Just Spent application
 * Follows ISO 4217 standards with extended metadata for localization and display
 *
 * @property code ISO 4217 currency code
 * @property symbol Currency symbol for display
 * @property displayName Localized currency name in English
 * @property shortName Short display name for compact views
 * @property localeIdentifier Locale identifier for proper number formatting
 * @property isRTL Whether this currency uses right-to-left text direction
 * @property voiceKeywords Keywords for voice command detection
 */
sealed class Currency(
    val code: String,
    val symbol: String,
    val displayName: String,
    val shortName: String,
    val localeIdentifier: String,
    val isRTL: Boolean,
    val voiceKeywords: List<String>
) {

    // MARK: - Currency Definitions

    object AED : Currency(
        code = "AED",
        symbol = "د.إ",
        displayName = "UAE Dirham",
        shortName = "Dirham",
        localeIdentifier = "ar_AE",
        isRTL = true,
        voiceKeywords = listOf("aed", "dirham", "dirhams", "د.إ", "dhs", "emirati dirham")
    )

    object USD : Currency(
        code = "USD",
        symbol = "$",
        displayName = "US Dollar",
        shortName = "Dollar",
        localeIdentifier = "en_US",
        isRTL = false,
        voiceKeywords = listOf("usd", "dollar", "dollars", "$", "buck", "bucks", "us dollar")
    )

    object EUR : Currency(
        code = "EUR",
        symbol = "€",
        displayName = "Euro",
        shortName = "Euro",
        localeIdentifier = "en_DE",
        isRTL = false,
        voiceKeywords = listOf("eur", "euro", "euros", "€")
    )

    object GBP : Currency(
        code = "GBP",
        symbol = "£",
        displayName = "British Pound",
        shortName = "Pound",
        localeIdentifier = "en_GB",
        isRTL = false,
        voiceKeywords = listOf("gbp", "pound", "pounds", "£", "quid", "sterling", "british pound")
    )

    object INR : Currency(
        code = "INR",
        symbol = "₹",
        displayName = "Indian Rupee",
        shortName = "Rupee",
        localeIdentifier = "en_IN",
        isRTL = false,
        voiceKeywords = listOf("inr", "rupee", "rupees", "₹", "indian rupee")
    )

    object SAR : Currency(
        code = "SAR",
        symbol = "﷼",
        displayName = "Saudi Riyal",
        shortName = "Riyal",
        localeIdentifier = "ar_SA",
        isRTL = true,
        voiceKeywords = listOf("sar", "riyal", "riyals", "﷼", "saudi riyal")
    )

    // MARK: - Properties

    /**
     * Locale object for formatting operations
     */
    val locale: Locale
        get() = when (this) {
            is AED -> Locale("ar", "AE")
            is USD -> Locale.US
            is EUR -> Locale.GERMANY
            is GBP -> Locale.UK
            is INR -> Locale("en", "IN")
            is SAR -> Locale("ar", "SA")
        }

    /**
     * Number of decimal places for this currency
     */
    val decimalPlaces: Int = 2

    /**
     * Decimal separator character
     */
    val decimalSeparator: String
        get() = when (this) {
            is EUR -> ","
            else -> "."
        }

    /**
     * Thousands grouping separator
     */
    val groupingSeparator: String
        get() = when (this) {
            is EUR -> "."
            is INR -> ","
            else -> ","
        }

    // MARK: - Companion Object (Static Utilities)

    companion object {
        /**
         * All supported currencies
         */
        val all: List<Currency> = listOf(AED, USD, EUR, GBP, INR, SAR)

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

                return fromCode(currencyCode) ?: USD
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
         *
         * @param text Input text to analyze
         * @return Detected currency or null if no match found
         */
        fun detectFromText(text: String): Currency? {
            val lowercasedText = text.lowercase()

            for (currency in all) {
                for (keyword in currency.voiceKeywords) {
                    if (lowercasedText.contains(keyword.lowercase())) {
                        return currency
                    }
                }
            }

            return null
        }
    }

    // MARK: - Overrides

    override fun toString(): String = "$symbol $code"

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Currency) return false
        return code == other.code
    }

    override fun hashCode(): Int = code.hashCode()
}

/**
 * Extension function to get Currency from String code
 */
fun String.toCurrency(): Currency? = Currency.fromCode(this)
