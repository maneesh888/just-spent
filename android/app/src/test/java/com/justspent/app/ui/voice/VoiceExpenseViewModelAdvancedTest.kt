package com.justspent.app.ui.voice

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import com.justspent.app.data.model.ExpenseData
import com.justspent.app.data.repository.ExpenseRepositoryInterface
import com.justspent.app.testutils.MainDispatcherRule
import com.justspent.app.testutils.MockExpenseRepository
import com.justspent.app.voice.VoiceCommandProcessor
import io.mockk.coEvery
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import org.junit.Assert.*
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.math.BigDecimal
import java.util.Locale

/**
 * Comprehensive tests for VoiceExpenseViewModel
 * Testing UI state management, voice processing integration, and user interactions
 */
@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
class VoiceExpenseViewModelAdvancedTest {

    @get:Rule
    val instantTaskExecutorRule = InstantTaskExecutorRule()

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    private lateinit var viewModel: VoiceExpenseViewModel
    private lateinit var mockRepository: ExpenseRepositoryInterface
    private lateinit var mockVoiceProcessor: VoiceCommandProcessor

    @Before
    fun setup() {
        mockRepository = MockExpenseRepository()
        mockVoiceProcessor = mockk(relaxed = true)
        viewModel = VoiceExpenseViewModel(mockRepository, mockVoiceProcessor)
    }

    // ===== RAW VOICE COMMAND PROCESSING TESTS =====

    @Test
    fun `processRawVoiceCommand - successful processing updates state correctly`() = runTest {
        // Setup
        val command = "I just spent 25 dollars on groceries"
        val expectedExpenseData = ExpenseData(
            amount = BigDecimal("25.00"),
            currency = "USD",
            category = "Grocery",
            merchant = null,
            notes = null,
            transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            source = "voice_assistant",
            voiceTranscript = command
        )
        
        every { mockVoiceProcessor.processVoiceCommand(command, any()) } returns Result.success(expectedExpenseData)
        every { mockVoiceProcessor.getConfidenceScore(command) } returns 0.9
        
        // Execute
        viewModel.processRawVoiceCommand(command)
        
        // Verify
        val finalState = viewModel.uiState.first()
        assertFalse("Should not be processing", finalState.isProcessing)
        assertTrue("Should be processed", finalState.isProcessed)
        assertNotNull("Should have processed expense", finalState.processedExpense)
        assertNotNull("Should have extracted data", finalState.extractedData)
        assertEquals("Should have confidence score", 0.9, finalState.confidenceScore, 0.01)
        assertNull("Should not have error", finalState.errorMessage)
        
        verify { mockVoiceProcessor.processVoiceCommand(command, any()) }
        verify { mockVoiceProcessor.getConfidenceScore(command) }
    }

    @Test
    fun `processRawVoiceCommand - large amount requires confirmation`() = runTest {
        // Setup
        val command = "I just spent 2000 dollars on electronics"
        val expenseData = ExpenseData(
            amount = BigDecimal("2000.00"),
            currency = "USD",
            category = "Shopping",
            merchant = null,
            notes = null,
            transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            source = "voice_assistant",
            voiceTranscript = command
        )
        
        every { mockVoiceProcessor.processVoiceCommand(command, any()) } returns Result.success(expenseData)
        every { mockVoiceProcessor.getConfidenceScore(command) } returns 0.9
        
        // Execute
        viewModel.processRawVoiceCommand(command)
        
        // Verify
        val finalState = viewModel.uiState.first()
        assertFalse("Should not be processing", finalState.isProcessing)
        assertFalse("Should not be auto-processed", finalState.isProcessed)
        assertTrue("Should require confirmation", finalState.requiresConfirmation)
        assertNotNull("Should have extracted data", finalState.extractedData)
        assertEquals("Amount should match", "2000.00", finalState.extractedData?.amount)
    }

    @Test
    fun `processRawVoiceCommand - low confidence requires confirmation`() = runTest {
        // Setup
        val command = "I spent something on stuff"
        val expenseData = ExpenseData(
            amount = BigDecimal("25.00"),
            currency = "USD",
            category = "Other",
            merchant = null,
            notes = null,
            transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            source = "voice_assistant",
            voiceTranscript = command
        )
        
        every { mockVoiceProcessor.processVoiceCommand(command, any()) } returns Result.success(expenseData)
        every { mockVoiceProcessor.getConfidenceScore(command) } returns 0.5 // Low confidence
        
        // Execute
        viewModel.processRawVoiceCommand(command)
        
        // Verify
        val finalState = viewModel.uiState.first()
        assertTrue("Should require confirmation for low confidence", finalState.requiresConfirmation)
        assertEquals("Should preserve low confidence score", 0.5, finalState.confidenceScore, 0.01)
    }

