package com.justspent.app.ui

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.google.common.truth.Truth.assertThat
import com.justspent.app.data.model.Expense
import com.justspent.app.testutils.MockExpenseRepository
import com.justspent.app.ui.expenses.ExpenseListScreen
import com.justspent.app.ui.expenses.ExpenseListViewModel
import com.justspent.app.ui.theme.JustSpentTheme
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.math.BigDecimal

@RunWith(AndroidJUnit4::class)
class ExpenseListScreenUITest {
    
    @get:Rule
    val composeTestRule = createComposeRule()
    
    private lateinit var mockRepository: MockExpenseRepository
    private lateinit var viewModel: ExpenseListViewModel
    
    @Before
    fun setup() {
        mockRepository = MockExpenseRepository.successfulRepository()
        viewModel = ExpenseListViewModel(mockRepository)
    }
    
    @Test
    fun expenseListScreen_displaysEmptyState_whenNoExpenses() {
        // Given
        mockRepository.expensesToReturn = emptyList()
        
        // When
        composeTestRule.setContent {
            JustSpentTheme {
                ExpenseListScreen(
                    viewModel = viewModel,
                    onNavigateToVoice = {},
                    onNavigateToAdd = {}
                )
            }
        }
        
        // Then
        composeTestRule
            .onNodeWithText("No expenses yet")
            .assertIsDisplayed()
        
        composeTestRule
            .onNodeWithText("Start tracking your expenses by adding your first expense")
            .assertIsDisplayed()
    }
    
    @Test
    fun expenseListScreen_displaysExpenses_whenExpensesExist() {
        // Given
        val expenses = listOf(
            createSampleExpense("1", BigDecimal("25.50"), "Food & Dining", "Starbucks"),
            createSampleExpense("2", BigDecimal("15.00"), "Transport", "Uber"),
            createSampleExpense("3", BigDecimal("100.00"), "Shopping", "Mall")
        )
        mockRepository.expensesToReturn = expenses
        
        // When
        composeTestRule.setContent {
            JustSpentTheme {
                ExpenseListScreen(
                    viewModel = viewModel,
                    onNavigateToVoice = {},
                    onNavigateToAdd = {}
                )
            }
        }
        
        // Then
        composeTestRule
            .onNodeWithText("$25.50")
            .assertIsDisplayed()
        
        composeTestRule
            .onNodeWithText("Starbucks")
            .assertIsDisplayed()
        
        composeTestRule
            .onNodeWithText("Food & Dining")
            .assertIsDisplayed()
        
        composeTestRule
            .onNodeWithText("$15.00")
            .assertIsDisplayed()
        
        composeTestRule
            .onNodeWithText("Uber")
            .assertIsDisplayed()
        
        composeTestRule
            .onNodeWithText("Transport")
            .assertIsDisplayed()
    }
    
    @Test
    fun expenseListScreen_displaysTotalSpending_correctly() {
        // Given
        val expenses = listOf(
            createSampleExpense("1", BigDecimal("25.50")),
            createSampleExpense("2", BigDecimal("30.25")),
            createSampleExpense("3", BigDecimal("44.25"))
        )
        mockRepository.expensesToReturn = expenses
        
        // When
        composeTestRule.setContent {
            JustSpentTheme {
                ExpenseListScreen(
                    viewModel = viewModel,
                    onNavigateToVoice = {},
                    onNavigateToAdd = {}
                )
            }
        }
        
        // Then
        composeTestRule
            .onNodeWithText("$100.00") // Total spending
            .assertIsDisplayed()
    }
    
    @Test
    fun expenseListScreen_fabButton_triggersVoiceNavigation() {
        // Given
        var voiceNavigationCalled = false
        
        // When
        composeTestRule.setContent {
            JustSpentTheme {
                ExpenseListScreen(
                    viewModel = viewModel,
                    onNavigateToVoice = { voiceNavigationCalled = true },
                    onNavigateToAdd = {}
                )
            }
        }
        
        // Find and click the voice FAB
        composeTestRule
            .onNodeWithContentDescription("Add expense with voice")
            .performClick()
        
        // Then
        assertThat(voiceNavigationCalled).isTrue()
    }
    
