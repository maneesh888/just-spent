package com.justspent.app.voice

import com.justspent.app.data.model.ExpenseData
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.math.BigDecimal
import java.util.Locale

/**
 * Comprehensive tests for VoiceCommandProcessor
 * Testing natural language processing, entity extraction, and edge cases
 */
@RunWith(RobolectricTestRunner::class)
class VoiceCommandProcessorAdvancedTest {

    private lateinit var processor: VoiceCommandProcessor

    @Before
    fun setup() {
        processor = VoiceCommandProcessor()
    }

    // ===== AMOUNT EXTRACTION TESTS =====

    @Test
    fun `processVoiceCommand - extracts simple dollar amounts correctly`() {
        val testCases = mapOf(
            "I just spent 25 dollars on food" to BigDecimal("25.00"),
            "I paid \$50.75 for groceries" to BigDecimal("50.75"),
            "Log 100 dollars for shopping" to BigDecimal("100.00"),
            "I spent \$1,234.56 on electronics" to BigDecimal("1234.56")
        )

        testCases.forEach { (command, expectedAmount) ->
            val result = processor.processVoiceCommand(command)
            assertTrue("Failed for command: $command", result.isSuccess)
            assertEquals("Amount mismatch for: $command", expectedAmount, result.getOrNull()?.amount)
        }
    }

    @Test
    fun `processVoiceCommand - extracts AED amounts correctly`() {
        val testCases = mapOf(
            "I just spent 50 AED on groceries" to BigDecimal("50.00"),
            "I paid 25.50 dirhams for lunch" to BigDecimal("25.50"),
            "Log 100 AED for transportation" to BigDecimal("100.00"),
            "I spent 1,500 dirhams on shopping" to BigDecimal("1500.00")
        )

        testCases.forEach { (command, expectedAmount) ->
            val result = processor.processVoiceCommand(command)
            assertTrue("Failed for command: $command", result.isSuccess)
            assertEquals("Amount mismatch for: $command", expectedAmount, result.getOrNull()?.amount)
            assertEquals("Currency should be AED", "AED", result.getOrNull()?.currency)
        }
    }

    @Test
    fun `processVoiceCommand - extracts written numbers correctly`() {
        val testCases = mapOf(
            "I spent twenty dollars on lunch" to BigDecimal("20"),
            "I paid fifty dirhams for groceries" to BigDecimal("50"),
            "Log fifteen dollars for coffee" to BigDecimal("15"),
            "I spent one hundred dollars shopping" to BigDecimal("100")
        )

        testCases.forEach { (command, expectedAmount) ->
            val result = processor.processVoiceCommand(command)
            assertTrue("Failed for command: $command", result.isSuccess)
            assertEquals("Amount mismatch for: $command", expectedAmount, result.getOrNull()?.amount)
        }
    }

    @Test
    fun `processVoiceCommand - handles invalid amounts correctly`() {
        val invalidCommands = listOf(
            "I spent zero dollars on food",
            "I paid negative fifty dollars",
            "Log abc dollars for shopping",
            "I spent 999999999 dollars on groceries",
            "I paid for lunch" // missing amount
        )

        invalidCommands.forEach { command ->
            val result = processor.processVoiceCommand(command)
            assertTrue("Should fail for invalid command: $command", result.isFailure)
        }
    }

    // ===== CURRENCY EXTRACTION TESTS =====

    @Test
    fun `processVoiceCommand - detects currencies correctly`() {
        val testCases = mapOf(
            "I spent 25 dollars on food" to "USD",
            "I paid 50 AED for groceries" to "AED",
            "Log 30 euros for shopping" to "EUR",
            "I spent 40 pounds on transport" to "GBP",
            "I paid 100 rupees for lunch" to "INR",
            "I spent 200 riyals on fuel" to "SAR"
        )

        testCases.forEach { (command, expectedCurrency) ->
            val result = processor.processVoiceCommand(command)
            assertTrue("Failed for command: $command", result.isSuccess)
            assertEquals("Currency mismatch for: $command", expectedCurrency, result.getOrNull()?.currency)
        }
    }

