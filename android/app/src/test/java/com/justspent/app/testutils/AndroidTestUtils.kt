package com.justspent.app.testutils

import com.justspent.app.data.model.Expense
import com.justspent.app.data.model.ExpenseData
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import java.math.BigDecimal
import java.util.UUID

/**
 * Utility functions for Android testing
 */
object AndroidTestUtils {

    /**
     * Create mock ExpenseData for testing
     */
    fun createMockExpenseData(
        amount: BigDecimal = BigDecimal("25.00"),
        currency: String = "USD",
        category: String = "Food & Dining",
        merchant: String? = null,
        notes: String? = null,
        source: String = "voice_assistant",
        voiceTranscript: String? = "I spent 25 dollars on food"
    ): ExpenseData {
        return ExpenseData(
            amount = amount,
            currency = currency,
            category = category,
            merchant = merchant,
            notes = notes,
            transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            source = source,
            voiceTranscript = voiceTranscript
        )
    }

    /**
     * Create mock Expense entity for testing
     */
    fun createMockExpense(
        id: String = UUID.randomUUID().toString(),
        amount: BigDecimal = BigDecimal("25.00"),
        currency: String = "USD",
        category: String = "Food & Dining",
        merchant: String? = null,
        notes: String? = null
    ): Expense {
        return Expense(
            id = id,
            amount = amount,
            currency = currency,
            category = category,
            merchant = merchant,
            description = notes,
            transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            createdAt = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            updatedAt = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            source = "voice_assistant",
            voiceTranscript = "Mock voice command"
        )
    }

    /**
     * Generate test voice commands with expected results
     */
    fun generateVoiceTestCases(): List<VoiceTestCase> {
        return listOf(
            VoiceTestCase(
                command = "I just spent 25 dollars on groceries",
                expectedAmount = BigDecimal("25.00"),
                expectedCurrency = "USD",
                expectedCategory = "Grocery",
                expectedMerchant = null,
                description = "Simple expense with clear category"
            ),
            VoiceTestCase(
                command = "I paid 50 AED for lunch at McDonald's",
                expectedAmount = BigDecimal("50.00"),
                expectedCurrency = "AED",
                expectedCategory = "Food & Dining",
                expectedMerchant = "McDonald's",
                description = "Expense with merchant and AED currency"
            ),
            VoiceTestCase(
                command = "I spent 100 dollars on gas",
                expectedAmount = BigDecimal("100.00"),
                expectedCurrency = "USD",
                expectedCategory = "Transportation",
                expectedMerchant = null,
                description = "Transportation expense"
            ),
            VoiceTestCase(
                command = "I bought clothes for 200 dollars at the mall",
                expectedAmount = BigDecimal("200.00"),
                expectedCurrency = "USD",
                expectedCategory = "Shopping",
                expectedMerchant = "the mall",
                description = "Shopping expense with location"
            ),
            VoiceTestCase(
                command = "I paid 75 euros for entertainment",
                expectedAmount = BigDecimal("75.00"),
                expectedCurrency = "EUR",
                expectedCategory = "Entertainment",
                expectedMerchant = null,
                description = "Entertainment expense in euros"
            )
        )
    }

    /**
     * Generate edge case test scenarios
     */
    fun generateEdgeCaseTestCases(): List<VoiceTestCase> {
        return listOf(
            VoiceTestCase(
                command = "I spent around twenty-five dollars on food",
                expectedAmount = BigDecimal("25.00"),
                expectedCurrency = "USD",
                expectedCategory = "Food & Dining",
                expectedMerchant = null,
                description = "Ambiguous amount with written numbers"
            ),
            VoiceTestCase(
                command = "I paid €30.50 for lunch",
                expectedAmount = BigDecimal("30.50"),
                expectedCurrency = "EUR",
                expectedCategory = "Food & Dining",
                expectedMerchant = null,
                description = "Euro symbol parsing"
            ),
            VoiceTestCase(
                command = "I spent 1,234.56 dollars on electronics",
                expectedAmount = BigDecimal("1234.56"),
                expectedCurrency = "USD",
                expectedCategory = "Shopping",
                expectedMerchant = null,
                description = "Large amount with comma formatting"
            ),
            VoiceTestCase(
                command = "I bought coffee for five dollars",
                expectedAmount = BigDecimal("5.00"),
                expectedCurrency = "USD",
                expectedCategory = "Food & Dining",
                expectedMerchant = null,
                description = "Written number amount"
            )
        )
    }

