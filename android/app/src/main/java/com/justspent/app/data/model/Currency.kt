package com.justspent.app.data.model

import android.content.Context
import com.google.gson.Gson
import com.google.gson.annotations.SerializedName
import java.util.Locale

/**
 * Represents a currency in the Just Spent application
 * Follows ISO 4217 standards with extended metadata for localization and display
 *
 * @property code ISO 4217 currency code
 * @property symbol Currency symbol for display
 * @property displayName Localized currency name in English
 * @property pluralName Plural name for the currency
 * @property symbolPosition Symbol position (before/after)
 * @property decimalSeparator Decimal separator character
 * @property groupingSeparator Thousands grouping separator
 * @property decimalPlaces Number of decimal places
 * @property isCommon Whether this is a common currency
 * @property voiceKeywords Keywords for voice command detection
 * @property countryCodes Country codes that use this currency
 * @property exampleFormat Example formatted amount
 */
data class Currency(
    val code: String,
    val symbol: String,
    @SerializedName("display_name")
    val displayName: String,
    @SerializedName("plural_name")
    val pluralName: String,
    @SerializedName("symbol_position")
    val symbolPosition: String,
    @SerializedName("decimal_separator")
    val decimalSeparator: String,
    @SerializedName("grouping_separator")
    val groupingSeparator: String,
    @SerializedName("decimal_places")
    val decimalPlaces: Int,
    @SerializedName("is_common")
    val isCommon: Boolean,
    @SerializedName("voice_keywords")
    val voiceKeywords: List<String>,
    @SerializedName("country_codes")
    val countryCodes: List<String>,
    @SerializedName("example_format")
    val exampleFormat: String
) {

    // MARK: - Computed Properties

    /**
     * Short display name for compact views
     */
    val shortName: String
        get() = displayName.split(" ").lastOrNull() ?: displayName

    /**
     * Whether this currency uses right-to-left text direction
     */
    val isRTL: Boolean
        get() = code in listOf("AED", "SAR", "BHD", "KWD", "OMR", "QAR")

    /**
     * Locale object for formatting operations
     */
    val locale: Locale
        get() = when (code) {
            "AED" -> Locale("ar", "AE")
            "USD" -> Locale.US
            "EUR" -> Locale.GERMANY
            "GBP" -> Locale.UK
            "INR" -> Locale("en", "IN")
            "SAR" -> Locale("ar", "SA")
            "JPY" -> Locale.JAPAN
            "CNY" -> Locale.CHINA
            "AUD" -> Locale("en", "AU")
            "CAD" -> Locale.CANADA
            else -> Locale.US
        }

    // MARK: - Companion Object (Static Utilities)

    companion object {

        /**
         * All supported currencies (loaded from JSON)
         */
        private var _allCurrencies: List<Currency>? = null

        /**
         * Get all currencies, loading from JSON if needed
         */
        fun getAll(context: Context): List<Currency> {
            if (_allCurrencies == null) {
                loadCurrencies(context)
            }
            return _allCurrencies ?: listOf(fallbackCurrency)
        }

        /**
         * Convenience property for accessing all currencies
         * Note: Requires context for first load
         */
        val all: List<Currency>
            get() = _allCurrencies ?: listOf(fallbackCurrency)

        /**
         * Get common currencies (marked as is_common in JSON)
         */
        fun getCommonCurrencies(context: Context): List<Currency> {
            return getAll(context).filter { it.isCommon }.sortedBy { it.displayName }
        }

        /**
         * Default currency for new users (based on device locale)
         */
        fun getDefault(context: Context): Currency {
            val deviceLocale = Locale.getDefault()
            val currencyCode = try {
                java.util.Currency.getInstance(deviceLocale).currencyCode
            } catch (e: Exception) {
                "USD"
            }

            return fromCode(currencyCode, context) ?: USD(context)
        }

        // MARK: - Predefined Common Currencies

        fun AED(context: Context): Currency = fromCode("AED", context) ?: fallbackCurrency
        fun USD(context: Context): Currency = fromCode("USD", context) ?: fallbackCurrency
        fun EUR(context: Context): Currency = fromCode("EUR", context) ?: fallbackCurrency
        fun GBP(context: Context): Currency = fromCode("GBP", context) ?: fallbackCurrency
        fun INR(context: Context): Currency = fromCode("INR", context) ?: fallbackCurrency
        fun SAR(context: Context): Currency = fromCode("SAR", context) ?: fallbackCurrency
        fun JPY(context: Context): Currency = fromCode("JPY", context) ?: fallbackCurrency
        fun CNY(context: Context): Currency = fromCode("CNY", context) ?: fallbackCurrency
        fun AUD(context: Context): Currency = fromCode("AUD", context) ?: fallbackCurrency
        fun CAD(context: Context): Currency = fromCode("CAD", context) ?: fallbackCurrency

        /**
         * Fallback currency if JSON loading fails
         */
        private val fallbackCurrency = Currency(
            code = "USD",
            symbol = "$",
            displayName = "US Dollar",
            pluralName = "US Dollars",
            symbolPosition = "before",
            decimalSeparator = ".",
            groupingSeparator = ",",
            decimalPlaces = 2,
            isCommon = true,
            voiceKeywords = listOf("dollar", "dollars", "usd", "$"),
            countryCodes = listOf("US"),
            exampleFormat = "$1,234.56"
        )

        /**
         * Load currencies from JSON file
         */
        private fun loadCurrencies(context: Context) {
            try {
                val inputStream = context.resources.openRawResource(
                    context.resources.getIdentifier("currencies", "raw", context.packageName)
                )

                val jsonString = inputStream.bufferedReader().use { it.readText() }
                val gson = Gson()

                val jsonObject = gson.fromJson(jsonString, Map::class.java)
                val currenciesMap = jsonObject["currencies"] as? Map<String, Any>

                if (currenciesMap == null) {
                    println("❌ Invalid JSON structure")
                    _allCurrencies = listOf(fallbackCurrency)
                    return
                }

                val currencies = mutableListOf<Currency>()

                for ((_, currencyData) in currenciesMap) {
                    try {
                        val currencyJson = gson.toJson(currencyData)
                        val currency = gson.fromJson(currencyJson, Currency::class.java)
                        currencies.add(currency)
                    } catch (e: Exception) {
                        println("❌ Failed to parse currency: ${e.message}")
                        continue
                    }
                }

                // Sort by display name
                _allCurrencies = currencies.sortedBy { it.displayName }

                println("✅ Loaded ${_allCurrencies?.size} currencies from JSON")

            } catch (e: Exception) {
                println("❌ Failed to load currencies from JSON: ${e.message}")
                e.printStackTrace()
                _allCurrencies = listOf(fallbackCurrency)
            }
        }

        /**
         * Create currency from ISO code string
         *
         * @param code ISO 4217 currency code
         * @param context Android context for loading currencies
         * @return Currency object or null if invalid
         */
        fun fromCode(code: String, context: Context): Currency? {
            return getAll(context).find { it.code.equals(code, ignoreCase = true) }
        }

        /**
         * Detect currency from text input (voice commands, manual entry)
         *
         * @param text Input text to analyze
         * @param context Android context for loading currencies
         * @return Detected currency or null if no match found
         */
        fun detectFromText(text: String, context: Context): Currency? {
            val lowercasedText = text.lowercase()

            for (currency in getAll(context)) {
                for (keyword in currency.voiceKeywords) {
                    if (lowercasedText.contains(keyword.lowercase())) {
                        return currency
                    }
                }
            }

            return null
        }

        /**
         * Initialize currencies early (call from Application.onCreate)
         */
        fun initialize(context: Context) {
            if (_allCurrencies == null) {
                loadCurrencies(context)
            }
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
fun String.toCurrency(context: Context): Currency? = Currency.fromCode(this, context)