    @Test
    fun `processVoiceCommand - uses locale for default currency`() {
        val localeTests = mapOf(
            Locale("en", "AE") to "AED",
            Locale("en", "GB") to "GBP",
            Locale("hi", "IN") to "INR",
            Locale("ar", "SA") to "SAR",
            Locale("en", "US") to "USD"
        )

        localeTests.forEach { (locale, expectedCurrency) ->
            val result = processor.processVoiceCommand("I spent 25 on food", locale)
            assertTrue("Failed for locale: ${locale.country}", result.isSuccess)
            assertEquals("Currency mismatch for locale: ${locale.country}", 
                       expectedCurrency, result.getOrNull()?.currency)
        }
    }

    // ===== CATEGORY EXTRACTION TESTS =====

    @Test
    fun `processVoiceCommand - categorizes food expenses correctly`() {
        val foodCommands = listOf(
            "I spent 25 dollars on food",
            "I paid for lunch at the restaurant",
            "Log coffee expense for 5 dollars",
            "I bought dinner for 30 dollars",
            "I ate breakfast for 10 dollars",
            "I had a snack for 3 dollars"
        )

        foodCommands.forEach { command ->
            val result = processor.processVoiceCommand(command)
            assertTrue("Failed for command: $command", result.isSuccess)
            assertEquals("Category should be Food & Dining for: $command", 
                       "Food & Dining", result.getOrNull()?.category)
        }
    }

    @Test
    fun `processVoiceCommand - categorizes transportation expenses correctly`() {
        val transportCommands = listOf(
            "I spent 50 dollars on gas",
            "I paid for taxi ride",
            "Log Uber expense for 25 dollars",
            "I filled up fuel for 60 dollars",
            "I paid parking fee of 10 dollars",
            "I took Careem for 15 dollars"
        )

        transportCommands.forEach { command ->
            val result = processor.processVoiceCommand(command)
            assertTrue("Failed for command: $command", result.isSuccess)
            assertEquals("Category should be Transportation for: $command", 
                       "Transportation", result.getOrNull()?.category)
        }
    }

    @Test
    fun `processVoiceCommand - categorizes shopping expenses correctly`() {
        val shoppingCommands = listOf(
            "I spent 100 dollars shopping",
            "I bought clothes for 80 dollars",
            "Log mall expense for 150 dollars",
            "I purchased items at the store",
            "I went shopping for 200 dollars"
        )

        shoppingCommands.forEach { command ->
            val result = processor.processVoiceCommand(command)
            assertTrue("Failed for command: $command", result.isSuccess)
            assertEquals("Category should be Shopping for: $command", 
                       "Shopping", result.getOrNull()?.category)
        }
    }

    @Test
    fun `processVoiceCommand - defaults to Other for unrecognized categories`() {
        val uncategorizedCommands = listOf(
            "I spent 50 dollars on something",
            "I paid 25 dollars for xyz",
            "Log 30 dollars for random stuff"
        )

        uncategorizedCommands.forEach { command ->
            val result = processor.processVoiceCommand(command)
            assertTrue("Failed for command: $command", result.isSuccess)
            assertEquals("Category should default to Other for: $command", 
                       "Other", result.getOrNull()?.category)
        }
    }

    // ===== MERCHANT EXTRACTION TESTS =====

    @Test
    fun `processVoiceCommand - extracts merchant names correctly`() {
        val testCases = mapOf(
            "I spent 25 dollars at Starbucks" to "Starbucks",
            "I paid 50 dollars from Amazon" to "Amazon",
            "I bought lunch to McDonald's" to "McDonald's",
            "I spent 100 dollars at Mall of Emirates" to "Mall of Emirates",
            "I paid 30 dollars from Carrefour Market" to "Carrefour Market"
        )

        testCases.forEach { (command, expectedMerchant) ->
            val result = processor.processVoiceCommand(command)
            assertTrue("Failed for command: $command", result.isSuccess)
            assertEquals("Merchant mismatch for: $command", expectedMerchant, result.getOrNull()?.merchant)
        }
    }

    @Test
    fun `processVoiceCommand - handles commands without merchants`() {
        val commandsWithoutMerchants = listOf(
            "I spent 25 dollars on food",
            "I paid 50 dollars for groceries",
            "Log 30 dollars for transportation"
        )

        commandsWithoutMerchants.forEach { command ->
            val result = processor.processVoiceCommand(command)
            assertTrue("Failed for command: $command", result.isSuccess)
            assertNull("Merchant should be null for: $command", result.getOrNull()?.merchant)
        }
    }

    // ===== DATE EXTRACTION TESTS =====