    /**
     * Generate invalid test cases that should fail
     */
    fun generateInvalidTestCases(): List<String> {
        return listOf(
            "", // Empty command
            "I spent", // Missing amount
            "I paid zero dollars", // Zero amount
            "I bought something", // No amount specified
            "Invalid command with no expense data",
            "I spent negative fifty dollars", // Negative amount
            "I paid 999999999 dollars", // Excessive amount
            "Random text with no expense information"
        )
    }

    /**
     * Generate performance test data
     */
    fun generatePerformanceTestData(count: Int = 100): List<String> {
        val templates = listOf(
            "I spent %d dollars on %s",
            "I paid %d AED for %s",
            "I bought %s for %d dollars",
            "I spent %d euros on %s at %s"
        )
        
        val categories = listOf("food", "groceries", "transport", "shopping", "entertainment")
        val merchants = listOf("Starbucks", "Carrefour", "McDonald's", "Mall", "Cinema")
        
        return (1..count).map { i ->
            val template = templates[i % templates.size]
            val amount = (i % 100) + 1
            val category = categories[i % categories.size]
            val merchant = merchants[i % merchants.size]
            
            when {
                template.contains("at %s") -> String.format(template, amount, category, merchant)
                else -> String.format(template, amount, category)
            }
        }
    }

    /**
     * Validate expense data against expected values
     */
    fun validateExpenseData(
        actual: ExpenseData,
        expected: VoiceTestCase,
        tolerance: BigDecimal = BigDecimal("0.01")
    ): ValidationResult {
        val errors = mutableListOf<String>()
        
        // Validate amount
        if ((actual.amount - expected.expectedAmount).abs() > tolerance) {
            errors.add("Amount mismatch: expected ${expected.expectedAmount}, got ${actual.amount}")
        }
        
        // Validate currency
        if (actual.currency != expected.expectedCurrency) {
            errors.add("Currency mismatch: expected ${expected.expectedCurrency}, got ${actual.currency}")
        }
        
        // Validate category
        if (actual.category != expected.expectedCategory) {
            errors.add("Category mismatch: expected ${expected.expectedCategory}, got ${actual.category}")
        }
        
        // Validate merchant (if expected)
        if (expected.expectedMerchant != null && actual.merchant != expected.expectedMerchant) {
            errors.add("Merchant mismatch: expected ${expected.expectedMerchant}, got ${actual.merchant}")
        }
        
        return ValidationResult(
            isValid = errors.isEmpty(),
            errors = errors,
            testCase = expected
        )
    }

    /**
     * Measure execution time of a block
     */
    inline fun <T> measureExecutionTime(block: () -> T): ExecutionResult<T> {
        val startTime = System.currentTimeMillis()
        val result = block()
        val endTime = System.currentTimeMillis()
        
        return ExecutionResult(
            result = result,
            executionTimeMs = endTime - startTime
        )
    }

    /**
     * Create test database name for isolation
     */
    fun createTestDatabaseName(testName: String): String {
        return "test_${testName}_${System.currentTimeMillis()}"
    }
}

/**
 * Data class for voice command test cases
 */
data class VoiceTestCase(
    val command: String,
    val expectedAmount: BigDecimal,
    val expectedCurrency: String,
    val expectedCategory: String,
    val expectedMerchant: String?,
    val description: String
)

/**
 * Data class for validation results
 */
data class ValidationResult(
    val isValid: Boolean,
    val errors: List<String>,
    val testCase: VoiceTestCase
)

/**
 * Data class for execution results with timing
 */
data class ExecutionResult<T>(
    val result: T,
    val executionTimeMs: Long
)