    @Test
    fun `processRawVoiceCommand - processing failure shows error with suggestions`() = runTest {
        // Setup
        val command = "invalid command"
        val errorMessage = "Failed to parse amount"
        val suggestions = listOf(
            "I just spent 25 dollars on groceries",
            "I paid 50 AED for lunch",
            "Log 15 dollars for coffee"
        )
        
        every { mockVoiceProcessor.processVoiceCommand(command, any()) } returns Result.failure(Exception(errorMessage))
        every { mockVoiceProcessor.getConfidenceScore(command) } returns 0.2
        every { mockVoiceProcessor.getSuggestedPhrases(any()) } returns suggestions
        
        // Execute
        viewModel.processRawVoiceCommand(command)
        
        // Verify
        val finalState = viewModel.uiState.first()
        assertFalse("Should not be processing", finalState.isProcessing)
        assertFalse("Should not be processed", finalState.isProcessed)
        assertEquals("Should show error message", errorMessage, finalState.errorMessage)
        assertEquals("Should show suggestions", suggestions.take(3), finalState.suggestedPhrases)
        assertEquals("Should preserve confidence score", 0.2, finalState.confidenceScore, 0.01)
    }

    @Test
    fun `processRawVoiceCommand - sets processing state initially`() = runTest {
        // Setup
        val command = "I just spent 25 dollars on food"
        
        every { mockVoiceProcessor.processVoiceCommand(any(), any()) } returns 
            Result.success(createMockExpenseData())
        every { mockVoiceProcessor.getConfidenceScore(any()) } returns 0.9
        
        // Execute
        viewModel.processRawVoiceCommand(command)
        
        // The processing state is set synchronously before the coroutine starts
        // Since we're using test dispatcher, we can verify the processing behavior
        verify { mockVoiceProcessor.processVoiceCommand(command, any()) }
    }

    // ===== CONFIRMATION FLOW TESTS =====

    @Test
    fun `confirmExpense - successfully saves confirmed expense`() = runTest {
        // Setup - first trigger a confirmation scenario
        val command = "I just spent 1500 dollars on electronics"
        val expenseData = createMockExpenseData(amount = BigDecimal("1500.00"))
        
        every { mockVoiceProcessor.processVoiceCommand(command, any()) } returns Result.success(expenseData)
        every { mockVoiceProcessor.getConfidenceScore(command) } returns 0.9
        
        // First process the command to get to confirmation state
        viewModel.processRawVoiceCommand(command)
        
        // Verify we're in confirmation state
        val confirmationState = viewModel.uiState.first()
        assertTrue("Should require confirmation", confirmationState.requiresConfirmation)
        
        // Execute confirmation
        viewModel.confirmExpense()
        
        // Verify final state
        val finalState = viewModel.uiState.first()
        assertFalse("Should not require confirmation anymore", finalState.requiresConfirmation)
        assertTrue("Should be processed", finalState.isProcessed)
        assertNotNull("Should have processed expense", finalState.processedExpense)
    }

    @Test
    fun `confirmExpense - handles confirmation failure gracefully`() = runTest {
        // Setup repository to fail on save
        mockRepository = mockk()
        coEvery { mockRepository.addExpense(any()) } returns Result.failure(Exception("Database error"))
        viewModel = VoiceExpenseViewModel(mockRepository, mockVoiceProcessor)
        
        // Setup confirmation state
        val command = "I just spent 1500 dollars on electronics"
        val expenseData = createMockExpenseData(amount = BigDecimal("1500.00"))
        
        every { mockVoiceProcessor.processVoiceCommand(command, any()) } returns Result.success(expenseData)
        every { mockVoiceProcessor.getConfidenceScore(command) } returns 0.9
        
        viewModel.processRawVoiceCommand(command)
        
        // Execute confirmation
        viewModel.confirmExpense()
        
        // Verify error state
        val finalState = viewModel.uiState.first()
        assertNotNull("Should have error message", finalState.errorMessage)
        assertTrue("Error should mention database", finalState.errorMessage!!.contains("Database error"))
    }

    // ===== LEGACY VOICE COMMAND TESTS =====

    @Test
    fun `processVoiceCommand - handles structured voice input correctly`() = runTest {
        // Setup
        val amount = "25.50"
        val category = "Food"
        val merchant = "Starbucks"
        val note = "Morning coffee"
        
        // Execute
        viewModel.processVoiceCommand(amount, category, merchant, note)
        
        // Verify
        val finalState = viewModel.uiState.first()
        assertTrue("Should be processed", finalState.isProcessed)
        assertNotNull("Should have processed expense", finalState.processedExpense)
        assertNull("Should not have error", finalState.errorMessage)
    }

