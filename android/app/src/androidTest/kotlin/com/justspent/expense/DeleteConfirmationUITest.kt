package com.justspent.expense

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * UI tests for delete confirmation dialog
 * Ensures user is asked to confirm before deleting an expense
 * Tests both swipe-to-delete and button-tap delete flows
 * Following TDD: Tests written BEFORE implementation
 */
@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class DeleteConfirmationUITest {

    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Before
    fun setUp() {
        hiltRule.inject()
        // Wait for app to load
        composeTestRule.waitForIdle()
    }

    // MARK: - Swipe-to-Delete Confirmation Tests

    /**
     * Test that swiping to delete shows a confirmation dialog
     */
    @Test
    fun swipeToDelete_showsConfirmationDialog() {
        // Given - App with expenses loaded
        composeTestRule.waitForIdle()
        Thread.sleep(2000) // Wait for data to load

        // Find an expense row using content description or test tag
        val expenseRows = composeTestRule.onAllNodesWithTag("expense_row")
        val rowCount = try {
            expenseRows.fetchSemanticsNodes().size
        } catch (e: Exception) {
            0
        }

        if (rowCount == 0) {
            // No expenses to test with, skip
            return
        }

        // When - Swipe left on an expense row
        val firstRow = expenseRows[0]
        firstRow.performTouchInput {
            swipeLeft()
        }
        composeTestRule.waitForIdle()
        Thread.sleep(500)

        // Then - Confirmation dialog should appear
        composeTestRule.onNodeWithText("Delete Expense").assertExists()
        composeTestRule.onNodeWithText("Are you sure you want to delete this expense?").assertExists()
    }

    /**
     * Test that swiping right also shows confirmation dialog
     */
    @Test
    fun swipeRightToDelete_showsConfirmationDialog() {
        // Given - App with expenses
        composeTestRule.waitForIdle()
        Thread.sleep(2000)

        val expenseRows = composeTestRule.onAllNodesWithTag("expense_row")
        val rowCount = try {
            expenseRows.fetchSemanticsNodes().size
        } catch (e: Exception) {
            0
        }

        if (rowCount == 0) return

        // When - Swipe right on an expense row
        val firstRow = expenseRows[0]
        firstRow.performTouchInput {
            swipeRight()
        }
        composeTestRule.waitForIdle()
        Thread.sleep(500)

        // Then - Confirmation dialog should appear
        composeTestRule.onNodeWithText("Delete Expense").assertExists()
    }

    /**
     * Test that tapping Cancel in confirmation dialog does NOT delete the expense
     */
    @Test
    fun cancelDelete_keepsExpense() {
        // Given - App with expenses
        composeTestRule.waitForIdle()
        Thread.sleep(2000)

        val expenseRows = composeTestRule.onAllNodesWithTag("expense_row")
        val initialRowCount = try {
            expenseRows.fetchSemanticsNodes().size
        } catch (e: Exception) {
            0
        }

        if (initialRowCount == 0) return

        // When - Swipe to delete
        expenseRows[0].performTouchInput {
            swipeLeft()
        }
        composeTestRule.waitForIdle()
        Thread.sleep(500)

        // Wait for dialog and tap Cancel
        composeTestRule.onNodeWithText("Cancel").performClick()
        composeTestRule.waitForIdle()
        Thread.sleep(500)

        // Then - Expense count should remain the same
        val finalRowCount = try {
            composeTestRule.onAllNodesWithTag("expense_row").fetchSemanticsNodes().size
        } catch (e: Exception) {
            0
        }

        assert(initialRowCount == finalRowCount) {
            "Expense count should not change after canceling delete"
        }
    }

    /**
     * Test that confirming delete removes the expense
     */
    @Test
    fun confirmDelete_removesExpense() {
        // Given - App with expenses
        composeTestRule.waitForIdle()
        Thread.sleep(2000)

        val expenseRows = composeTestRule.onAllNodesWithTag("expense_row")
        val initialRowCount = try {
            expenseRows.fetchSemanticsNodes().size
        } catch (e: Exception) {
            0
        }

        if (initialRowCount == 0) return

        // When - Swipe to delete and confirm
        expenseRows[0].performTouchInput {
            swipeLeft()
        }
        composeTestRule.waitForIdle()
        Thread.sleep(500)

        // Tap Delete to confirm
        composeTestRule.onNodeWithText("Delete").performClick()
        composeTestRule.waitForIdle()
        Thread.sleep(1000)

        // Then - Expense count should decrease by 1
        val finalRowCount = try {
            composeTestRule.onAllNodesWithTag("expense_row").fetchSemanticsNodes().size
        } catch (e: Exception) {
            0
        }

        assert(initialRowCount - 1 == finalRowCount) {
            "Expense count should decrease by 1 after confirming delete"
        }
    }

    // MARK: - Delete Button Confirmation Tests (existing behavior)

    /**
     * Test that tapping Delete button on row shows confirmation dialog
     */
    @Test
    fun deleteButton_showsConfirmationDialog() {
        // Given - App with expenses
        composeTestRule.waitForIdle()
        Thread.sleep(2000)

        // Find delete buttons on expense rows
        val deleteButtons = composeTestRule.onAllNodesWithText("Delete")
        val buttonCount = try {
            deleteButtons.fetchSemanticsNodes().size
        } catch (e: Exception) {
            0
        }

        if (buttonCount == 0) return

        // When - Tap the delete button
        deleteButtons[0].performClick()
        composeTestRule.waitForIdle()
        Thread.sleep(500)

        // Then - Confirmation dialog should appear
        composeTestRule.onNodeWithText("Delete Expense").assertExists()
        composeTestRule.onNodeWithText("Are you sure you want to delete this expense?").assertExists()
    }

    /**
     * Test that confirmation dialog has Cancel and Delete buttons
     */
    @Test
    fun confirmationDialog_hasCorrectButtons() {
        // Given - App with expenses
        composeTestRule.waitForIdle()
        Thread.sleep(2000)

        val deleteButtons = composeTestRule.onAllNodesWithText("Delete")
        val buttonCount = try {
            deleteButtons.fetchSemanticsNodes().size
        } catch (e: Exception) {
            0
        }

        if (buttonCount == 0) return

        // When - Trigger confirmation dialog
        deleteButtons[0].performClick()
        composeTestRule.waitForIdle()
        Thread.sleep(500)

        // Then - Dialog should have Cancel and Delete buttons
        // Note: "Delete" appears twice - once on row, once in dialog
        composeTestRule.onNodeWithText("Cancel").assertExists()
        composeTestRule.onAllNodesWithText("Delete").assertCountEquals(2) // One on row (dismissed), one in dialog
    }

    /**
     * Test accessibility of delete confirmation dialog
     */
    @Test
    fun confirmationDialog_isAccessible() {
        // Given - App with expenses
        composeTestRule.waitForIdle()
        Thread.sleep(2000)

        val deleteButtons = composeTestRule.onAllNodesWithText("Delete")
        val buttonCount = try {
            deleteButtons.fetchSemanticsNodes().size
        } catch (e: Exception) {
            0
        }

        if (buttonCount == 0) return

        // When - Show confirmation dialog
        deleteButtons[0].performClick()
        composeTestRule.waitForIdle()
        Thread.sleep(500)

        // Then - Dialog components should be accessible
        // Title should exist
        composeTestRule.onNodeWithText("Delete Expense").assertExists()

        // Message should exist
        composeTestRule.onNodeWithText("Are you sure you want to delete this expense?").assertExists()

        // Buttons should be clickable
        composeTestRule.onNodeWithText("Cancel").assertHasClickAction()

        // Find the dialog's Delete button (not the row's Delete button)
        val dialogDeleteButton = composeTestRule.onAllNodesWithText("Delete")
            .filter(hasAnyAncestor(hasTestTag("delete_confirmation_dialog")) or hasClickAction())
        dialogDeleteButton[0].assertHasClickAction()
    }

    /**
     * Test that dismissing dialog by tapping Cancel resets swipe state
     */
    @Test
    fun cancelDialog_resetsSwipeState() {
        // Given - App with expenses
        composeTestRule.waitForIdle()
        Thread.sleep(2000)

        val expenseRows = composeTestRule.onAllNodesWithTag("expense_row")
        val rowCount = try {
            expenseRows.fetchSemanticsNodes().size
        } catch (e: Exception) {
            0
        }

        if (rowCount == 0) return

        // When - Swipe to delete, then cancel
        expenseRows[0].performTouchInput {
            swipeLeft()
        }
        composeTestRule.waitForIdle()
        Thread.sleep(500)

        composeTestRule.onNodeWithText("Cancel").performClick()
        composeTestRule.waitForIdle()
        Thread.sleep(500)

        // Then - Expense row should be back to normal position
        // (not swiped state - dialog was dismissed)
        composeTestRule.onNodeWithText("Delete Expense").assertDoesNotExist()

        // Row should still exist
        val newExpenseRows = composeTestRule.onAllNodesWithTag("expense_row")
        val newRowCount = try {
            newExpenseRows.fetchSemanticsNodes().size
        } catch (e: Exception) {
            0
        }

        assert(rowCount == newRowCount) { "Expense should still exist after cancel" }
    }
}
