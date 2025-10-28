package com.justspent.app

import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.assertIsDisplayed
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Instrumented UI test for MainContentScreen
 */
@RunWith(AndroidJUnit4::class)
class MainContentScreenUITest {

    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun appTitle_isDisplayed() {
        // Verify the app title appears
        composeTestRule.onNodeWithText("Just Spent").assertIsDisplayed()
    }

    @Test
    fun emptyState_isDisplayed() {
        // Verify empty state message appears when no expenses
        composeTestRule.onNodeWithText("No Expenses Yet").assertIsDisplayed()
    }
}