    @Test
    fun `processVoiceCommand - handles relative date references`() {
        val result1 = processor.processVoiceCommand("I spent 25 dollars yesterday on food")
        assertTrue("Yesterday command should succeed", result1.isSuccess)
        
        val result2 = processor.processVoiceCommand("I just paid 30 dollars for lunch")
        assertTrue("'Just' command should succeed", result2.isSuccess)
        
        val result3 = processor.processVoiceCommand("I spent 20 dollars this morning on coffee")
        assertTrue("'This morning' command should succeed", result3.isSuccess)
        
        // All should have valid transaction dates
        assertNotNull("Should have transaction date", result1.getOrNull()?.transactionDate)
        assertNotNull("Should have transaction date", result2.getOrNull()?.transactionDate)
        assertNotNull("Should have transaction date", result3.getOrNull()?.transactionDate)
    }

    // ===== NOTES EXTRACTION TESTS =====

    @Test
    fun `processVoiceCommand - extracts notes correctly`() {
        val testCases = mapOf(
            "I spent 25 dollars for weekly groceries" to "weekly groceries",
            "I paid 50 dollars note: business lunch" to "business lunch",
            "Log 30 dollars for client entertainment" to "client entertainment"
        )

        testCases.forEach { (command, expectedNote) ->
            val result = processor.processVoiceCommand(command)
            assertTrue("Failed for command: $command", result.isSuccess)
            assertEquals("Notes mismatch for: $command", expectedNote, result.getOrNull()?.notes)
        }
    }

    // ===== CONFIDENCE SCORING TESTS =====

    @Test
    fun `getConfidenceScore - returns high confidence for complete commands`() {
        val highConfidenceCommands = listOf(
            "I just spent 25 dollars on groceries at Carrefour",
            "I paid 50 AED for lunch at McDonald's",
            "I bought coffee for 5 dollars at Starbucks"
        )

        highConfidenceCommands.forEach { command ->
            val confidence = processor.getConfidenceScore(command)
            assertTrue("High confidence expected for: $command (got $confidence)", confidence >= 0.8)
        }
    }

    @Test
    fun `getConfidenceScore - returns low confidence for incomplete commands`() {
        val lowConfidenceCommands = listOf(
            "I spent something",
            "I paid for stuff",
            "Log expense"
        )

        lowConfidenceCommands.forEach { command ->
            val confidence = processor.getConfidenceScore(command)
            assertTrue("Low confidence expected for: $command (got $confidence)", confidence <= 0.5)
        }
    }

    @Test
    fun `getConfidenceScore - returns medium confidence for partial commands`() {
        val mediumConfidenceCommands = listOf(
            "I spent 25 dollars",
            "I paid for groceries",
            "I bought 50 dollars worth"
        )

        mediumConfidenceCommands.forEach { command ->
            val confidence = processor.getConfidenceScore(command)
            assertTrue("Medium confidence expected for: $command (got $confidence)", 
                     confidence > 0.5 && confidence < 0.8)
        }
    }

    // ===== VALIDATION TESTS =====

    @Test
    fun `processVoiceCommand - validates amount ranges`() {
        // Test minimum amount validation
        val tooSmallResult = processor.processVoiceCommand("I spent 0 dollars on food")
        assertTrue("Should fail for zero amount", tooSmallResult.isFailure)
        
        // Test maximum amount validation
        val tooLargeResult = processor.processVoiceCommand("I spent 9999999 dollars on shopping")
        assertTrue("Should fail for excessive amount", tooLargeResult.isFailure)
        
        // Test valid range
        val validResult = processor.processVoiceCommand("I spent 100 dollars on groceries")
        assertTrue("Should succeed for valid amount", validResult.isSuccess)
    }

    @Test
    fun `processVoiceCommand - validates supported currencies`() {
        val supportedCurrencies = listOf("USD", "AED", "EUR", "GBP", "INR", "SAR")
        
        supportedCurrencies.forEach { currency ->
            val command = "I spent 25 ${currency.lowercase()} on food"
            val result = processor.processVoiceCommand(command)
            assertTrue("Should support currency: $currency", result.isSuccess)
        }
    }

    // ===== COMPLEX SCENARIO TESTS =====

