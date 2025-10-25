package com.justspent.app.voice

import com.google.common.truth.Truth.assertThat
import org.junit.Before
import org.junit.Test
import java.math.BigDecimal

/**
 * Integration tests for VoiceCommandProcessor with NumberPhraseParser
 *
 * These tests verify that the voice command processor correctly uses
 * NumberPhraseParser to handle number phrases like:
 * - "two thousand" → 2000 (not 200!)
 * - "five lakh" → 500000
 * - "two point five million" → 2500000
 */
class VoiceCommandProcessorNumberPhraseTest {

    private lateinit var processor: VoiceCommandProcessor

    @Before
    fun setup() {
        processor = VoiceCommandProcessor()
    }

    // ===========================================
    // Critical Bug Fix Tests
    // ===========================================

    @Test
    fun `processVoiceCommand - 1000 Dirhams numeric - not 100`() {
        // REAL USER BUG: "1000 Dirhams" was parsed as 100 (regex only matched first 3 digits)
        val command = "I just spent 1000 Dirhams for Android phone"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("1000.00"))
        assertThat(expenseData.currency).isEqualTo("AED")
        assertThat(expenseData.category).isEqualTo("Shopping")
    }

    @Test
    fun `processVoiceCommand - two thousand dirhams - not 200`() {
        // USER'S BUG: "two thousand dirhams" was parsed as 200
        val command = "I just spent two thousand dirhams on groceries"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("2000.00"))
        assertThat(expenseData.currency).isEqualTo("AED")
        assertThat(expenseData.category).isEqualTo("Grocery")
    }

    @Test
    fun `processVoiceCommand - five thousand dollars`() {
        val command = "I spent five thousand dollars on electronics"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("5000.00"))
        assertThat(expenseData.currency).isEqualTo("USD")
    }

    @Test
    fun `processVoiceCommand - ten thousand euros`() {
        val command = "I just paid ten thousand euros for the trip"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("10000.00"))
        assertThat(expenseData.currency).isEqualTo("EUR")
    }

    // ===========================================
    // Thousands with Hundreds Tests
    // ===========================================

    @Test
    fun `processVoiceCommand - two thousand five hundred`() {
        val command = "I spent two thousand five hundred dirhams on shopping"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("2500.00"))
    }

    @Test
    fun `processVoiceCommand - twenty five thousand three hundred`() {
        val command = "I paid twenty five thousand three hundred dollars"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("25300.00"))
    }

    // ===========================================
    // Indian Numbering System Tests
    // ===========================================

    @Test
    fun `processVoiceCommand - one lakh rupees`() {
        val command = "I spent one lakh rupees on furniture"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("100000.00"))
        assertThat(expenseData.currency).isEqualTo("INR")
    }

    @Test
    fun `processVoiceCommand - five lakh rupees`() {
        val command = "I just spent five lakh rupees on the car"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("500000.00"))
        assertThat(expenseData.currency).isEqualTo("INR")
    }

    @Test
    fun `processVoiceCommand - one crore rupees`() {
        val command = "I paid one crore rupees for the property"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("10000000.00"))
    }

    @Test
    fun `processVoiceCommand - five lakh fifty thousand`() {
        val command = "I spent five lakh fifty thousand rupees"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("550000.00"))
    }

    // ===========================================
    // Western Large Numbers Tests
    // ===========================================

    @Test
    fun `processVoiceCommand - one million dollars`() {
        val command = "I spent one million dollars on the house"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("1000000.00"))
    }

    @Test
    fun `processVoiceCommand - two point five million`() {
        val command = "I paid two point five million dollars"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("2500000.00"))
    }

    @Test
    fun `processVoiceCommand - one million two hundred thousand`() {
        val command = "I spent one million two hundred thousand euros"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("1200000.00"))
    }

    // ===========================================
    // Hundreds Tests
    // ===========================================

    @Test
    fun `processVoiceCommand - five hundred dirhams`() {
        val command = "I spent five hundred dirhams on groceries"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("500.00"))
    }

    @Test
    fun `processVoiceCommand - nine hundred ninety nine`() {
        val command = "I paid nine hundred ninety nine dollars"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("999.00"))
    }

    // ===========================================
    // Complex Real-World Scenarios
    // ===========================================

    @Test
    fun `processVoiceCommand - complex with merchant and category`() {
        val command = "I just spent two thousand five hundred dirhams at Carrefour for groceries"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("2500.00"))
        assertThat(expenseData.currency).isEqualTo("AED")
        assertThat(expenseData.merchant).contains("Carrefour")
        assertThat(expenseData.category).isEqualTo("Grocery")
    }

    @Test
    fun `processVoiceCommand - long descriptive command`() {
        val command = "I just spent five thousand dollars at the Apple Store on a new MacBook for work"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("5000.00"))
        assertThat(expenseData.merchant).contains("Apple Store")
    }

    // ===========================================
    // Mixed Format Tests
    // ===========================================

    @Test
    fun `processVoiceCommand - prefers numeric over words`() {
        // If both numeric and words present, numeric should take precedence
        val command = "I spent 2000 dollars not two thousand"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        // Should extract "2000" (numeric) not "two thousand" (words)
        assertThat(expenseData.amount).isEqualTo(BigDecimal("2000.00"))
    }

    @Test
    fun `processVoiceCommand - numeric with commas`() {
        val command = "I spent 2,000 dirhams on electronics"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("2000.00"))
    }

    @Test
    fun `processVoiceCommand - various numeric formats`() {
        val testCases = mapOf(
            "I spent 50 dirhams" to BigDecimal("50.00"),
            "I spent 500 dirhams" to BigDecimal("500.00"),
            "I spent 1000 dirhams" to BigDecimal("1000.00"),
            "I spent 5000 dirhams" to BigDecimal("5000.00"),
            "I spent 10000 dirhams" to BigDecimal("10000.00"),
            "I spent 25000 dirhams" to BigDecimal("25000.00"),
            "I spent 100000 dirhams" to BigDecimal("100000.00")
        )

        testCases.forEach { (command, expectedAmount) ->
            val result = processor.processVoiceCommand(command)
            assertThat(result.isSuccess).isTrue()
            val expenseData = result.getOrNull()!!
            assertThat(expenseData.amount).isEqualTo(expectedAmount)
        }
    }

    // ===========================================
    // Decimal/Fractional Tests
    // ===========================================

    @Test
    fun `processVoiceCommand - decimal with point`() {
        val command = "I spent five point five thousand dollars"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        // "five point five thousand" = 5.5 * 1000 = 5500
        assertThat(expenseData.amount).isEqualTo(BigDecimal("5500.00"))
    }

    // ===========================================
    // Small Numbers Tests
    // ===========================================

    @Test
    fun `processVoiceCommand - twenty five dollars`() {
        val command = "I spent twenty five dollars on lunch"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("25.00"))
    }

    @Test
    fun `processVoiceCommand - fifty dirhams`() {
        val command = "I paid fifty dirhams for gas"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.amount).isEqualTo(BigDecimal("50.00"))
    }

    // ===========================================
    // Confidence Score Tests
    // ===========================================

    @Test
    fun `getConfidenceScore - high confidence for complete command`() {
        val command = "I spent two thousand dirhams on groceries at Carrefour"
        val score = processor.getConfidenceScore(command)

        // Should have high confidence (amount + category + merchant + action word + currency)
        assertThat(score).isGreaterThan(0.8)
    }

    @Test
    fun `getConfidenceScore - moderate confidence for partial command`() {
        val command = "I spent two thousand dirhams"
        val score = processor.getConfidenceScore(command)

        // Should have moderate confidence (amount + action word + currency)
        assertThat(score).isGreaterThan(0.5)
    }
}
