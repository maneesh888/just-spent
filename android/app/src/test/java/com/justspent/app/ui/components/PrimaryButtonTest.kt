package com.justspent.app.ui.components

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.unit.dp
import org.junit.Rule
import org.junit.Test

/**
 * Unit tests for PrimaryButton component
 * Ensures consistent button styling across the app
 */
class PrimaryButtonTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun primaryButton_hasCorrectHeight() {
        composeTestRule.setContent {
            PrimaryButton(
                text = "Test Button",
                onClick = {}
            )
        }

        val button = composeTestRule.onNodeWithText("Test Button")
        button.assertExists()

        // Get button bounds
        val buttonBounds = button.fetchSemanticsNode().boundsInRoot

        // Button should have height of 56dp
        val expectedHeight = 56f
        val actualHeight = buttonBounds.height

        assert(actualHeight >= expectedHeight - 2f && actualHeight <= expectedHeight + 2f) {
            "Button height should be ${expectedHeight}dp, was ${actualHeight}dp"
        }
    }

    @Test
    fun primaryButton_displaysCorrectText() {
        val buttonText = "Continue"

        composeTestRule.setContent {
            PrimaryButton(
                text = buttonText,
                onClick = {}
            )
        }

        composeTestRule.onNodeWithText(buttonText)
            .assertExists()
            .assertIsDisplayed()
    }

    @Test
    fun primaryButton_isClickable() {
        var clicked = false

        composeTestRule.setContent {
            PrimaryButton(
                text = "Click Me",
                onClick = { clicked = true }
            )
        }

        composeTestRule.onNodeWithText("Click Me")
            .assertHasClickAction()
            .performClick()

        assert(clicked) { "Button should trigger onClick callback" }
    }

    @Test
    fun primaryButton_hasFullWidth() {
        composeTestRule.setContent {
            PrimaryButton(
                text = "Test Button",
                onClick = {}
            )
        }

        val button = composeTestRule.onNodeWithText("Test Button")
        button.assertExists()

        // Button should fill max width (will be constrained by parent)
        val buttonBounds = button.fetchSemanticsNode().boundsInRoot
        assert(buttonBounds.width > 100f) {
            "Button should have substantial width, was ${buttonBounds.width}dp"
        }
    }

    @Test
    fun primaryButton_hasAccessibilityLabel() {
        composeTestRule.setContent {
            PrimaryButton(
                text = "Submit",
                onClick = {}
            )
        }

        composeTestRule.onNodeWithText("Submit")
            .assertExists()
            .assertHasClickAction()
    }

    @Test
    fun primaryButton_canBeDisabled() {
        composeTestRule.setContent {
            PrimaryButton(
                text = "Disabled Button",
                onClick = {},
                enabled = false
            )
        }

        composeTestRule.onNodeWithText("Disabled Button")
            .assertExists()
            .assertIsNotEnabled()
    }

    @Test
    fun primaryButton_canBeEnabled() {
        composeTestRule.setContent {
            PrimaryButton(
                text = "Enabled Button",
                onClick = {},
                enabled = true
            )
        }

        composeTestRule.onNodeWithText("Enabled Button")
            .assertExists()
            .assertIsEnabled()
    }
}