    @Test
    fun expenseListScreen_addButton_triggersAddNavigation() {
        // Given
        var addNavigationCalled = false
        
        // When
        composeTestRule.setContent {
            JustSpentTheme {
                ExpenseListScreen(
                    viewModel = viewModel,
                    onNavigateToVoice = {},
                    onNavigateToAdd = { addNavigationCalled = true }
                )
            }
        }
        
        // Find and click the add button (could be in menu or as secondary action)
        composeTestRule
            .onNodeWithContentDescription("Add expense manually")
            .performClick()
        
        // Then
        assertThat(addNavigationCalled).isTrue()
    }
    
    @Test
    fun expenseListScreen_swipeToDelete_removesExpense() {
        // Given
        val expenses = listOf(
            createSampleExpense("1", BigDecimal("25.50"), "Food & Dining", "Starbucks"),
            createSampleExpense("2", BigDecimal("15.00"), "Transport", "Uber")
        )
        mockRepository.expensesToReturn = expenses
        
        // When
        composeTestRule.setContent {
            JustSpentTheme {
                ExpenseListScreen(
                    viewModel = viewModel,
                    onNavigateToVoice = {},
                    onNavigateToAdd = {}
                )
            }
        }
        
        // Perform swipe to delete on first expense
        composeTestRule
            .onNodeWithText("Starbucks")
            .performTouchInput { swipeLeft() }
        
        // Then
        composeTestRule.waitUntil(timeoutMillis = 2000) {
            mockRepository.deleteExpenseCalled
        }
        assertThat(mockRepository.deleteExpenseCalled).isTrue()
    }
    
