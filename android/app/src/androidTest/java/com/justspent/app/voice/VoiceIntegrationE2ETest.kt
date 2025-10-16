package com.justspent.app.voice

import android.content.Intent
import android.net.Uri
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.justspent.app.ui.voice.VoiceDeepLinkActivity
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.util.*

/**
 * End-to-end tests for voice integration functionality
 * Tests the complete flow from Google Assistant intent to expense logging
 */
@RunWith(AndroidJUnit4::class)
@HiltAndroidTest
class VoiceIntegrationE2ETest {
    
    @get:Rule
    val hiltRule = HiltAndroidRule(this)
    
    @get:Rule
    val composeTestRule = createAndroidComposeRule<VoiceDeepLinkActivity>()
    
    @Before
    fun setup() {
        hiltRule.inject()
    }
    
    @Test
    fun testSimpleVoiceCommand_LogsExpenseSuccessfully() {
        // Arrange: Create intent with voice command parameters
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("https://justspent.app/expense?amount=50&category=grocery&merchant=supermarket")
        }
        
        // Act: Launch activity with intent
        composeTestRule.activityRule.scenario.onActivity { activity ->
            activity.onNewIntent(intent)
        }
        
        // Assert: Check that expense is processed
        composeTestRule.onNodeWithText("Processing your expense...")
            .assertIsDisplayed()
        
        // Wait for processing and check success
        composeTestRule.waitUntil(timeoutMillis = 5000) {
            composeTestRule.onAllNodesWithText("Expense Logged!")
                .fetchSemanticsNodes().isNotEmpty()
        }
        
        composeTestRule.onNodeWithText("Expense Logged!")
            .assertIsDisplayed()
        
