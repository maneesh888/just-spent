package com.justspent.app

import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.assertIsDisplayed
import androidx.test.ext.junit.runners.AndroidJUnit4
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Instrumented UI test for MainContentScreen
 */
@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class MainContentScreenUITest {

    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Before
    fun setUp() {
        hiltRule.inject()
    }

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
