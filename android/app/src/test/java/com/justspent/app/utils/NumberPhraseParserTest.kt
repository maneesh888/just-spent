package com.justspent.app.utils

import com.google.common.truth.Truth.assertThat
import org.junit.Test
import java.math.BigDecimal

/**
 * Comprehensive test suite for NumberPhraseParser
 *
 * Tests cover:
 * - Basic number words (one to ninety-nine)
 * - Hundreds
 * - Thousands
 * - Indian numbering (lakhs, crores)
 * - Western large numbers (millions, billions, trillions)
 * - Complex multi-scale combinations
 * - Decimal/fractional amounts
 * - Real-world voice command scenarios
 * - Edge cases and error handling
 */
class NumberPhraseParserTest {

    // ===========================================
    // Basic Number Tests (0-99)
    // ===========================================

    @Test
    fun `parse basic single digit numbers`() {
        val testCases = mapOf(
            "zero" to 0.0,
            "one" to 1.0,
            "two" to 2.0,
            "five" to 5.0,
            "nine" to 9.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isEqualTo(expected)
        }
    }

    @Test
    fun `parse teens (11-19)`() {
        val testCases = mapOf(
            "eleven" to 11.0,
            "twelve" to 12.0,
            "thirteen" to 13.0,
            "fifteen" to 15.0,
            "nineteen" to 19.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isEqualTo(expected)
        }
    }

    @Test
    fun `parse tens (20-90)`() {
        val testCases = mapOf(
            "twenty" to 20.0,
            "thirty" to 30.0,
            "forty" to 40.0,
            "fifty" to 50.0,
            "ninety" to 90.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isEqualTo(expected)
        }
    }

    @Test
    fun `parse compound tens (21-99)`() {
        val testCases = mapOf(
            "twenty one" to 21.0,
            "twenty-one" to 21.0,
            "thirty five" to 35.0,
            "forty two" to 42.0,
            "ninety nine" to 99.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isEqualTo(expected)
        }
    }

    // ===========================================
    // Hundreds Tests
    // ===========================================

    @Test
    fun `parse hundreds`() {
        val testCases = mapOf(
            "one hundred" to 100.0,
            "hundred" to 100.0,  // "hundred" alone = 100
            "two hundred" to 200.0,
            "five hundred" to 500.0,
            "nine hundred" to 900.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isEqualTo(expected)
        }
    }

    @Test
    fun `parse hundreds with compound numbers`() {
        val testCases = mapOf(
            "one hundred and one" to 101.0,
            "two hundred and fifty" to 250.0,
            "five hundred and fifty five" to 555.0,
            "nine hundred ninety nine" to 999.0,
            "three hundred twenty five" to 325.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isEqualTo(expected)
        }
    }

    // ===========================================
    // Thousands Tests (CRITICAL - User's Issue)
    // ===========================================

