package com.justspent.app.voice

import com.google.common.truth.Truth.assertThat
import org.junit.Before
import org.junit.Test

/**
 * Comprehensive category identification tests
 * Ensures Android matches iOS category mapping exactly (ContentView.swift:396-414)
 */
class VoiceCommandProcessorCategoryTest {

    private lateinit var processor: VoiceCommandProcessor

    @Before
    fun setup() {
        processor = VoiceCommandProcessor()
    }

    @Test
    fun `tea keyword maps to Food and Dining category`() {
        // Given - This was the reported bug
        val command = "I just spent 20 dollars on tea"

        // When
        val result = processor.processVoiceCommand(command)

        // Then
        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.category).isEqualTo("Food & Dining")
    }

    @Test
    fun `all Food and Dining keywords match iOS implementation`() {
        val foodKeywords = listOf(
            "food", "tea", "coffee", "lunch", "dinner", "breakfast",
            "restaurant", "meal", "drink", "cafe", "dining",
            "eat", "ate", "snack"
        )

        foodKeywords.forEach { keyword ->
            // Given
            val command = "I spent 20 dollars on $keyword"

            // When
            val result = processor.processVoiceCommand(command)

            // Then
            assertThat(result.isSuccess).isTrue()
            val expenseData = result.getOrNull()!!
            assertThat(expenseData.category)
                .named("Keyword '$keyword' should map to Food & Dining")
                .isEqualTo("Food & Dining")
        }
    }

    @Test
    fun `all Grocery keywords match iOS implementation`() {
        val groceryKeywords = listOf(
            "grocery", "groceries", "supermarket", "market", "food shopping"
        )

        groceryKeywords.forEach { keyword ->
            val command = "I spent 50 dollars on $keyword"
            val result = processor.processVoiceCommand(command)

            assertThat(result.isSuccess).isTrue()
            assertThat(result.getOrNull()!!.category).isEqualTo("Grocery")
        }
    }

    @Test
    fun `all Transportation keywords match iOS implementation`() {
        val transportKeywords = listOf(
            "gas", "fuel", "taxi", "uber", "transport", "transportation",
            "parking", "petrol", "toll", "careem"
        )

        transportKeywords.forEach { keyword ->
            val command = "I spent 30 dollars on $keyword"
            val result = processor.processVoiceCommand(command)

            assertThat(result.isSuccess).isTrue()
            assertThat(result.getOrNull()!!.category).isEqualTo("Transportation")
        }
    }

    @Test
    fun `all Shopping keywords match iOS implementation`() {
        val shoppingKeywords = listOf(
            "shopping", "clothes", "clothing", "store", "mall",
            "purchase", "buy", "bought"
        )

        shoppingKeywords.forEach { keyword ->
            val command = "I spent 100 dollars on $keyword"
            val result = processor.processVoiceCommand(command)

            assertThat(result.isSuccess).isTrue()
            assertThat(result.getOrNull()!!.category).isEqualTo("Shopping")
        }
    }

    @Test
    fun `all Entertainment keywords match iOS implementation`() {
        val entertainmentKeywords = listOf(
            "movie", "cinema", "concert", "entertainment",
            "fun", "games", "theatre"
        )

        entertainmentKeywords.forEach { keyword ->
            val command = "I spent 40 dollars on $keyword"
            val result = processor.processVoiceCommand(command)

            assertThat(result.isSuccess).isTrue()
            assertThat(result.getOrNull()!!.category).isEqualTo("Entertainment")
        }
    }

    @Test
    fun `all Bills and Utilities keywords match iOS implementation`() {
        val billsKeywords = listOf(
            "bill", "bills", "rent", "utility", "utilities",
            "electricity", "water", "internet", "phone", "subscription"
        )

        billsKeywords.forEach { keyword ->
            val command = "I spent 200 dollars on $keyword"
            val result = processor.processVoiceCommand(command)

            assertThat(result.isSuccess).isTrue()
            assertThat(result.getOrNull()!!.category).isEqualTo("Bills & Utilities")
        }
    }

    @Test
    fun `category priority matches iOS - Food and Dining checked first`() {
        // If a command has multiple category keywords, Food & Dining should win
        // because it's checked first in both iOS and Android
        val command = "I spent 25 dollars on food shopping"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        // "food" is in Food & Dining list, checked before Grocery
        // So even though "shopping" is in Grocery keywords as "food shopping",
        // "food" alone should trigger Food & Dining first
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.category).isEqualTo("Food & Dining")
    }

    @Test
    fun `unknown keywords default to Other category`() {
        val command = "I spent 50 dollars on something random"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()!!.category).isEqualTo("Other")
    }

    @Test
    fun `case insensitive category matching`() {
        val testCases = listOf(
            "I spent 20 dollars on TEA",
            "I spent 20 dollars on Tea",
            "I spent 20 dollars on tEa",
            "I spent 20 DOLLARS on COFFEE"
        )

        testCases.forEach { command ->
            val result = processor.processVoiceCommand(command)

            assertThat(result.isSuccess).isTrue()
            assertThat(result.getOrNull()!!.category).isEqualTo("Food & Dining")
        }
    }

    @Test
    fun `real world voice command - coffee at Starbucks`() {
        val command = "I just spent 20 dollars on coffee at Starbucks"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.category).isEqualTo("Food & Dining")
        assertThat(expenseData.merchant).isEqualTo("Starbucks")
        assertThat(expenseData.amount.toString()).isEqualTo("20")
    }

    @Test
    fun `real world voice command - tea from cafe`() {
        val command = "I just spent 15 dirhams on tea"

        val result = processor.processVoiceCommand(command)

        assertThat(result.isSuccess).isTrue()
        val expenseData = result.getOrNull()!!
        assertThat(expenseData.category).isEqualTo("Food & Dining")
        assertThat(expenseData.currency).isEqualTo("AED")
    }
}
