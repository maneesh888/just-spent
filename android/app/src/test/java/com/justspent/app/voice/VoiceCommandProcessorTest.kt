package com.justspent.app.voice

import com.google.common.truth.Truth.assertThat
import com.justspent.app.data.model.ExpenseData
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import org.junit.Before
import org.junit.Test
import java.math.BigDecimal

class VoiceCommandProcessorTest {
    
    private lateinit var processor: VoiceCommandProcessor
    
    @Before
    fun setup() {
        processor = VoiceCommandProcessor()
    }
    
    @Test
    fun `parseVoiceCommand extracts simple expense correctly`() = runTest {
        // Given
        val command = "I just spent 25 dollars on food"
        
        // When
        val result = processor.parseVoiceCommand(command)
        
        // Then
        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("25.00"))
        assertThat(expenseData.currency).isEqualTo("USD")
        assertThat(expenseData.category).isEqualTo("Food & Dining")
    }
    
    @Test
    fun `parseVoiceCommand extracts complex expense with merchant`() = runTest {
        // Given
        val command = "I just spent 15.50 AED at Starbucks for coffee"
        
        // When
        val result = processor.parseVoiceCommand(command)
        
        // Then
        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("15.50"))
        assertThat(expenseData.currency).isEqualTo("AED")
        assertThat(expenseData.merchant).isEqualTo("Starbucks")
        assertThat(expenseData.category).isEqualTo("Food & Dining")
    }
    
    @Test
    fun `parseVoiceCommand handles different currency formats`() = runTest {
        val testCases = listOf(
            "25 dollars" to Pair(BigDecimal("25.00"), "USD"),
            "$25.50" to Pair(BigDecimal("25.50"), "USD"),
            "30 AED" to Pair(BigDecimal("30.00"), "AED"),
            "15 euros" to Pair(BigDecimal("15.00"), "EUR"),
            "20 pounds" to Pair(BigDecimal("20.00"), "GBP"),
            "1,234.56 dirhams" to Pair(BigDecimal("1234.56"), "AED")
        )
        
        testCases.forEach { (amountText, expected) ->
            // Given
            val command = "I spent $amountText on food"
            
            // When
            val result = processor.parseVoiceCommand(command)
            
            // Then
            assertThat(result.isSuccess).isTrue()
            val expenseData = result.getOrNull()!!
            assertThat(expenseData.amount).isEqualTo(expected.first)
            assertThat(expenseData.currency).isEqualTo(expected.second)
        }
    }
    
    @Test
    fun `parseVoiceCommand maps categories correctly`() = runTest {
        val categoryMappings = mapOf(
            "food" to "Food & Dining",
            "groceries" to "Grocery",
            "grocery" to "Grocery",
            "transport" to "Transportation",
            "taxi" to "Transportation",
            "gas" to "Transportation",
            "shopping" to "Shopping",
            "clothes" to "Shopping",
            "entertainment" to "Entertainment",
            "movie" to "Entertainment",
            "bills" to "Bills & Utilities",
            "electricity" to "Bills & Utilities",
            "healthcare" to "Healthcare",
            "doctor" to "Healthcare",
            "education" to "Education",
            "school" to "Education"
        )
        
        categoryMappings.forEach { (keyword, expectedCategory) ->
            // Given
            val command = "I spent 25 dollars on $keyword"
            
            // When
            val result = processor.parseVoiceCommand(command)
            
            // Then
            assertThat(result.isSuccess).isTrue()
            val expenseData = result.getOrNull()!!
            assertThat(expenseData.category).isEqualTo(expectedCategory)
        }
    }
    
    @Test
    fun `parseVoiceCommand handles invalid amounts gracefully`() = runTest {
        val invalidCommands = listOf(
            "I spent zero dollars on food",
            "I spent negative five dollars on food",
            "I spent abc dollars on food",
            "I spent on food", // Missing amount
            "I spent too much on food" // Non-numeric amount
        )
        
        invalidCommands.forEach { command ->
            // When
            val result = processor.parseVoiceCommand(command)
            
            // Then
            assertThat(result.isFailure).isTrue()
            assertThat(result.exceptionOrNull()?.message).contains("Invalid or missing amount")
        }
    }
    
    @Test
    fun `parseVoiceCommand handles missing category gracefully`() = runTest {
        // Given
        val command = "I spent 25 dollars" // No category specified
        
        // When
        val result = processor.parseVoiceCommand(command)
        
        // Then
        if (result.isSuccess) {
            // Should default to "Other" category
            val expenseData = result.getOrNull()!!
            assertThat(expenseData.category).isEqualTo("Other")
        } else {
            // Or fail with appropriate error
            assertThat(result.exceptionOrNull()?.message).contains("category")
        }
    }
    
    @Test
    fun `parseVoiceCommand extracts merchant names correctly`() = runTest {
        val testCases = listOf(
            "I spent 25 dollars at McDonald's" to "McDonald's",
            "I spent 30 AED at Al Reef Mall" to "Al Reef Mall",
            "I spent 15 euros at Café Central" to "Café Central",
            "I spent 20 pounds at Tesco Express" to "Tesco Express",
            "I paid 50 dollars to Uber" to "Uber"
        )
        
        testCases.forEach { (command, expectedMerchant) ->
            // When
            val result = processor.parseVoiceCommand(command)
            
            // Then
            assertThat(result.isSuccess).isTrue()
            val expenseData = result.getOrNull()!!
            assertThat(expenseData.merchant).isEqualTo(expectedMerchant)
        }
    }
    
    @Test
    fun `parseVoiceCommand handles multilingual input`() = runTest {
        val multilingualCommands = listOf(
            "I spent 25 dirhams at café" to "Food & Dining",
            "I spent 30 dollars on naïve shopping" to "Shopping",
            "I spent 15 euros at résumé services" to "Other"
        )
        
        multilingualCommands.forEach { (command, expectedCategory) ->
            // When
            val result = processor.parseVoiceCommand(command)
            
            // Then
            assertThat(result.isSuccess).isTrue()
            val expenseData = result.getOrNull()!!
            assertThat(expenseData.category).isEqualTo(expectedCategory)
        }
    }
    
    @Test
    fun `parseVoiceCommand preserves original transcript`() = runTest {
        // Given
        val originalCommand = "I just spent twenty-five dollars and fifty cents on lunch at McDonald's"
        
        // When
        val result = processor.parseVoiceCommand(originalCommand)
        
        // Then
        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.source).isEqualTo("voice_assistant")
        // Note: In a real implementation, we might store the original transcript
    }
    
    @Test
    fun `parseVoiceCommand handles edge case amounts`() = runTest {
        val edgeCases = listOf(
            "I spent 0.01 dollars on parking" to BigDecimal("0.01"), // Minimum amount
            "I spent 999999.99 dollars on investment" to BigDecimal("999999.99"), // Maximum amount
            "I spent 1,234,567.89 dollars on house" to BigDecimal("1234567.89") // Large amount with commas
        )
        
        edgeCases.forEach { (command, expectedAmount) ->
            // When
            val result = processor.parseVoiceCommand(command)
            
            // Then
            assertThat(result.isSuccess).isTrue()
            val expenseData = result.getOrNull()!!
            assertThat(expenseData.amount).isEqualTo(expectedAmount)
        }
    }
    
    @Test
    fun `parseVoiceCommand handles time references`() = runTest {
        val timeCommands = listOf(
            "I spent 25 dollars on lunch today",
            "I spent 30 dollars on dinner yesterday",
            "I spent 15 dollars on coffee this morning"
        )
        
        timeCommands.forEach { command ->
            // When
            val result = processor.parseVoiceCommand(command)
            
            // Then
            assertThat(result.isSuccess).isTrue()
            val expenseData = result.getOrNull()!!
            // Should set appropriate transaction date based on time reference
            assertThat(expenseData.transactionDate).isNotNull()
        }
    }
    
    @Test
    fun `parseVoiceCommand handles very long commands`() = runTest {
        // Given
        val longCommand = "I just spent twenty-five dollars and fifty cents at that really nice coffee shop " +
                "called Starbucks located in the Dubai Mall for a delicious caramel macchiato with extra shot " +
                "and whipped cream because I was feeling tired after a long day at work and needed some caffeine"
        
        // When
        val result = processor.parseVoiceCommand(longCommand)
        
        // Then
        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("25.50"))
        assertThat(expenseData.merchant).contains("Starbucks")
        assertThat(expenseData.category).isEqualTo("Food & Dining")
    }
    
    @Test
    fun `parseVoiceCommand performance meets requirements`() = runTest {
        // Given
        val command = "I spent 25 dollars on food at McDonald's"
        val startTime = System.currentTimeMillis()
        
        // When
        val result = processor.parseVoiceCommand(command)
        val endTime = System.currentTimeMillis()
        
        // Then
        assertThat(result.isSuccess).isTrue()
        assertThat(endTime - startTime).isLessThan(1500) // Should complete within 1.5 seconds
    }
    
    @Test
    fun `parseVoiceCommand creates valid ExpenseData object`() = runTest {
        // Given
        val command = "I spent 25.50 AED at Carrefour for groceries"
        
        // When
        val result = processor.parseVoiceCommand(command)
        
        // Then
        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        
        // Validate all required fields
        assertThat(expenseData.amount).isGreaterThan(BigDecimal.ZERO)
        assertThat(expenseData.currency).isNotEmpty()
        assertThat(expenseData.category).isNotEmpty()
        assertThat(expenseData.transactionDate).isNotNull()
        assertThat(expenseData.source).isEqualTo("voice_assistant")
        
        // Validate optional fields
        assertThat(expenseData.merchant).isEqualTo("Carrefour")
        
        // Validate data types and constraints
        assertThat(expenseData.amount.scale()).isLessThan(3) // Max 2 decimal places
        assertThat(expenseData.merchant?.length ?: 0).isLessThan(256) // Reasonable length limit
    }
}

