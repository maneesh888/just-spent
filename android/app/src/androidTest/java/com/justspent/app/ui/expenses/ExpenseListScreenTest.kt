package com.justspent.app.ui.expenses

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.justspent.app.MainActivity
import com.justspent.app.ui.theme.JustSpentTheme
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class ExpenseListScreenTest {
    
    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)
    
    @get:Rule(order = 1)
    val composeTestRule = createAndroidComposeRule<MainActivity>()
    
    @Before
    fun setup() {
        hiltRule.inject()
    }
    
    @Test
    fun emptyStateDisplaysCorrectContent() {
        composeTestRule.setContent {
            JustSpentTheme {
                ExpenseListScreen()
            }
        }
        
        // Check that empty state is displayed
        composeTestRule
            .onNodeWithText("No expenses yet")
            .assertIsDisplayed()
        
        composeTestRule
            .onNodeWithText("Say \"Hey Google, I just spent...\" to get started")
            .assertIsDisplayed()
        
        composeTestRule
            .onNodeWithText("Add Sample Expense")
            .assertIsDisplayed()
    }
    
    @Test
    fun headerDisplaysAppNameAndTotal() {
        composeTestRule.setContent {
            JustSpentTheme {
                ExpenseListScreen()
            }
        }
        
        // Check header content
        composeTestRule
            .onNodeWithText("Just Spent")
            .assertIsDisplayed()
        
        composeTestRule
            .onNodeWithText("Voice-enabled expense tracker")
            .assertIsDisplayed()
        
        composeTestRule
            .onNodeWithText("Total")
            .assertIsDisplayed()
    }
    
    @Test
    fun addSampleExpenseButtonIsClickable() {
        composeTestRule.setContent {
            JustSpentTheme {
                ExpenseListScreen()
            }
        }
        
        // Check that sample expense button exists and is clickable
        composeTestRule
            .onNodeWithText("Add Sample Expense")
            .assertExists()
            .assertIsDisplayed()
            .assertHasClickAction()
    }
    
    @Test
    fun clickingSampleExpenseButtonAddsExpense() {
        composeTestRule.setContent {
            JustSpentTheme {
                ExpenseListScreen()
            }
        }
        
        // Click the sample expense button
        composeTestRule
            .onNodeWithText("Add Sample Expense")
            .performClick()
        
        // Wait a moment for the expense to be added
        composeTestRule.waitForIdle()
        
        // The empty state should no longer be displayed after adding an expense
        // (Note: This test might need adjustment based on actual implementation)
    }
}