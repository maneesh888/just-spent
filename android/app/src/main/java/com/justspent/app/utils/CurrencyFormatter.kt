package com.justspent.app.utils

import com.justspent.app.data.model.Currency
import java.math.BigDecimal
import java.math.RoundingMode
import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.text.NumberFormat
import java.util.Locale

/**
 * Provides currency formatting with proper locale support and customization
 */
object CurrencyFormatter {

    /**
     * Format amount with currency symbol and Western numerals
     * Always uses English numerals (0-9) regardless of device locale
     *
     * @param amount The monetary amount to format
     * @param currency The currency to use for formatting
     * @param showSymbol Whether to include the currency symbol (default: true)
     * @param showCode Whether to include the currency code (default: false)
     * @return Formatted currency string (e.g., "AED 100.00", "$50.25")
     */
    fun format(
        amount: BigDecimal,
        currency: Currency,
        showSymbol: Boolean = true,
        showCode: Boolean = false
    ): String {
        return try {
            val formatter = createFormatter(currency)
            val formattedAmount = formatter.format(amount)

            when {
                !showSymbol && !showCode -> formattedAmount
                showSymbol && !showCode -> formatWithSymbol(formattedAmount, currency)
                !showSymbol && showCode -> "$formattedAmount ${currency.code}"
                else -> "${formatWithSymbol(formattedAmount, currency)} (${currency.code})"
            }
        } catch (e: Exception) {
            // Fallback to basic formatting
            basicFormat(amount, currency, showSymbol)
        }
    }

    /**
     * Format amount for compact display (e.g., in lists)
     *
     * @param amount The monetary amount to format
     * @param currency The currency to use for formatting
     * @return Compact formatted string
     */
    fun formatCompact(amount: BigDecimal, currency: Currency): String {
        return format(amount, currency, showSymbol = true, showCode = false)
    }

    /**
     * Format amount for detailed display (e.g., in forms, detail views)
     *
     * @param amount The monetary amount to format
     * @param currency The currency to use for formatting
     * @return Detailed formatted string with currency code
     */
    fun formatDetailed(amount: BigDecimal, currency: Currency): String {
        return format(amount, currency, showSymbol = true, showCode = true)
    }

    /**
     * Parse currency string to BigDecimal amount
     *
     * @param string String to parse (e.g., "د.إ 100", "$50.25")
     * @param currency Currency context for parsing
     * @return Parsed BigDecimal value or null if parsing fails
     */
    fun parse(string: String, currency: Currency): BigDecimal? {
        return try {
            // Remove common currency symbols and whitespace
            var cleanedString = string
            Currency.all.forEach { curr ->
                cleanedString = cleanedString.replace(curr.symbol, "")
                cleanedString = cleanedString.replace(curr.code, "")
            }
            cleanedString = cleanedString.trim()
                .replace(",", "")  // Remove grouping separators
                .replace(" ", "")

            BigDecimal(cleanedString).setScale(currency.decimalPlaces, RoundingMode.HALF_UP)
        } catch (e: Exception) {
            null
        }
    }

    // MARK: - Private Helper Methods

    /**
     * Create a DecimalFormat configured for the specified currency
     * Always uses English (US) locale for Western numerals
     *
     * @param currency The currency to configure for
     * @return Configured DecimalFormat
     */
    private fun createFormatter(currency: Currency): DecimalFormat {
        // Force English (US) locale to always show Western numerals (0-9)
        val symbols = DecimalFormatSymbols(Locale.US).apply {
            decimalSeparator = currency.decimalSeparator[0]
            groupingSeparator = currency.groupingSeparator[0]
        }

        return DecimalFormat().apply {
            decimalFormatSymbols = symbols
            minimumFractionDigits = currency.decimalPlaces
            maximumFractionDigits = currency.decimalPlaces
            isGroupingUsed = true
            roundingMode = RoundingMode.HALF_UP
        }
    }

    /**
     * Format amount with currency symbol in proper position
     *
     * @param formattedAmount The already formatted amount string
     * @param currency The currency
     * @return String with symbol in correct position
     */
    private fun formatWithSymbol(formattedAmount: String, currency: Currency): String {
        return if (currency.isRTL) {
            "${currency.symbol} $formattedAmount"
        } else {
            when (currency) {
                Currency.USD, Currency.GBP, Currency.INR -> "${currency.symbol}$formattedAmount"
                Currency.EUR -> "$formattedAmount${currency.symbol}"
                else -> "${currency.symbol} $formattedAmount"
            }
        }
    }

    /**
     * Basic formatting fallback when DecimalFormat fails
     *
     * @param amount The amount to format
     * @param currency The currency
     * @param showSymbol Whether to show symbol
     * @return Basic formatted string
     */
    private fun basicFormat(
        amount: BigDecimal,
        currency: Currency,
        showSymbol: Boolean
    ): String {
        val amountString = String.format("%.2f", amount)

        return if (showSymbol) {
            if (currency.isRTL) {
                "${currency.symbol} $amountString"
            } else {
                "${currency.symbol}$amountString"
            }
        } else {
            amountString
        }
    }
}

// MARK: - Extension Functions

/**
 * Format this BigDecimal as currency
 */
fun BigDecimal.formatted(currency: Currency): String {
    return CurrencyFormatter.format(this, currency)
}

/**
 * Format this BigDecimal compactly
 */
fun BigDecimal.formattedCompact(currency: Currency): String {
    return CurrencyFormatter.formatCompact(this, currency)
}

/**
 * Format this BigDecimal with full details
 */
fun BigDecimal.formattedDetailed(currency: Currency): String {
    return CurrencyFormatter.formatDetailed(this, currency)
}

/**
 * Parse this string as a currency amount
 */
fun String.parsedAsCurrency(currency: Currency): BigDecimal? {
    return CurrencyFormatter.parse(this, currency)
}
