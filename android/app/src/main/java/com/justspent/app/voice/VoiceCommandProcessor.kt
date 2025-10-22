package com.justspent.app.voice

import com.justspent.app.data.model.ExpenseData
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import java.math.BigDecimal
import java.util.Locale
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class VoiceCommandProcessor @Inject constructor() {
    
    companion object {
        private const val MAX_AMOUNT = 999999.99
        private const val MIN_AMOUNT = 0.01
    }
    
    /**
     * Process a voice command and extract expense data
     */
    fun processVoiceCommand(
        command: String,
        locale: Locale = Locale.getDefault()
    ): Result<ExpenseData> {
        return try {
            val cleanCommand = command.trim().lowercase()
            
            val amount = extractAmount(cleanCommand)
            val currency = extractCurrency(cleanCommand, locale)
            val category = extractCategory(cleanCommand)
            val merchant = extractMerchant(cleanCommand)
            val notes = extractNotes(cleanCommand)
            val transactionDate = extractDate(cleanCommand)
            
            // Validate extracted data
            validateExpenseData(amount, currency, category)
            
            val expenseData = ExpenseData(
                amount = amount,
                currency = currency,
                category = category,
                merchant = merchant,
                notes = notes,
                transactionDate = transactionDate,
                source = "voice_assistant",
                voiceTranscript = command
            )
            
            Result.success(expenseData)
            
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Extract monetary amount from voice command
     */
    private fun extractAmount(command: String): BigDecimal {
        // Patterns for different amount formats
        val patterns = listOf(
            // $25.50, $25, $1,234.56
            Regex("""\$(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)"""),
            // 25.50 dollars, 25 dollars, 1,234.56 dollars
            Regex("""(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*dollars?"""),
            // 25.50 AED, 25 AED, 1,234.56 AED
            Regex("""(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*(?:AED|aed|dirhams?)"""),
            // 25.50 euros, 25 euros
            Regex("""(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*euros?"""),
            // 25.50 pounds, 25 pounds
            Regex("""(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*pounds?"""),
            // Plain numbers: 25.50, 25, 1,234.56
            Regex("""(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)""")
        )
        
        for (pattern in patterns) {
            val match = pattern.find(command)
            if (match != null) {
                val amountStr = match.groupValues[1].replace(",", "")
                try {
                    val amount = BigDecimal(amountStr)
                    if (amount >= BigDecimal(MIN_AMOUNT) && amount <= BigDecimal(MAX_AMOUNT)) {
                        return amount
                    }
                } catch (e: NumberFormatException) {
                    continue
                }
            }
        }
        
        // Try to extract written numbers (twenty-five, fifty, etc.)
        extractWrittenAmount(command)?.let { return it }
        
        throw IllegalArgumentException("Invalid or missing amount")
    }
    
    /**
     * Extract written numbers like "twenty-five dollars", "one hundred", "two thousand"
     * Handles compound numbers and multipliers (hundred, thousand)
     */
    private fun extractWrittenAmount(command: String): BigDecimal? {
        val ones = mapOf(
            "zero" to 0, "one" to 1, "two" to 2, "three" to 3, "four" to 4, "five" to 5,
            "six" to 6, "seven" to 7, "eight" to 8, "nine" to 9, "ten" to 10,
            "eleven" to 11, "twelve" to 12, "thirteen" to 13, "fourteen" to 14, "fifteen" to 15,
            "sixteen" to 16, "seventeen" to 17, "eighteen" to 18, "nineteen" to 19
        )

        val tens = mapOf(
            "twenty" to 20, "thirty" to 30, "forty" to 40, "fifty" to 50,
            "sixty" to 60, "seventy" to 70, "eighty" to 80, "ninety" to 90
        )

        val multipliers = mapOf(
            "hundred" to 100,
            "thousand" to 1000
        )

        // Extract potential amount substring (words between action word and currency/category)
        val amountPattern = Regex("""(?:spent|spend|paid|pay|cost)\s+([\w\s]+?)\s+(?:dollars?|dirhams?|aed|euros?|pounds?|for|on|at)""", RegexOption.IGNORE_CASE)
        val amountMatch = amountPattern.find(command)
        val amountText = amountMatch?.groupValues?.get(1)?.trim()?.lowercase() ?: command.lowercase()

        val words = amountText.split(Regex("""\s+"""))
        var total = 0
        var current = 0

        for (word in words) {
            when {
                ones.containsKey(word) -> {
                    current += ones[word]!!
                }
                tens.containsKey(word) -> {
                    current += tens[word]!!
                }
                word == "hundred" -> {
                    if (current == 0) current = 1 // "hundred" alone means "one hundred"
                    current *= 100
                }
                word == "thousand" -> {
                    if (current == 0) current = 1 // "thousand" alone means "one thousand"
                    current *= 1000
                    total += current
                    current = 0
                }
            }
        }

        total += current

        return if (total > 0 && total <= MAX_AMOUNT) BigDecimal(total) else null
    }
    
    /**
     * Extract currency from command or determine from locale
     */
    private fun extractCurrency(command: String, locale: Locale): String {
        return when {
            command.contains("dollars?".toRegex()) || command.contains("$") -> "USD"
            command.contains("AED|aed|dirhams?".toRegex()) -> "AED"
            command.contains("euros?".toRegex()) || command.contains("€") -> "EUR"
            command.contains("pounds?".toRegex()) || command.contains("£") -> "GBP"
            command.contains("rupees?".toRegex()) || command.contains("₹") -> "INR"
            command.contains("riyals?".toRegex()) -> "SAR"
            else -> {
                // Determine from locale
                when (locale.country) {
                    "AE" -> "AED"
                    "GB" -> "GBP"
                    "IN" -> "INR"
                    "SA" -> "SAR"
                    else -> "USD" // Default
                }
            }
        }
    }
    
    /**
     * Extract expense category from command
     * Enhanced with broader keyword coverage
     */
    private fun extractCategory(command: String): String {
        val categoryMappings = mapOf(
            // Food & Dining - comprehensive food-related keywords
            listOf("food", "tea", "coffee", "lunch", "dinner", "breakfast", "restaurant",
                   "meal", "drink", "cafe", "dining", "eat", "ate", "snack", "brunch",
                   "takeout", "takeaway", "delivery", "pizza", "burger", "sandwich",
                   "sushi", "dessert", "ice cream", "bakery", "starbucks", "mcdonald") to "Food & Dining",

            // Grocery - food shopping related
            listOf("grocery", "groceries", "supermarket", "market", "food shopping",
                   "vegetables", "fruits", "produce", "walmart", "carrefour", "lulu") to "Grocery",

            // Transportation - comprehensive transport and fuel keywords
            listOf("gas", "fuel", "taxi", "uber", "transport", "transportation", "parking",
                   "petrol", "toll", "careem", "lyft", "metro", "subway", "train", "bus",
                   "diesel", "station", "refuel", "fill up", "car", "vehicle", "ride",
                   "trip", "travel", "flight", "airline", "ticket") to "Transportation",

            // Shopping - retail and purchases
            listOf("shopping", "clothes", "clothing", "store", "mall", "purchase", "buy", "bought",
                   "shoes", "accessories", "fashion", "retail", "amazon", "online shopping",
                   "electronics", "gadget", "phone", "laptop") to "Shopping",

            // Entertainment - leisure and fun activities
            listOf("movie", "cinema", "concert", "entertainment", "fun", "games", "theatre",
                   "sports", "gym", "fitness", "netflix", "streaming", "spotify", "music",
                   "hobby", "recreation", "amusement", "park") to "Entertainment",

            // Bills & Utilities - recurring expenses
            listOf("bill", "bills", "rent", "utility", "utilities", "electricity", "water",
                   "internet", "phone", "subscription", "insurance", "mortgage", "loan",
                   "payment", "recurring", "monthly", "annual") to "Bills & Utilities",

            // Healthcare - medical expenses
            listOf("healthcare", "health", "doctor", "hospital", "medicine", "medical",
                   "pharmacy", "clinic", "prescription", "dentist", "therapy", "checkup",
                   "emergency", "surgery", "treatment") to "Healthcare",

            // Education - learning and development
            listOf("education", "school", "course", "training", "books", "learning", "tuition",
                   "college", "university", "class", "workshop", "seminar", "certification",
                   "textbook", "supplies", "fees") to "Education"
        )

        // Check in priority order (Food & Dining first)
        for ((keywords, category) in categoryMappings) {
            if (keywords.any { command.contains(it) }) {
                return category
            }
        }

        return "Other"
    }
    
    /**
     * Extract merchant name from command
     */
    private fun extractMerchant(command: String): String? {
        // Patterns to extract merchant names
        val patterns = listOf(
            Regex("""at\s+([A-Za-z0-9\s'&.-]+?)(?:\s+for|\s+on|$)""", RegexOption.IGNORE_CASE),
            Regex("""from\s+([A-Za-z0-9\s'&.-]+?)(?:\s+for|\s+on|$)""", RegexOption.IGNORE_CASE),
            Regex("""to\s+([A-Za-z0-9\s'&.-]+?)(?:\s+for|\s+on|$)""", RegexOption.IGNORE_CASE)
        )
        
        for (pattern in patterns) {
            val match = pattern.find(command)
            if (match != null) {
                val merchant = match.groupValues[1].trim()
                if (merchant.length > 2 && merchant.length <= 100) {
                    return merchant
                }
            }
        }
        
        return null
    }
    
    /**
     * Extract notes from command
     */
    private fun extractNotes(command: String): String? {
        val notePatterns = listOf(
            Regex("""for\s+(.+)$""", RegexOption.IGNORE_CASE),
            Regex("""note:\s*(.+)$""", RegexOption.IGNORE_CASE)
        )
        
        for (pattern in notePatterns) {
            val match = pattern.find(command)
            if (match != null) {
                val note = match.groupValues[1].trim()
                if (note.length <= 500) {
                    return note
                }
            }
        }
        
        return null
    }
    
    /**
     * Extract date from command, defaulting to current date
     */
    private fun extractDate(command: String): kotlinx.datetime.LocalDateTime {
        val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())
        
        return when {
            command.contains("yesterday") -> {
                val oneDayDuration = kotlin.time.Duration.parse("24h")
                val yesterdayInstant = Clock.System.now().minus(oneDayDuration)
                yesterdayInstant.toLocalDateTime(TimeZone.currentSystemDefault())
            }
            command.contains("today") || command.contains("just") -> now
            command.contains("this morning") -> kotlinx.datetime.LocalDateTime(now.date, kotlinx.datetime.LocalTime(9, 0))
            command.contains("this afternoon") -> kotlinx.datetime.LocalDateTime(now.date, kotlinx.datetime.LocalTime(14, 0))
            command.contains("this evening") -> kotlinx.datetime.LocalDateTime(now.date, kotlinx.datetime.LocalTime(19, 0))
            else -> now
        }
    }
    
    /**
     * Validate extracted expense data
     */
    private fun validateExpenseData(amount: BigDecimal, currency: String, category: String) {
        if (amount <= BigDecimal.ZERO) {
            throw IllegalArgumentException("Amount must be greater than zero")
        }
        
        if (amount > BigDecimal(MAX_AMOUNT)) {
            throw IllegalArgumentException("Amount exceeds maximum limit")
        }
        
        val supportedCurrencies = listOf("USD", "AED", "EUR", "GBP", "INR", "SAR")
        if (!supportedCurrencies.contains(currency)) {
            throw IllegalArgumentException("Unsupported currency: $currency")
        }
        
        if (category.isBlank()) {
            throw IllegalArgumentException("Category cannot be empty")
        }
    }
    
    /**
     * Get confidence score for the parsed command
     */
    fun getConfidenceScore(command: String): Double {
        val cleanCommand = command.trim().lowercase()
        var score = 0.0
        
        // Check for amount indicators
        if (hasAmountIndicators(cleanCommand)) score += 0.3
        
        // Check for category indicators
        if (hasCategoryIndicators(cleanCommand)) score += 0.3
        
        // Check for expense action words
        if (hasExpenseActionWords(cleanCommand)) score += 0.2
        
        // Check for merchant indicators
        if (hasMerchantIndicators(cleanCommand)) score += 0.1
        
        // Check for currency indicators
        if (hasCurrencyIndicators(cleanCommand)) score += 0.1
        
        return minOf(score, 1.0)
    }
    
    private fun hasAmountIndicators(command: String): Boolean {
        return command.matches(""".*\d+.*""".toRegex())
    }
    
    private fun hasCategoryIndicators(command: String): Boolean {
        val categoryWords = listOf("food", "grocery", "transport", "shopping", "entertainment")
        return categoryWords.any { command.contains(it) }
    }
    
    private fun hasExpenseActionWords(command: String): Boolean {
        val actionWords = listOf("spent", "spend", "paid", "pay", "cost", "bought", "purchase", "buy")
        return actionWords.any { command.contains(it) }
    }
    
    private fun hasMerchantIndicators(command: String): Boolean {
        return command.contains(" at ") || command.contains(" from ") || command.contains(" to ")
    }
    
    private fun hasCurrencyIndicators(command: String): Boolean {
        return command.contains("$") || command.contains("dollar") || command.contains("AED") || 
               command.contains("euro") || command.contains("pound")
    }
    
    /**
     * Generate suggested phrases for voice training
     */
    fun getSuggestedPhrases(locale: Locale = Locale.getDefault()): List<String> {
        val basePhrases = listOf(
            "I just spent 25 dollars on food",
            "I paid 50 dollars for groceries at the supermarket",
            "Log 15 dollars for lunch",
            "I spent 30 dollars on gas",
            "I bought coffee for 5 dollars",
            "Add 100 dollars shopping expense",
            "I just paid 20 dollars for entertainment"
        )
        
        return when (locale.country) {
            "AE" -> basePhrases.map { it.replace("dollars", "dirhams").replace("AED", "AED") } +
                    listOf(
                        "I just spent 50 AED on groceries",
                        "I paid 25 dirhams for lunch",
                        "Log 100 AED for shopping"
                    )
            "GB" -> basePhrases.map { it.replace("dollars", "pounds") } +
                    listOf(
                        "I just spent 20 pounds on petrol",
                        "I paid 15 pounds for lunch"
                    )
            else -> basePhrases
        }
    }
}