    @Test
    fun `parse thousands - basic`() {
        val testCases = mapOf(
            "one thousand" to 1000.0,
            "thousand" to 1000.0,  // "thousand" alone = 1000
            "two thousand" to 2000.0,  // USER'S BUG: Was parsing as 200
            "five thousand" to 5000.0,
            "ten thousand" to 10000.0,
            "twenty thousand" to 20000.0,
            "fifty thousand" to 50000.0,
            "ninety nine thousand" to 99000.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    @Test
    fun `parse thousands with hundreds`() {
        val testCases = mapOf(
            "one thousand one hundred" to 1100.0,
            "two thousand five hundred" to 2500.0,
            "five thousand seven hundred fifty" to 5750.0,
            "ten thousand five hundred" to 10500.0,
            "twenty five thousand three hundred" to 25300.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    @Test
    fun `parse hundred thousand`() {
        val testCases = mapOf(
            "one hundred thousand" to 100000.0,
            "two hundred thousand" to 200000.0,
            "five hundred fifty thousand" to 550000.0,
            "nine hundred ninety nine thousand" to 999000.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    // ===========================================
    // Indian Numbering System Tests
    // ===========================================

    @Test
    fun `parse lakhs`() {
        val testCases = mapOf(
            "one lakh" to 100000.0,
            "lakh" to 100000.0,  // "lakh" alone = 100000
            "two lakh" to 200000.0,
            "five lakh" to 500000.0,
            "ten lakh" to 1000000.0,
            "twenty lakh" to 2000000.0,
            "fifty lakh" to 5000000.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    @Test
    fun `parse lakhs with thousands`() {
        val testCases = mapOf(
            "one lakh fifty thousand" to 150000.0,
            "five lakh twenty thousand" to 520000.0,
            "ten lakh fifty thousand" to 1050000.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    @Test
    fun `parse crores`() {
        val testCases = mapOf(
            "one crore" to 10000000.0,
            "crore" to 10000000.0,  // "crore" alone = 10000000
            "two crore" to 20000000.0,
            "five crore" to 50000000.0,
            "ten crore" to 100000000.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    // ===========================================
    // Western Large Numbers Tests
    // ===========================================

    @Test
    fun `parse millions`() {
        val testCases = mapOf(
            "one million" to 1000000.0,
            "million" to 1000000.0,  // "million" alone = 1000000
            "two million" to 2000000.0,
            "five million" to 5000000.0,
            "ten million" to 10000000.0,
            "twenty million" to 20000000.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    @Test
    fun `parse millions with thousands`() {
        val testCases = mapOf(
            "one million two hundred thousand" to 1200000.0,
            "five million five hundred thousand" to 5500000.0,
            "ten million fifty thousand" to 10050000.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    @Test
    fun `parse billions`() {
        val testCases = mapOf(
            "one billion" to 1000000000.0,
            "billion" to 1000000000.0,
            "two billion" to 2000000000.0,
            "five billion" to 5000000000.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    @Test
    fun `parse trillions`() {
        val testCases = mapOf(
            "one trillion" to 1000000000000.0,
            "trillion" to 1000000000000.0,
            "two trillion" to 2000000000000.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    // ===========================================
    // Decimal/Fractional Tests
    // ===========================================

    @Test
    fun `parse decimal numbers with point`() {
        val testCases = mapOf(
            "five point five" to 5.5,
            "two point five" to 2.5,
            "one point two five" to 1.25,
            "ten point seven five" to 10.75
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    @Test
    fun `parse decimal millions`() {
        val testCases = mapOf(
            "two point five million" to 2500000.0,
            "one point two million" to 1200000.0,
            "five point five million" to 5500000.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    // ===========================================
    // Real-World Voice Command Tests
    // ===========================================

    @Test
    fun `extractAmountFromCommand - user's exact scenario`() {
        // USER'S BUG: "two thousand dirhams" was being parsed as 200
        val command = "I just spent two thousand dirhams on groceries"
        val result = NumberPhraseParser.extractAmountFromCommand(command)

        assertThat(result).isNotNull()
        assertThat(result!!.toDouble()).isEqualTo(2000.0)
    }

    @Test
    fun `extractAmountFromCommand - various real phrases`() {
        val testCases = mapOf(
            "I spent five hundred dollars on shopping" to 500.0,
            "I just paid two thousand AED for rent" to 2000.0,
            "I spent fifty thousand rupees on education" to 50000.0,
            "I paid one lakh for the car" to 100000.0,
            "I spent two point five million on house" to 2500000.0,
            "I just spent twenty five thousand euros" to 25000.0
        )

        testCases.forEach { (command, expected) ->
            val result = NumberPhraseParser.extractAmountFromCommand(command)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    @Test
    fun `extractAmountFromCommand - with merchant and category`() {
        val testCases = mapOf(
            "I spent two thousand dirhams at Carrefour for groceries" to 2000.0,
            "I paid five hundred dollars at Starbucks for coffee" to 500.0,
            "I spent ten thousand rupees at Amazon on electronics" to 10000.0
        )

        testCases.forEach { (command, expected) ->
            val result = NumberPhraseParser.extractAmountFromCommand(command)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    @Test
    fun `extractAmountFromCommand - complex combinations`() {
        val testCases = mapOf(
            "I spent two thousand five hundred and fifty dirhams" to 2550.0,
            "I paid one million two hundred thousand dollars" to 1200000.0,
            "I spent five lakh fifty thousand rupees" to 550000.0
        )

        testCases.forEach { (command, expected) ->
            val result = NumberPhraseParser.extractAmountFromCommand(command)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    // ===========================================
    // Numeric Extraction Tests
    // ===========================================

    @Test
    fun `parse numeric amounts with thousand separators`() {
        val testCases = mapOf(
            "2,000" to 2000.0,
            "25,000" to 25000.0,
            "1,234,567" to 1234567.0,
            "2,000.50" to 2000.50
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    @Test
    fun `parse simple numeric amounts`() {
        val testCases = mapOf(
            "50" to 50.0,
            "500" to 500.0,
            "2000" to 2000.0,
            "25000" to 25000.0,
            "100000" to 100000.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    @Test
    fun `parse decimal numeric amounts`() {
        val testCases = mapOf(
            "50.50" to 50.50,
            "500.99" to 500.99,
            "2000.25" to 2000.25,
            "25000.75" to 25000.75
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    // ===========================================
    // Edge Cases & Error Handling
    // ===========================================

    @Test
    fun `parse returns null for invalid input`() {
        val invalidInputs = listOf(
            "",
            "   ",
            "no numbers here",
            "abc",
            "xyz"
        )

        invalidInputs.forEach { input ->
            val result = NumberPhraseParser.parse(input)
            assertThat(result).isNull()
        }
    }

    @Test
    fun `containsNumberPhrase detects number words`() {
        val testCases = mapOf(
            "I spent two thousand dollars" to true,
            "I spent five hundred" to true,
            "I spent ten lakh" to true,
            "I spent one million" to true,
            "no numbers here" to false,
            "just some text" to false
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.containsNumberPhrase(phrase)
            assertThat(result).isEqualTo(expected)
        }
    }

    @Test
    fun `validate method works correctly`() {
        assertThat(NumberPhraseParser.validate("two thousand", 2000.0)).isTrue()
        assertThat(NumberPhraseParser.validate("five hundred", 500.0)).isTrue()
        assertThat(NumberPhraseParser.validate("one lakh", 100000.0)).isTrue()
        assertThat(NumberPhraseParser.validate("two thousand", 200.0)).isFalse()
    }

    // ===========================================
    // Alternative Spellings & Variations
    // ===========================================

    @Test
    fun `parse alternative spellings for lakhs`() {
        val testCases = mapOf(
            "one lakh" to 100000.0,
            "one lac" to 100000.0,
            "two lakhs" to 200000.0,
            "two lacs" to 200000.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    @Test
    fun `parse plural forms`() {
        val testCases = mapOf(
            "two thousands" to 2000.0,
            "three millions" to 3000000.0,
            "five billions" to 5000000000.0
        )

        testCases.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }

    // ===========================================
    // Performance Tests
    // ===========================================

    @Test
    fun `parsing completes within reasonable time`() {
        val command = "I spent two thousand five hundred and fifty dirhams at Carrefour"
        val startTime = System.currentTimeMillis()

        val result = NumberPhraseParser.extractAmountFromCommand(command)

        val endTime = System.currentTimeMillis()
        val duration = endTime - startTime

        assertThat(result).isNotNull()
        assertThat(duration).isLessThan(100L) // Should complete in <100ms
    }

    // ===========================================
    // Example Phrases Validation
    // ===========================================

    @Test
    fun `all example phrases parse correctly`() {
        val examples = NumberPhraseParser.getExamplePhrases()

        examples.forEach { (phrase, expected) ->
            val result = NumberPhraseParser.parse(phrase)
            assertThat(result).isNotNull()
            assertThat(result!!.toDouble()).isWithin(0.01).of(expected)
        }
    }
}