    @Test\n    fun expenseListScreen_pullToRefresh_refreshesData() {\n        // Given\n        val initialExpenses = listOf(\n            createSampleExpense(\"1\", BigDecimal(\"25.50\"))\n        )\n        mockRepository.expensesToReturn = initialExpenses\n        \n        // When\n        composeTestRule.setContent {\n            JustSpentTheme {\n                ExpenseListScreen(\n                    viewModel = viewModel,\n                    onNavigateToVoice = {},\n                    onNavigateToAdd = {}\n                )\n            }\n        }\n        \n        // Perform pull to refresh\n        composeTestRule\n            .onRoot()\n            .performTouchInput { swipeDown() }\n        \n        // Then\n        composeTestRule.waitUntil(timeoutMillis = 2000) {\n            mockRepository.getAllExpensesCalled\n        }\n        assertThat(mockRepository.getAllExpensesCalled).isTrue()\n    }\n    \n    @Test\n    fun expenseListScreen_displaysLoadingState_whenLoading() {\n        // Given\n        mockRepository = MockExpenseRepository.slowRepository(2000L)\n        viewModel = ExpenseListViewModel(mockRepository)\n        \n        // When\n        composeTestRule.setContent {\n            JustSpentTheme {\n                ExpenseListScreen(\n                    viewModel = viewModel,\n                    onNavigateToVoice = {},\n                    onNavigateToAdd = {}\n                )\n            }\n        }\n        \n        // Then\n        composeTestRule\n            .onNodeWithContentDescription(\"Loading\")\n            .assertIsDisplayed()\n    }\n    \n    @Test\n    fun expenseListScreen_displaysErrorState_whenError() {\n        // Given\n        mockRepository = MockExpenseRepository.failingRepository(\n            Exception(\"Network error\")\n        )\n        viewModel = ExpenseListViewModel(mockRepository)\n        \n        // When\n        composeTestRule.setContent {\n            JustSpentTheme {\n                ExpenseListScreen(\n                    viewModel = viewModel,\n                    onNavigateToVoice = {},\n                    onNavigateToAdd = {}\n                )\n            }\n        }\n        \n        // Then\n        composeTestRule\n            .onNodeWithText(\"Network error\")\n            .assertIsDisplayed()\n    }\n    \n    @Test\n    fun expenseListScreen_handlesLargeDataset() {\n        // Given\n        val largeExpenseList = (1..100).map { index ->\n            createSampleExpense(\n                id = \"expense-$index\",\n                amount = BigDecimal(\"${index * 10}.50\"),\n                category = \"Category $index\",\n                merchant = \"Merchant $index\"\n            )\n        }\n        mockRepository.expensesToReturn = largeExpenseList\n        \n        // When\n        composeTestRule.setContent {\n            JustSpentTheme {\n                ExpenseListScreen(\n                    viewModel = viewModel,\n                    onNavigateToVoice = {},\n                    onNavigateToAdd = {}\n                )\n            }\n        }\n        \n        // Then - Check that list can scroll and display items\n        composeTestRule\n            .onNodeWithText(\"Merchant 1\")\n            .assertIsDisplayed()\n        \n        // Scroll to find an item further down\n        composeTestRule\n            .onRoot()\n            .performTouchInput { swipeUp() }\n        \n        // Should be able to scroll through the list without performance issues\n        composeTestRule\n            .onNodeWithText(\"$1000.50\") // Last item amount\n            .assertIsDisplayed()\n    }\n    \n    @Test\n    fun expenseListScreen_accessibilityLabels_areCorrect() {\n        // Given\n        val expense = createSampleExpense(\n            \"1\", \n            BigDecimal(\"25.50\"), \n            \"Food & Dining\", \n            \"Starbucks\"\n        )\n        mockRepository.expensesToReturn = listOf(expense)\n        \n        // When\n        composeTestRule.setContent {\n            JustSpentTheme {\n                ExpenseListScreen(\n                    viewModel = viewModel,\n                    onNavigateToVoice = {},\n                    onNavigateToAdd = {}\n                )\n            }\n        }\n        \n        // Then - Check accessibility labels\n        composeTestRule\n            .onNodeWithContentDescription(\"Add expense with voice\")\n            .assertIsDisplayed()\n        \n        composeTestRule\n            .onNodeWithContentDescription(\"Expense: $25.50 at Starbucks for Food & Dining\")\n            .assertIsDisplayed()\n    }\n    \n    @Test\n    fun expenseListScreen_darkMode_rendersCorrectly() {\n        // Given\n        val expense = createSampleExpense(\"1\", BigDecimal(\"25.50\"))\n        mockRepository.expensesToReturn = listOf(expense)\n        \n        // When\n        composeTestRule.setContent {\n            JustSpentTheme(darkTheme = true) {\n                ExpenseListScreen(\n                    viewModel = viewModel,\n                    onNavigateToVoice = {},\n                    onNavigateToAdd = {}\n                )\n            }\n        }\n        \n        // Then - Screen should render without crashes in dark mode\n        composeTestRule\n            .onNodeWithText(\"$25.50\")\n            .assertIsDisplayed()\n    }\n    \n    @Test\n    fun expenseListScreen_multiCurrency_displaysCorrectly() {\n        // Given\n        val expenses = listOf(\n            createSampleExpense(\"1\", BigDecimal(\"25.50\")).copy(currency = \"USD\"),\n            createSampleExpense(\"2\", BigDecimal(\"100.00\")).copy(currency = \"AED\"),\n            createSampleExpense(\"3\", BigDecimal(\"20.00\")).copy(currency = \"EUR\")\n        )\n        mockRepository.expensesToReturn = expenses\n        \n        // When\n        composeTestRule.setContent {\n            JustSpentTheme {\n                ExpenseListScreen(\n                    viewModel = viewModel,\n                    onNavigateToVoice = {},\n                    onNavigateToAdd = {}\n                )\n            }\n        }\n        \n        // Then\n        composeTestRule\n            .onNodeWithText(\"$25.50\")\n            .assertIsDisplayed()\n        \n        composeTestRule\n            .onNodeWithText(\"100.00 AED\")\n            .assertIsDisplayed()\n        \n        composeTestRule\n            .onNodeWithText(\"€20.00\")\n            .assertIsDisplayed()\n    }\n    \n    private fun createSampleExpense(\n        id: String,\n        amount: BigDecimal,\n        category: String = \"Food & Dining\",\n        merchant: String = \"Test Merchant\"\n    ): Expense {\n        val now = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())\n        return Expense(\n            id = id,\n            userId = \"test-user\",\n            amount = amount,\n            currency = \"USD\",\n            category = category,\n            merchant = merchant,\n            description = \"Test expense\",\n            notes = \"Test notes\",\n            transactionDate = now,\n            createdAt = now,\n            updatedAt = now,\n            source = \"manual\",\n            voiceTranscript = null\n        )\n    }\n}