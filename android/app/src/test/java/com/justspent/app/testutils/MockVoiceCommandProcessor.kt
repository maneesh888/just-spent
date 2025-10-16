package com.justspent.app.testutils

import com.justspent.app.data.model.ExpenseData
import com.justspent.app.voice.VoiceCommandProcessor
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import java.math.BigDecimal
import java.util.Locale

/**
 * Mock implementation of VoiceCommandProcessor for testing
 * Provides predictable responses for test scenarios
 */
class MockVoiceCommandProcessor : VoiceCommandProcessor() {

    private val predefinedResponses = mutableMapOf<String, Result<ExpenseData>>()
    private val confidenceScores = mutableMapOf<String, Double>()
    private val suggestedPhrases = mutableMapOf<Locale, List<String>>()
    
    var shouldFail = false
    var failureException: Exception = Exception("Mock failure")
    var defaultConfidenceScore = 0.9
    
    // Track method calls for verification
    val processCommandCalls = mutableListOf<Pair<String, Locale>>()
    val confidenceScoreCalls = mutableListOf<String>()
    val suggestedPhrasesCalls = mutableListOf<Locale>()

    /**
     * Override to provide predictable responses for testing
     */
    override fun processVoiceCommand(command: String, locale: Locale): Result<ExpenseData> {
        processCommandCalls.add(command to locale)
        
        if (shouldFail) {
            return Result.failure(failureException)
        }
        
        // Return predefined response if available
        predefinedResponses[command]?.let { return it }
        
        // Generate mock response based on command
        return try {
            val mockExpenseData = generateMockExpenseFromCommand(command, locale)
            Result.success(mockExpenseData)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Override to provide predictable confidence scores
     */
    override fun getConfidenceScore(command: String): Double {
        confidenceScoreCalls.add(command)
        
        return confidenceScores[command] ?: calculateMockConfidence(command)
    }

    /**
     * Override to provide predictable suggested phrases
     */
    override fun getSuggestedPhrases(locale: Locale): List<String> {
        suggestedPhrasesCalls.add(locale)
        
        return suggestedPhrases[locale] ?: generateDefaultSuggestions(locale)
    }

    // ===== MOCK CONFIGURATION METHODS =====

    /**
     * Set a specific response for a command
     */
    fun setResponse(command: String, response: Result<ExpenseData>) {
        predefinedResponses[command] = response
    }

    /**
     * Set a specific confidence score for a command
     */
    fun setConfidenceScore(command: String, score: Double) {
        confidenceScores[command] = score
    }

    /**
     * Set suggested phrases for a locale
     */
    fun setSuggestedPhrases(locale: Locale, phrases: List<String>) {
        suggestedPhrases[locale] = phrases
    }

    /**
     * Configure mock to fail all operations
     */
    fun configureMockFailure(exception: Exception = Exception("Mock failure")) {
        shouldFail = true
        failureException = exception
    }

    /**
     * Reset mock to success mode
     */
    fun resetToSuccess() {
        shouldFail = false
    }

    /**
     * Clear all predefined responses and call history
     */
    fun reset() {
        predefinedResponses.clear()
        confidenceScores.clear()
        suggestedPhrases.clear()
        processCommandCalls.clear()
        confidenceScoreCalls.clear()
        suggestedPhrasesCalls.clear()
        shouldFail = false
        defaultConfidenceScore = 0.9
    }

    // ===== VERIFICATION METHODS =====

    /**
     * Verify that processVoiceCommand was called with specific parameters
     */
    fun verifyProcessCommandCalled(command: String, locale: Locale = Locale.getDefault()): Boolean {
        return processCommandCalls.contains(command to locale)
    }

    /**
     * Verify that getConfidenceScore was called with specific command
     */
    fun verifyConfidenceScoreCalled(command: String): Boolean {
        return confidenceScoreCalls.contains(command)
    }

    /**
     * Verify that getSuggestedPhrases was called with specific locale
     */
    fun verifySuggestedPhrasesCalled(locale: Locale = Locale.getDefault()): Boolean {
        return suggestedPhrasesCalls.contains(locale)
    }

    /**
     * Get the number of times processVoiceCommand was called
     */
    fun getProcessCommandCallCount(): Int = processCommandCalls.size

    /**
     * Get the last command that was processed
     */
    fun getLastProcessedCommand(): String? = processCommandCalls.lastOrNull()?.first

    // ===== PRIVATE HELPER METHODS =====

    private fun generateMockExpenseFromCommand(command: String, locale: Locale): ExpenseData {
        val lowerCommand = command.lowercase()
        
        // Extract amount (simplified mock logic)
        val amount = extractMockAmount(lowerCommand)
        
        // Extract currency based on locale or command content
        val currency = extractMockCurrency(lowerCommand, locale)
        
        // Extract category
        val category = extractMockCategory(lowerCommand)
        
        // Extract merchant
        val merchant = extractMockMerchant(lowerCommand)
        
        return ExpenseData(
            amount = amount,
            currency = currency,
            category = category,
            merchant = merchant,
            notes = null,
            transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            source = "voice_assistant",
            voiceTranscript = command
        )
    }

    private fun extractMockAmount(command: String): BigDecimal {
        // Simple regex to find numbers
        val numberPattern = Regex("""(\d+(?:\.\d{2})?)""")
        val match = numberPattern.find(command)
        return if (match != null) {
            BigDecimal(match.value)
        } else {
            // Default amount if none found
            BigDecimal("25.00")
        }
    }

    private fun extractMockCurrency(command: String, locale: Locale): String {
        return when {
            command.contains("aed") || command.contains("dirham") -> "AED"
            command.contains("euro") || command.contains("eur") -> "EUR"
            command.contains("pound") || command.contains("gbp") -> "GBP"
            command.contains("rupee") || command.contains("inr") -> "INR"
            command.contains("riyal") || command.contains("sar") -> "SAR"
            command.contains("dollar") || command.contains("usd") -> "USD"
            else -> when (locale.country) {
                "AE" -> "AED"
                "GB" -> "GBP"
                "IN" -> "INR"
                "SA" -> "SAR"
                else -> "USD"
            }
        }
    }

    private fun extractMockCategory(command: String): String {
        return when {
            command.contains("food") || command.contains("lunch") || 
            command.contains("dinner") || command.contains("coffee") -> "Food & Dining"
            command.contains("grocery") || command.contains("groceries") -> "Grocery"
            command.contains("gas") || command.contains("fuel") || 
            command.contains("taxi") || command.contains("transport") -> "Transportation"
            command.contains("shopping") || command.contains("clothes") || 
            command.contains("mall") -> "Shopping"
            command.contains("movie") || command.contains("entertainment") -> "Entertainment"
            command.contains("bill") || command.contains("utility") -> "Bills & Utilities"
            command.contains("doctor") || command.contains("medicine") || 
            command.contains("health") -> "Healthcare"
            command.contains("school") || command.contains("education") -> "Education"
            else -> "Other"
        }
    }

    private fun extractMockMerchant(command: String): String? {
        val patterns = listOf(
            Regex("""at\s+([A-Za-z0-9\s'&.-]+?)(?:\s|$)"""),
            Regex("""from\s+([A-Za-z0-9\s'&.-]+?)(?:\s|$)""")
        )
        
        for (pattern in patterns) {
            val match = pattern.find(command)
            if (match != null) {
                val merchant = match.groupValues[1].trim()
                if (merchant.length > 2) {
                    return merchant
                }
            }
        }
        
        return null
    }

    private fun calculateMockConfidence(command: String): Double {
        val lowerCommand = command.lowercase()
        var score = 0.0
        
        // Check for amount
        if (Regex("""\d+""").containsMatchIn(lowerCommand)) score += 0.3
        
        // Check for currency
        if (lowerCommand.contains("dollar") || lowerCommand.contains("aed") || 
            lowerCommand.contains("euro")) score += 0.2
        
        // Check for category keywords
        val categoryWords = listOf("food", "grocery", "transport", "shopping")
        if (categoryWords.any { lowerCommand.contains(it) }) score += 0.3
        
        // Check for action words
        if (lowerCommand.contains("spent") || lowerCommand.contains("paid")) score += 0.2
        
        return minOf(score, 1.0)
    }

    private fun generateDefaultSuggestions(locale: Locale): List<String> {
        return when (locale.country) {
            "AE" -> listOf(
                "I just spent 50 AED on groceries",
                "I paid 25 dirhams for lunch",
                "Log 100 AED for shopping"
            )
            "GB" -> listOf(
                "I just spent 20 pounds on petrol",
                "I paid 15 pounds for lunch",
                "Log 50 pounds for shopping"
            )
            else -> listOf(
                "I just spent 25 dollars on groceries",
                "I paid 50 dollars for lunch",
                "Log 15 dollars for coffee"
            )
        }
    }
}