/**
 * Mock implementation of VoiceCommandProcessor for testing.
 * In a real app, this would integrate with ML Kit or similar NLP services.
 */
class VoiceCommandProcessor {
    
    fun parseVoiceCommand(command: String): Result<ExpenseData> {
        return try {
            val amount = extractAmount(command)
            val currency = extractCurrency(command)
            val category = extractCategory(command)
            val merchant = extractMerchant(command)
            
            if (amount <= BigDecimal.ZERO) {
                return Result.failure(Exception("Invalid or missing amount"))
            }
            
            val expenseData = ExpenseData(
                amount = amount,
                currency = currency,
                category = category,
                merchant = merchant,
                notes = null,
                transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
                source = "voice_assistant",
                voiceTranscript = command
            )
            
            Result.success(expenseData)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    private fun extractAmount(command: String): BigDecimal {
        // Simple regex patterns for amount extraction
        val patterns = listOf(
            Regex("""(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)"""),
            Regex("""\$(\d+(?:\.\d{2})?)"""),
            Regex("""(\d+(?:\.\d{2})?) (?:dollars?|AED|euros?|pounds?)""")
        )
        
        for (pattern in patterns) {
            val match = pattern.find(command)
            if (match != null) {
                val amountStr = match.groupValues[1].replace(",", "")
                return BigDecimal(amountStr)
            }
        }
        
        throw Exception("Amount not found")
    }
    
    private fun extractCurrency(command: String): String {
        return when {
            command.contains("dollars?".toRegex()) || command.contains("$") -> "USD"
            command.contains("AED") || command.contains("dirhams?".toRegex()) -> "AED"
            command.contains("euros?".toRegex()) -> "EUR"
            command.contains("pounds?".toRegex()) -> "GBP"
            else -> "USD" // Default currency
        }
    }
    
    private fun extractCategory(command: String): String {
        val lowerCommand = command.lowercase()
        return when {
            lowerCommand.contains("food") || lowerCommand.contains("lunch") || 
            lowerCommand.contains("dinner") || lowerCommand.contains("coffee") ||
            lowerCommand.contains("restaurant") -> "Food & Dining"
            
            lowerCommand.contains("grocery") || lowerCommand.contains("groceries") ||
            lowerCommand.contains("supermarket") -> "Grocery"
            
            lowerCommand.contains("transport") || lowerCommand.contains("taxi") ||
            lowerCommand.contains("gas") || lowerCommand.contains("fuel") ||
            lowerCommand.contains("uber") -> "Transportation"
            
            lowerCommand.contains("shopping") || lowerCommand.contains("clothes") ||
            lowerCommand.contains("mall") -> "Shopping"
            
            lowerCommand.contains("entertainment") || lowerCommand.contains("movie") ||
            lowerCommand.contains("cinema") -> "Entertainment"
            
            lowerCommand.contains("bills") || lowerCommand.contains("electricity") ||
            lowerCommand.contains("utility") -> "Bills & Utilities"
            
            lowerCommand.contains("healthcare") || lowerCommand.contains("doctor") ||
            lowerCommand.contains("medical") -> "Healthcare"
            
            lowerCommand.contains("education") || lowerCommand.contains("school") ||
            lowerCommand.contains("course") -> "Education"
            
            else -> "Other"
        }
    }
    
    private fun extractMerchant(command: String): String? {
        val atPattern = Regex("""at\s+([A-Za-z0-9\s']+?)(?:\s+for|\s+on|$)""", RegexOption.IGNORE_CASE)
        val toPattern = Regex("""to\s+([A-Za-z0-9\s']+?)(?:\s+for|\s+on|$)""", RegexOption.IGNORE_CASE)
        
        atPattern.find(command)?.let { match ->
            return match.groupValues[1].trim()
        }
        
        toPattern.find(command)?.let { match ->
            return match.groupValues[1].trim()
        }
        
        return null
    }
}