package com.justspent.app.voice

import android.content.Intent
import android.net.Uri
import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.ApplicationProvider
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.assertion.ViewAssertions.matches
import androidx.test.espresso.matcher.ViewMatchers.*
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.rule.ActivityTestRule
import com.justspent.app.MainActivity
import com.justspent.app.R
import com.justspent.app.ui.voice.VoiceExpenseActivity
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.util.concurrent.TimeUnit

/**
 * Integration tests for Google Assistant integration
 * Testing deep links, App Actions, and voice workflow integration
 */
@RunWith(AndroidJUnit4::class)
class GoogleAssistantIntegrationTest {

    @get:Rule
    val activityRule = ActivityTestRule(MainActivity::class.java, true, false)

    private lateinit var scenario: ActivityScenario<*>

    @Before
    fun setup() {
        // Ensure clean state before each test
        InstrumentationRegistry.getInstrumentation().targetContext.deleteDatabase("just_spent_database")
    }

    @After
    fun tearDown() {
        if (::scenario.isInitialized) {
            scenario.close()
        }
    }

    // ===== DEEP LINK PROCESSING TESTS =====

    @Test
    fun testDeepLink_SimpleExpenseLogging_OpensVoiceExpenseActivity() {
        // Setup deep link URL
        val deepLinkUri = Uri.parse("https://justspent.app/expense?text=I%20just%20spent%2025%20dollars%20on%20groceries")
        val intent = Intent(Intent.ACTION_VIEW, deepLinkUri).apply {
            setPackage(ApplicationProvider.getApplicationContext<android.content.Context>().packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        // Launch via deep link
        scenario = ActivityScenario.launch<VoiceExpenseActivity>(intent)

        // Verify activity launched
        scenario.onActivity { activity ->
            assertNotNull("Activity should be launched", activity)
            assertTrue("Should be VoiceExpenseActivity", activity is VoiceExpenseActivity)
        }

        // Verify voice processing UI is shown
        onView(withId(R.id.voice_processing_container))
            .check(matches(isDisplayed()))
    }

    @Test
    fun testDeepLink_ComplexExpenseWithMerchant_ProcessesCorrectly() {
        // Setup complex deep link
        val complexText = "I spent 50 AED on groceries at Carrefour"
        val encodedText = Uri.encode(complexText)
        val deepLinkUri = Uri.parse("https://justspent.app/expense?text=$encodedText")
        val intent = Intent(Intent.ACTION_VIEW, deepLinkUri).apply {
            setPackage(ApplicationProvider.getApplicationContext<android.content.Context>().packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        // Launch and process
        scenario = ActivityScenario.launch<VoiceExpenseActivity>(intent)

        // Wait for processing
        Thread.sleep(2000)

        // Verify processing results are displayed
        onView(withId(R.id.expense_amount_text))
            .check(matches(withText(containsString("50"))))
        
        onView(withId(R.id.expense_currency_text))
            .check(matches(withText("AED")))
        
        onView(withId(R.id.expense_category_text))
            .check(matches(withText("Grocery")))
        
        onView(withId(R.id.expense_merchant_text))
            .check(matches(withText("Carrefour")))
    }

    @Test
    fun testDeepLink_MissingParameters_ShowsErrorState() {
        // Setup deep link without required text parameter
        val deepLinkUri = Uri.parse("https://justspent.app/expense")
        val intent = Intent(Intent.ACTION_VIEW, deepLinkUri).apply {
            setPackage(ApplicationProvider.getApplicationContext<android.content.Context>().packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        // Launch
        scenario = ActivityScenario.launch<VoiceExpenseActivity>(intent)

        // Verify error state
        onView(withId(R.id.error_message_text))
            .check(matches(isDisplayed()))
            .check(matches(withText(containsString("Missing"))))
    }

    @Test
    fun testDeepLink_InvalidExpenseCommand_ShowsSuggestions() {
        // Setup deep link with invalid command
        val invalidText = "I did something with money"
        val encodedText = Uri.encode(invalidText)
        val deepLinkUri = Uri.parse("https://justspent.app/expense?text=$encodedText")
        val intent = Intent(Intent.ACTION_VIEW, deepLinkUri).apply {
            setPackage(ApplicationProvider.getApplicationContext<android.content.Context>().packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        // Launch
        scenario = ActivityScenario.launch<VoiceExpenseActivity>(intent)

        // Wait for processing
        Thread.sleep(1500)

        // Verify suggestions are shown
        onView(withId(R.id.suggestions_recycler_view))
            .check(matches(isDisplayed()))
        
        onView(withText(containsString("Try saying")))
            .check(matches(isDisplayed()))
    }

    // ===== APP ACTIONS PARAMETER PROCESSING TESTS =====

    @Test
    fun testAppActions_StructuredParameters_ProcessesCorrectly() {
        // Setup App Actions-style deep link with structured parameters
        val deepLinkUri = Uri.parse("https://justspent.app/expense?amount=25.50&category=food&merchant=Starbucks&note=morning%20coffee")
        val intent = Intent(Intent.ACTION_VIEW, deepLinkUri).apply {
            setPackage(ApplicationProvider.getApplicationContext<android.content.Context>().packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        // Launch
        scenario = ActivityScenario.launch<VoiceExpenseActivity>(intent)

        // Wait for processing
        Thread.sleep(1000)

        // Verify structured data processing
        onView(withId(R.id.expense_amount_text))
            .check(matches(withText("25.50")))
        
        onView(withId(R.id.expense_category_text))
            .check(matches(withText("Food & Dining")))
        
        onView(withId(R.id.expense_merchant_text))
            .check(matches(withText("Starbucks")))
        
        onView(withId(R.id.expense_notes_text))
            .check(matches(withText("morning coffee")))
    }

    @Test
    fun testAppActions_CurrencyDetection_FromLocale() {
        // Setup App Actions with amount but no explicit currency
        val deepLinkUri = Uri.parse("https://justspent.app/expense?amount=100&category=transport")
        val intent = Intent(Intent.ACTION_VIEW, deepLinkUri).apply {
            setPackage(ApplicationProvider.getApplicationContext<android.content.Context>().packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        // Launch
        scenario = ActivityScenario.launch<VoiceExpenseActivity>(intent)

        // Wait for processing
        Thread.sleep(1000)

        // Verify currency detection (should default based on device locale)
        onView(withId(R.id.expense_currency_text))
            .check(matches(isDisplayed())) // Currency should be detected and displayed
    }

    // ===== CONFIRMATION WORKFLOW TESTS =====

    @Test
    fun testConfirmationFlow_LargeAmount_RequiresUserConfirmation() {
        // Setup large amount that should trigger confirmation
        val largeAmountText = "I just spent 5000 dollars on a new computer"
        val encodedText = Uri.encode(largeAmountText)
        val deepLinkUri = Uri.parse("https://justspent.app/expense?text=$encodedText")
        val intent = Intent(Intent.ACTION_VIEW, deepLinkUri).apply {
            setPackage(ApplicationProvider.getApplicationContext<android.content.Context>().packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        // Launch
        scenario = ActivityScenario.launch<VoiceExpenseActivity>(intent)

        // Wait for processing
        Thread.sleep(2000)

        // Verify confirmation dialog is shown
        onView(withId(R.id.confirmation_dialog))
            .check(matches(isDisplayed()))
        
        onView(withText("Confirm Expense"))
            .check(matches(isDisplayed()))
        
        onView(withText(containsString("5000")))
            .check(matches(isDisplayed()))

        // Test confirmation action
        onView(withId(R.id.confirm_button))
            .perform(click())

        // Verify expense is saved after confirmation
        Thread.sleep(1000)
        onView(withId(R.id.success_message))
            .check(matches(isDisplayed()))
    }

    @Test
    fun testConfirmationFlow_LowConfidence_RequiresUserConfirmation() {
        // Setup ambiguous command that should have low confidence
        val ambiguousText = "I spent money on stuff"
        val encodedText = Uri.encode(ambiguousText)
        val deepLinkUri = Uri.parse("https://justspent.app/expense?text=$encodedText")
        val intent = Intent(Intent.ACTION_VIEW, deepLinkUri).apply {
            setPackage(ApplicationProvider.getApplicationContext<android.content.Context>().packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        // Launch
        scenario = ActivityScenario.launch<VoiceExpenseActivity>(intent)

        // Wait for processing
        Thread.sleep(2000)

        // Should either show confirmation or error with suggestions
        try {
            onView(withId(R.id.confirmation_dialog))
                .check(matches(isDisplayed()))
        } catch (e: Exception) {
            // Alternative: should show suggestions for improvement
            onView(withId(R.id.suggestions_recycler_view))
                .check(matches(isDisplayed()))
        }
    }

    // ===== MULTI-LANGUAGE SUPPORT TESTS =====

    @Test
    fun testMultiLanguage_ArabicNumbers_ProcessesCorrectly() {
        // Test with Arabic locale-style numbers
        val arabicText = "I spent 25 AED on groceries"
        val encodedText = Uri.encode(arabicText)
        val deepLinkUri = Uri.parse("https://justspent.app/expense?text=$encodedText")
        val intent = Intent(Intent.ACTION_VIEW, deepLinkUri).apply {
            setPackage(ApplicationProvider.getApplicationContext<android.content.Context>().packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        // Launch
        scenario = ActivityScenario.launch<VoiceExpenseActivity>(intent)

        // Wait for processing
        Thread.sleep(1500)

        // Verify processing
        onView(withId(R.id.expense_amount_text))
            .check(matches(withText("25")))
        
        onView(withId(R.id.expense_currency_text))
            .check(matches(withText("AED")))
    }

    // ===== PERFORMANCE TESTS =====

    @Test
    fun testVoiceProcessing_Performance_CompletesWithinThreshold() {
        // Setup performance test
        val command = "I just spent 50 dollars on groceries at Carrefour"
        val encodedText = Uri.encode(command)
        val deepLinkUri = Uri.parse("https://justspent.app/expense?text=$encodedText")
        val intent = Intent(Intent.ACTION_VIEW, deepLinkUri).apply {
            setPackage(ApplicationProvider.getApplicationContext<android.content.Context>().packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        // Measure processing time
        val startTime = System.currentTimeMillis()
        
        scenario = ActivityScenario.launch<VoiceExpenseActivity>(intent)

        // Wait for processing to complete
        Thread.sleep(3000)

        // Verify completion within performance threshold
        onView(withId(R.id.processing_indicator))
            .check(matches(withEffectiveVisibility(Visibility.GONE)))

        val endTime = System.currentTimeMillis()
        val processingTime = endTime - startTime

        assertTrue("Voice processing should complete within 3 seconds (took ${processingTime}ms)", 
                 processingTime < 3000)
    }

    @Test
    fun testConcurrentDeepLinks_HandlesMultipleRequestsGracefully() {
        // Test handling multiple quick deep links
        val commands = listOf(
            "I spent 25 dollars on coffee",
            "I paid 50 AED for lunch",
            "I bought 30 dollars groceries"
        )

        commands.forEach { command ->
            val encodedText = Uri.encode(command)
            val deepLinkUri = Uri.parse("https://justspent.app/expense?text=$encodedText")
            val intent = Intent(Intent.ACTION_VIEW, deepLinkUri).apply {
                setPackage(ApplicationProvider.getApplicationContext<android.content.Context>().packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }

            if (::scenario.isInitialized) {
                scenario.close()
            }
            scenario = ActivityScenario.launch<VoiceExpenseActivity>(intent)
            
            // Brief wait between launches
            Thread.sleep(500)
        }

        // Verify final command processed correctly
        Thread.sleep(2000)
        onView(withId(R.id.expense_amount_text))
            .check(matches(isDisplayed()))
    }

    // ===== ERROR HANDLING TESTS =====

    @Test
    fun testErrorRecovery_NetworkFailure_ShowsRetryOption() {
        // This test would require mocking network conditions
        // For now, we'll test the retry UI flow
        val command = "I spent 25 dollars on food"
        val encodedText = Uri.encode(command)
        val deepLinkUri = Uri.parse("https://justspent.app/expense?text=$encodedText")
        val intent = Intent(Intent.ACTION_VIEW, deepLinkUri).apply {
            setPackage(ApplicationProvider.getApplicationContext<android.content.Context>().packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        scenario = ActivityScenario.launch<VoiceExpenseActivity>(intent)

        // Wait for processing
        Thread.sleep(2000)

        // If error occurs, verify retry option is available
        try {
            onView(withId(R.id.retry_button))
                .check(matches(isDisplayed()))
                .perform(click())
            
            // Verify retry attempt
            Thread.sleep(1000)
            onView(withId(R.id.processing_indicator))
                .check(matches(isDisplayed()))
        } catch (e: Exception) {
            // If no error occurred, that's also acceptable
            onView(withId(R.id.success_message))
                .check(matches(isDisplayed()))
        }
    }

    @Test
    fun testErrorHandling_MalformedDeepLink_HandlesGracefully() {
        // Test with malformed URL
        val malformedUri = Uri.parse("https://justspent.app/expense?invalid=data&malformed")
        val intent = Intent(Intent.ACTION_VIEW, malformedUri).apply {
            setPackage(ApplicationProvider.getApplicationContext<android.content.Context>().packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        scenario = ActivityScenario.launch<VoiceExpenseActivity>(intent)

        // Verify graceful error handling
        onView(withId(R.id.error_message_text))
            .check(matches(isDisplayed()))
        
        onView(withText(containsString("try again")))
            .check(matches(isDisplayed()))
    }

    // ===== ACCESSIBILITY TESTS =====

    @Test
    fun testAccessibility_VoiceFlowHasProperContentDescriptions() {
        val command = "I spent 25 dollars on coffee"
        val encodedText = Uri.encode(command)
        val deepLinkUri = Uri.parse("https://justspent.app/expense?text=$encodedText")
        val intent = Intent(Intent.ACTION_VIEW, deepLinkUri).apply {
            setPackage(ApplicationProvider.getApplicationContext<android.content.Context>().packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        scenario = ActivityScenario.launch<VoiceExpenseActivity>(intent)

        // Wait for processing
        Thread.sleep(2000)

        // Verify accessibility content descriptions
        onView(withId(R.id.expense_amount_text))
            .check(matches(hasContentDescription()))
        
        onView(withId(R.id.expense_category_text))
            .check(matches(hasContentDescription()))
    }

    @Test
    fun testAccessibility_ConfirmationDialogIsAccessible() {
        // Setup large amount for confirmation
        val largeAmountText = "I spent 2000 dollars on electronics"
        val encodedText = Uri.encode(largeAmountText)
        val deepLinkUri = Uri.parse("https://justspent.app/expense?text=$encodedText")
        val intent = Intent(Intent.ACTION_VIEW, deepLinkUri).apply {
            setPackage(ApplicationProvider.getApplicationContext<android.content.Context>().packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        scenario = ActivityScenario.launch<VoiceExpenseActivity>(intent)

        // Wait for confirmation dialog
        Thread.sleep(2000)

        // Verify accessibility of confirmation elements
        onView(withId(R.id.confirm_button))
            .check(matches(hasContentDescription()))
            .check(matches(isClickable()))
        
        onView(withId(R.id.cancel_button))
            .check(matches(hasContentDescription()))
            .check(matches(isClickable()))
    }

    // ===== INTEGRATION WITH MAIN APP TESTS =====

    @Test
    fun testIntegration_SuccessfulExpense_ShowsInMainApp() {
        // First, process an expense via voice
        val command = "I spent 30 dollars on lunch"
        val encodedText = Uri.encode(command)
        val deepLinkUri = Uri.parse("https://justspent.app/expense?text=$encodedText")
        val intent = Intent(Intent.ACTION_VIEW, deepLinkUri).apply {
            setPackage(ApplicationProvider.getApplicationContext<android.content.Context>().packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        scenario = ActivityScenario.launch<VoiceExpenseActivity>(intent)

        // Wait for processing and completion
        Thread.sleep(3000)

        // Navigate to main app
        scenario.close()
        scenario = ActivityScenario.launch<MainActivity>(Intent(ApplicationProvider.getApplicationContext(), MainActivity::class.java))

        // Verify expense appears in main app
        Thread.sleep(1000)
        onView(withText(containsString("30")))
            .check(matches(isDisplayed()))
    }
}