        composeTestRule.onNodeWithText("USD 50 - Grocery")
            .assertIsDisplayed()
    }
    
    @Test
    fun testRawVoiceCommand_ProcessesAndConfirms() {
        // Arrange: Create intent with raw voice command
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("https://justspent.app/expense?command=I%20just%20spent%201500%20dollars%20on%20shopping")
        }
        
        // Act: Launch activity with intent
        composeTestRule.activityRule.scenario.onActivity { activity ->
            activity.onNewIntent(intent)
        }
        
        // Assert: Check that confirmation is required for large amount
        composeTestRule.onNodeWithText("Please Confirm")
            .assertIsDisplayed()
        
        composeTestRule.onNodeWithText("\"I just spent 1500 dollars on shopping\"")
            .assertIsDisplayed()
        
        composeTestRule.onNodeWithText("Amount")
            .assertIsDisplayed()
        
        composeTestRule.onNodeWithText("USD 1500")
            .assertIsDisplayed()
        
        // Confirm the expense
        composeTestRule.onNodeWithText("Confirm")
            .performClick()
        
        // Wait for success
        composeTestRule.waitUntil(timeoutMillis = 5000) {
            composeTestRule.onAllNodesWithText("Expense Logged!")
                .fetchSemanticsNodes().isNotEmpty()
        }
        
        composeTestRule.onNodeWithText("Expense Logged!")
            .assertIsDisplayed()
    }
    
    @Test
    fun testInvalidVoiceCommand_ShowsError() {
        // Arrange: Create intent with invalid command
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("https://justspent.app/expense?command=hello%20world")
        }
        
        // Act: Launch activity with intent
        composeTestRule.activityRule.scenario.onActivity { activity ->
            activity.onNewIntent(intent)
        }
        
        // Assert: Check that error is shown with suggestions
        composeTestRule.onNodeWithText("Oops!")
            .assertIsDisplayed()
        
        composeTestRule.onNodeWithText("Try saying:")
            .assertIsDisplayed()
        
        // Check that suggestions are shown
        composeTestRule.onNodeWithText("\"I just spent 25 dollars on food\"")
            .assertIsDisplayed()
        
        composeTestRule.onNodeWithText("Retry")
            .assertIsDisplayed()
        
        composeTestRule.onNodeWithText("Close")
            .assertIsDisplayed()
    }
    
    @Test
    fun testMultiCurrencyCommand_ProcessesCorrectly() {
        // Arrange: Create intent with AED currency
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("https://justspent.app/expense?command=I%20spent%2025%20AED%20on%20coffee")
        }
        
        // Act: Launch activity with intent
        composeTestRule.activityRule.scenario.onActivity { activity ->
            activity.onNewIntent(intent)
        }
        
        // Assert: Check that AED currency is detected
        composeTestRule.waitUntil(timeoutMillis = 5000) {
            composeTestRule.onAllNodesWithText("Expense Logged!")
                .fetchSemanticsNodes().isNotEmpty()
        }
        
        composeTestRule.onNodeWithText("AED 25")
            .assertIsDisplayed()
    }
    
    @Test
    fun testCategoryClassification_WorksCorrectly() {
        // Test various category classifications
        val testCases = listOf(
            "I spent 10 dollars on lunch" to "Food & Dining",
            "I paid 30 dollars for gas" to "Transportation",
            "I bought groceries for 50 dollars" to "Grocery",
            "I spent 20 dollars at the store" to "Shopping"
        )
        
        testCases.forEach { (command, expectedCategory) ->
            // Arrange
            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("https://justspent.app/expense?command=${Uri.encode(command)}")
            }
            
            // Act
            composeTestRule.activityRule.scenario.onActivity { activity ->
                activity.onNewIntent(intent)
            }
            
            // Assert
            composeTestRule.waitUntil(timeoutMillis = 5000) {
                composeTestRule.onAllNodesWithText("Expense Logged!")
                    .fetchSemanticsNodes().isNotEmpty()
            }
            
            composeTestRule.onNodeWithText(expectedCategory, substring = true)
                .assertIsDisplayed()
            
            // Reset for next test
            composeTestRule.activityRule.scenario.recreate()
        }
    }
    
    @Test
    fun testMerchantExtraction_WorksCorrectly() {
        // Arrange: Command with merchant
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("https://justspent.app/expense?command=${Uri.encode("I spent 15 dollars at Starbucks for coffee")}")
        }
        
        // Act
        composeTestRule.activityRule.scenario.onActivity { activity ->
            activity.onNewIntent(intent)
        }
        
        // Assert: Check merchant is extracted
        composeTestRule.waitUntil(timeoutMillis = 5000) {
            composeTestRule.onAllNodesWithText("Expense Logged!")
                .fetchSemanticsNodes().isNotEmpty()
        }
        
        // Check that merchant info is included in the display
        composeTestRule.onNode(hasText("Starbucks", substring = true))
            .assertIsDisplayed()
    }
    
    @Test
    fun testConfidenceScoring_DisplaysCorrectly() {
        // Arrange: Command that should have high confidence
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("https://justspent.app/expense?command=${Uri.encode("I just spent 25 dollars on food")}")
        }
        
        // Act
        composeTestRule.activityRule.scenario.onActivity { activity ->
            activity.onNewIntent(intent)
        }
        
        // Assert: Check confidence is displayed
        composeTestRule.waitUntil(timeoutMillis = 5000) {
            composeTestRule.onAllNodesWithText("Expense Logged!")
                .fetchSemanticsNodes().isNotEmpty()
        }
        
        // Look for confidence percentage (should be high for clear command)
        composeTestRule.onNode(hasText("confidence", substring = true, ignoreCase = true))
            .assertIsDisplayed()
    }
    
    @Test
    fun testRetryFunctionality_WorksCorrectly() {
        // Arrange: Invalid command that will show retry option
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("https://justspent.app/expense?command=invalid")
        }
        
        // Act
        composeTestRule.activityRule.scenario.onActivity { activity ->
            activity.onNewIntent(intent)
        }
        
        // Assert: Error is shown
        composeTestRule.onNodeWithText("Oops!")
            .assertIsDisplayed()
        
        // Click retry
        composeTestRule.onNodeWithText("Retry")
            .performClick()
        
        // Should show processing again
        composeTestRule.onNodeWithText("Processing your expense...")
            .assertIsDisplayed()
    }
    
    @Test
    fun testEmptyIntent_ShowsError() {
        // Arrange: Empty intent
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("https://justspent.app/expense")
        }
        
        // Act
        composeTestRule.activityRule.scenario.onActivity { activity ->
            activity.onNewIntent(intent)
        }
        
        // Assert: Error is shown
        composeTestRule.onNodeWithText("Invalid voice command data")
            .assertIsDisplayed()
        
        composeTestRule.onNodeWithText("Close")
            .assertIsDisplayed()
    }
}

/**
 * Helper extension to wait for a condition with timeout
 */
private fun ComposeTestRule.waitUntil(
    timeoutMillis: Long = 1000,
    condition: () -> Boolean
) {
    val startTime = System.currentTimeMillis()
    while (!condition() && System.currentTimeMillis() - startTime < timeoutMillis) {
        Thread.sleep(50)
    }
}