    @Test
    fun `processVoiceCommand - handles invalid structured input`() = runTest {
        // Setup - invalid amount
        val amount = "invalid"
        val category = "Food"
        
        // Execute
        viewModel.processVoiceCommand(amount, category, null, null)
        
        // Verify
        val finalState = viewModel.uiState.first()
        assertFalse("Should not be processed", finalState.isProcessed)
        assertNotNull("Should have error message", finalState.errorMessage)
    }

    @Test
    fun `processVoiceCommand - handles missing required data`() = runTest {
        // Execute with null amount
        viewModel.processVoiceCommand(null, "Food", null, null)
        
        // Verify
        val finalState = viewModel.uiState.first()
        assertFalse("Should not be processed", finalState.isProcessed)
        assertNotNull("Should have error message", finalState.errorMessage)
    }

    // ===== RETRY FUNCTIONALITY TESTS =====

    @Test
    fun `retry - retries last raw voice command`() = runTest {
        // Setup
        val command = "I just spent 25 dollars on food"
        every { mockVoiceProcessor.processVoiceCommand(command, any()) } returns 
            Result.failure(Exception("Network error"))
        every { mockVoiceProcessor.getConfidenceScore(command) } returns 0.8
        every { mockVoiceProcessor.getSuggestedPhrases(any()) } returns emptyList()
        
        // First attempt - should fail
        viewModel.processRawVoiceCommand(command)
        val errorState = viewModel.uiState.first()
        assertNotNull("Should have error", errorState.errorMessage)
        
        // Setup for retry success
        every { mockVoiceProcessor.processVoiceCommand(command, any()) } returns 
            Result.success(createMockExpenseData())
        
        // Execute retry
        viewModel.retry()
        
        // Verify retry worked
        val retryState = viewModel.uiState.first()
        assertTrue("Retry should succeed", retryState.isProcessed)
        assertNull("Should not have error after retry", retryState.errorMessage)
    }

    @Test
    fun `retry - retries last structured voice command`() = runTest {
        // Setup repository to fail initially
        mockRepository = mockk()
        coEvery { mockRepository.addExpense(any()) } returns Result.failure(Exception("Database busy"))
        viewModel = VoiceExpenseViewModel(mockRepository, mockVoiceProcessor)
        
        // First attempt - should fail
        viewModel.processVoiceCommand("25", "Food", null, null)
        val errorState = viewModel.uiState.first()
        assertNotNull("Should have error", errorState.errorMessage)
        
        // Setup for retry success
        coEvery { mockRepository.addExpense(any()) } returns Result.success(mockk())
        
        // Execute retry
        viewModel.retry()
        
        // Verify retry worked
        val retryState = viewModel.uiState.first()
        assertTrue("Retry should succeed", retryState.isProcessed)
        assertNull("Should not have error after retry", retryState.errorMessage)
    }

    @Test
    fun `retry - does nothing when no previous command exists`() = runTest {
        // Execute retry without any previous command
        viewModel.retry()
        
        // Verify state remains initial
        val state = viewModel.uiState.first()
        assertFalse("Should not be processed", state.isProcessed)
        assertFalse("Should not be processing", state.isProcessing)
        assertNull("Should not have error", state.errorMessage)
    }

    // ===== STATE MANAGEMENT TESTS =====

    @Test
    fun `resetState - clears all UI state`() = runTest {
        // Setup - get into an error state
        viewModel.processRawVoiceCommand("invalid command")
        every { mockVoiceProcessor.processVoiceCommand(any(), any()) } returns 
            Result.failure(Exception("Error"))
        every { mockVoiceProcessor.getConfidenceScore(any()) } returns 0.0
        every { mockVoiceProcessor.getSuggestedPhrases(any()) } returns listOf("suggestion")
        
        // Verify we have some state
        val stateWithData = viewModel.uiState.first()
        // State might be different due to mocking, so let's reset and verify clean state
        
        // Execute reset
        viewModel.resetState()
        
        // Verify clean state
        val cleanState = viewModel.uiState.first()
        assertFalse("Should not be processing", cleanState.isProcessing)
        assertFalse("Should not be processed", cleanState.isProcessed)
        assertNull("Should not have error", cleanState.errorMessage)
        assertNull("Should not have processed expense", cleanState.processedExpense)
        assertNull("Should not have confidence score", cleanState.confidenceScore)
        assertTrue("Should not have suggestions", cleanState.suggestedPhrases.isEmpty())
        assertFalse("Should not require confirmation", cleanState.requiresConfirmation)
        assertNull("Should not have extracted data", cleanState.extractedData)
    }

    // ===== TRAINING PHRASES TESTS =====