    @Test
    fun `processVoiceCommand - handles complex natural language commands`() {
        val complexCommands = mapOf(
            "I just spent twenty-five dollars and fifty cents on groceries at Carrefour this morning" to 
                Triple(BigDecimal("25.00"), "Grocery", "Carrefour"),
            "I paid 100 AED for dinner at Burj Al Arab restaurant yesterday evening" to 
                Triple(BigDecimal("100.00"), "Food & Dining", "Burj Al Arab restaurant"),
            "Log fifty euros for shopping at Mall of Emirates for clothes" to 
                Triple(BigDecimal("50.00"), "Shopping", "Mall of Emirates")
        )

        complexCommands.forEach { (command, expected) ->
            val result = processor.processVoiceCommand(command)
            assertTrue("Failed for complex command: $command", result.isSuccess)
            
            val expense = result.getOrNull()!!
            assertEquals("Amount mismatch for: $command", expected.first, expense.amount)
            assertEquals("Category mismatch for: $command", expected.second, expense.category)
            assertEquals("Merchant mismatch for: $command", expected.third, expense.merchant)
        }
    }

    @Test
    fun `processVoiceCommand - handles multilingual number words`() {
        // This would be extended for actual multilingual support
        val result = processor.processVoiceCommand("I spent five dollars on coffee")
        assertTrue("Should handle written numbers", result.isSuccess)
        assertEquals("Should extract five as 5", BigDecimal("5"), result.getOrNull()?.amount)
    }

    // ===== PERFORMANCE TESTS =====

    @Test
    fun `processVoiceCommand - processes commands within performance threshold`() {
        val command = "I just spent 50 dollars on groceries at Carrefour"
        val iterations = 100
        
        val startTime = System.currentTimeMillis()
        
        repeat(iterations) {
            processor.processVoiceCommand(command)
        }
        
        val endTime = System.currentTimeMillis()
        val averageTime = (endTime - startTime) / iterations
        
        assertTrue("Average processing time should be under 10ms (was ${averageTime}ms)", 
                 averageTime < 10)
    }

    // ===== SUGGESTED PHRASES TESTS =====

    @Test
    fun `getSuggestedPhrases - returns locale-appropriate phrases`() {
        val uaeLocale = Locale("en", "AE")
        val usLocale = Locale("en", "US")
        val gbLocale = Locale("en", "GB")
        
        val uaePhrases = processor.getSuggestedPhrases(uaeLocale)
        val usPhrases = processor.getSuggestedPhrases(usLocale)
        val gbPhrases = processor.getSuggestedPhrases(gbLocale)
        
        assertTrue("UAE phrases should contain AED/dirhams", 
                 uaePhrases.any { it.contains("AED") || it.contains("dirhams") })
        assertTrue("US phrases should contain dollars", 
                 usPhrases.any { it.contains("dollars") })
        assertTrue("GB phrases should contain pounds", 
                 gbPhrases.any { it.contains("pounds") })
        
        assertTrue("Should return multiple phrases", uaePhrases.size >= 5)
    }

    // ===== EDGE CASE TESTS =====

    @Test
    fun `processVoiceCommand - handles edge cases gracefully`() {
        val edgeCases = listOf(
            "", // Empty command
            "   ", // Whitespace only
            "I spent", // Incomplete
            "25 dollars", // Missing action verb
            "I spent dollars on food", // Missing amount
            "I spent 25 on", // Missing category
            "!@#$%^&*()", // Special characters
            "I spent twenty-five point five dollars on food" // Complex written number
        )

        edgeCases.forEach { command ->
            val result = processor.processVoiceCommand(command)
            // Should either succeed with valid data or fail gracefully
            if (result.isSuccess) {
                val expense = result.getOrNull()!!
                assertTrue("Valid amount required", expense.amount > BigDecimal.ZERO)
                assertNotNull("Category required", expense.category)
                assertNotNull("Currency required", expense.currency)
            }
            // If it fails, that's acceptable for edge cases
        }
    }

    @Test
    fun `processVoiceCommand - preserves original voice transcript`() {
        val originalCommand = "I just spent 25 dollars on groceries at Carrefour"
        val result = processor.processVoiceCommand(originalCommand)
        
        assertTrue("Should succeed", result.isSuccess)
        assertEquals("Should preserve original transcript", 
                   originalCommand, result.getOrNull()?.voiceTranscript)
        assertEquals("Source should be voice_assistant", 
                   "voice_assistant", result.getOrNull()?.source)
    }
}