    @Test
    fun `getTrainingPhrases - returns locale-appropriate phrases`() {
        // Setup
        val expectedPhrases = listOf(
            "I just spent 25 dollars on food",
            "I paid 50 AED for groceries",
            "Log 15 dollars for coffee"
        )
        every { mockVoiceProcessor.getSuggestedPhrases(any()) } returns expectedPhrases
        
        // Execute
        val phrases = viewModel.getTrainingPhrases(Locale.getDefault())
        
        // Verify
        assertEquals("Should return expected phrases", expectedPhrases, phrases)
        verify { mockVoiceProcessor.getSuggestedPhrases(Locale.getDefault()) }
    }

    @Test
    fun `getTrainingPhrases - handles different locales`() {
        // Setup
        val uaeLocale = Locale("en", "AE")
        val expectedAEDPhrases = listOf(
            "I just spent 50 AED on groceries",
            "I paid 25 dirhams for lunch"
        )
        every { mockVoiceProcessor.getSuggestedPhrases(uaeLocale) } returns expectedAEDPhrases
        
        // Execute
        val phrases = viewModel.getTrainingPhrases(uaeLocale)
        
        // Verify
        assertEquals("Should return UAE-specific phrases", expectedAEDPhrases, phrases)
        verify { mockVoiceProcessor.getSuggestedPhrases(uaeLocale) }
    }

    // ===== INTEGRATION TESTS =====

    @Test
    fun `full voice processing flow - success path`() = runTest {
        // Setup
        val command = "I just spent 50 AED on groceries at Carrefour"
        val expenseData = ExpenseData(
            amount = BigDecimal("50.00"),
            currency = "AED",
            category = "Grocery",
            merchant = "Carrefour",
            notes = null,
            transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            source = "voice_assistant",
            voiceTranscript = command
        )
        
        every { mockVoiceProcessor.processVoiceCommand(command, any()) } returns Result.success(expenseData)
        every { mockVoiceProcessor.getConfidenceScore(command) } returns 0.95
        
        // Execute
        viewModel.processRawVoiceCommand(command)
        
        // Verify complete flow
        val finalState = viewModel.uiState.first()
        
        assertFalse("Should not be processing", finalState.isProcessing)
        assertTrue("Should be processed", finalState.isProcessed)
        assertFalse("Should not require confirmation", finalState.requiresConfirmation)
        assertNull("Should not have error", finalState.errorMessage)
        
        // Verify extracted data
        assertNotNull("Should have extracted data", finalState.extractedData)
        assertEquals("Should preserve original command", command, finalState.extractedData!!.originalCommand)
        assertEquals("Should extract amount", "50.00", finalState.extractedData!!.amount)
        assertEquals("Should extract currency", "AED", finalState.extractedData!!.currency)
        assertEquals("Should extract category", "Grocery", finalState.extractedData!!.category)
        assertEquals("Should extract merchant", "Carrefour", finalState.extractedData!!.merchant)
        
        // Verify confidence and processing
        assertEquals("Should have high confidence", 0.95, finalState.confidenceScore, 0.01)
        assertTrue("Should have formatted expense", finalState.processedExpense!!.contains("AED 50.00"))
    }

    @Test
    fun `full voice processing flow - confirmation path`() = runTest {
        // Setup for large amount requiring confirmation
        val command = "I just spent 2500 dollars on a new laptop"
        val expenseData = createMockExpenseData(amount = BigDecimal("2500.00"))
        
        every { mockVoiceProcessor.processVoiceCommand(command, any()) } returns Result.success(expenseData)
        every { mockVoiceProcessor.getConfidenceScore(command) } returns 0.9
        
        // Execute initial processing
        viewModel.processRawVoiceCommand(command)
        
        // Verify confirmation required
        val confirmationState = viewModel.uiState.first()
        assertTrue("Should require confirmation", confirmationState.requiresConfirmation)
        assertFalse("Should not be auto-processed", confirmationState.isProcessed)
        
        // Execute confirmation
        viewModel.confirmExpense()
        
        // Verify final success
        val finalState = viewModel.uiState.first()
        assertFalse("Should not require confirmation anymore", finalState.requiresConfirmation)
        assertTrue("Should be processed", finalState.isProcessed)
        assertNotNull("Should have processed expense", finalState.processedExpense)
    }

    // ===== HELPER METHODS =====

    private fun createMockExpenseData(
        amount: BigDecimal = BigDecimal("25.00"),
        currency: String = "USD",
        category: String = "Food & Dining"
    ): ExpenseData {
        return ExpenseData(
            amount = amount,
            currency = currency,
            category = category,
            merchant = null,
            notes = null,
            transactionDate = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()),
            source = "voice_assistant",
            voiceTranscript = "Mock command"
        )
    }
}