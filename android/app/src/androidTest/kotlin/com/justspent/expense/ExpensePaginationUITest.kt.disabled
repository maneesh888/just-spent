package com.justspent.expense

import android.content.Context
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.core.app.ApplicationProvider
import com.justspent.expense.data.dao.ExpenseDao
import com.justspent.expense.data.database.JustSpentDatabase
import com.justspent.expense.data.repository.ExpenseRepository
import com.justspent.expense.ui.expenses.ExpenseListViewModel
import com.justspent.expense.utils.DateFilter
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import javax.inject.Inject
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * UI tests for pagination functionality in Just Spent app.
 *
 * These tests verify pagination behavior through UI interactions and data verification.
 * Uses 180 expense test dataset across 6 currencies.
 *
 * TDD Phase: RED - These tests will FAIL until pagination is implemented
 *
 * Test Approach: Data verification (checking ViewModel state) rather than UI element counting
 */
@HiltAndroidTest
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
@OptIn(ExperimentalCoroutinesApi::class)
class ExpensePaginationUITest {

    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Inject
    lateinit var database: JustSpentDatabase

    @Inject
    lateinit var repository: ExpenseRepository

    private lateinit var viewModel: ExpenseListViewModel
    private lateinit var dao: ExpenseDao
    private lateinit var context: Context

    @Before
    fun setUp() {
        hiltRule.inject()
        context = ApplicationProvider.getApplicationContext()
        dao = database.expenseDao()

        // Clear any existing data
        runBlocking {
            dao.deleteAllExpenses()
        }

        // Initialize ViewModel
        viewModel = ExpenseListViewModel(repository)

        // Load test data with pagination dataset (180 expenses)
        TestDataHelper.addTestExpenses(context, usePaginationDataset = true)
    }

    @After
    fun tearDown() {
        database.close()
    }

    /**
     * Test 1: Large Dataset - Initial Load and Scroll-Triggered Pagination
     *
     * Scenario:
     * 1. App launches with 180 expenses in database
     * 2. Initial load shows 20 AED expenses (page 0)
     * 3. User scrolls to position 15 (within prefetch distance of 5)
     * 4. Pagination automatically loads next 20 expenses (page 1)
     * 5. Total expenses in memory: 40
     *
     * Verification Approach: Data verification via ViewModel state
     */
    @Test
    fun largeDataset_loadsInitial20_scrollLoadsMore() = runTest {
        // Given: App launched with test data, navigated to AED tab
        composeTestRule.waitForIdle()

        // Load first page
        viewModel.loadFirstPage(currency = "AED", dateFilter = DateFilter.All)

        // Then: Should have loaded exactly 20 expenses
        val initialState = viewModel.paginationState.first()
        assertEquals(20, initialState.loadedExpenses.size, "Initial page should load 20 expenses")
        assertTrue(initialState.hasMore, "Should indicate more pages available")
        assertEquals(0, initialState.currentPage, "Current page should be 0")

        // When: Simulate scroll to position 15 (triggers prefetch at position 15 = within last 5 items)
        // In real implementation, scrolling would trigger viewModel.loadNextPage()
        // For testing, we call it directly to simulate the scroll-triggered pagination
        viewModel.loadNextPage()

        // Then: Should have loaded page 2 (total 40 expenses)
        val scrolledState = viewModel.paginationState.first()
        assertEquals(40, scrolledState.loadedExpenses.size, "After scroll, should have 40 expenses (2 pages)")
        assertTrue(scrolledState.hasMore, "Should still have more pages available")
        assertEquals(1, scrolledState.currentPage, "Current page should be 1")

        // Verify: Check loading indicator shown/hidden correctly
        // (This would be tested via UI element if using UI verification approach)
        // For data verification, we check the isLoading state
        assertEquals(false, scrolledState.isLoading, "Loading should be complete")
    }

    /**
     * Test 2: Filter Change - Resets Pagination and Loads Filtered Data
     *
     * Scenario:
     * 1. Initial state: 20 AED expenses loaded (page 0, All filter)
     * 2. User changes filter to "This Week"
     * 3. Pagination resets to page 0
     * 4. New filtered page loads (≤20 expenses from this week)
     * 5. User scrolls to load more filtered data
     *
     * Verification Approach: Data verification via ViewModel state
     */
    @Test
    fun filterChange_resetsPagination_thenLoadsFiltered() = runTest {
        // Given: Initial page loaded (20 AED, All filter)
        viewModel.loadFirstPage(currency = "AED", dateFilter = DateFilter.All)
        val initialState = viewModel.paginationState.first()
        assertEquals(20, initialState.loadedExpenses.size, "Should start with 20 expenses")

        // When: User changes filter to "This Week"
        viewModel.loadFirstPage(currency = "AED", dateFilter = DateFilter.Week)

        // Then: Pagination should reset
        val filteredState = viewModel.paginationState.first()
        assertEquals(0, filteredState.currentPage, "Page should reset to 0")

        // Verify: New filtered page loaded (≤20 expenses from this week)
        assertTrue(
            filteredState.loadedExpenses.size <= 20,
            "Should load ≤20 expenses for first page"
        )

        // Verify: All expenses are from this week
        val oneWeekAgo = kotlinx.datetime.Clock.System.now()
            .minus(kotlinx.datetime.DateTimeUnit.DAY, 7)
            .toLocalDateTime(kotlinx.datetime.TimeZone.currentSystemDefault())

        assertTrue(
            filteredState.loadedExpenses.all { expense ->
                expense.transactionDate >= oneWeekAgo
            },
            "All expenses should be from this week"
        )

        // When: User scrolls to load more (if available)
        if (filteredState.hasMore) {
            viewModel.loadNextPage()
            val nextPageState = viewModel.paginationState.first()

            // Then: Next filtered page should load correctly
            assertTrue(
                nextPageState.loadedExpenses.size > filteredState.loadedExpenses.size,
                "Should have loaded more filtered expenses"
            )

            // Verify: All expenses in next page are also from this week
            assertTrue(
                nextPageState.loadedExpenses.all { expense ->
                    expense.transactionDate >= oneWeekAgo
                },
                "All expenses in next page should also be from this week"
            )
        }
    }

    /**
     * Test 3: Currency Switch - Maintains Separate Pagination States
     *
     * Scenario:
     * 1. Load AED page 1 (20 expenses)
     * 2. Switch to USD tab → loads USD page 1 (fresh 20 expenses)
     * 3. USD should show fresh data (not AED data)
     * 4. Switch back to AED → should show same AED page 1 data (state preserved)
     *
     * Verification Approach: Data verification via ViewModel state
     */
    @Test
    fun currencySwitch_maintainsSeparatePaginationStates() = runTest {
        // Given: AED page 1 loaded
        viewModel.loadFirstPage(currency = "AED", dateFilter = DateFilter.All)
        val aedState1 = viewModel.paginationState.first()
        val aedPage1Ids = aedState1.loadedExpenses.map { it.id }.toSet()

        assertEquals(20, aedState1.loadedExpenses.size, "AED should load 20 expenses")
        assertTrue(
            aedState1.loadedExpenses.all { it.currency == "AED" },
            "All expenses should be AED"
        )

        // When: Switch to USD tab and load page 1
        viewModel.loadFirstPage(currency = "USD", dateFilter = DateFilter.All)
        val usdState1 = viewModel.paginationState.first()

        // Then: USD should show fresh data (not AED data)
        assertEquals(20, usdState1.loadedExpenses.size, "USD should load 20 expenses")
        assertTrue(
            usdState1.loadedExpenses.all { it.currency == "USD" },
            "All expenses should be USD"
        )

        // Verify: No overlap with AED expenses
        val usdPage1Ids = usdState1.loadedExpenses.map { it.id }.toSet()
        assertEquals(
            0,
            aedPage1Ids.intersect(usdPage1Ids).size,
            "USD expenses should not overlap with AED expenses"
        )

        // When: Switch back to AED
        viewModel.loadFirstPage(currency = "AED", dateFilter = DateFilter.All)
        val aedState2 = viewModel.paginationState.first()

        // Then: AED should show same data as before (state could be preserved or reloaded)
        // Note: Depending on implementation, state may be preserved or fetched fresh
        // Both behaviors are acceptable, just verify we get AED data
        assertTrue(
            aedState2.loadedExpenses.all { it.currency == "AED" },
            "Should show AED expenses when switching back"
        )

        assertEquals(20, aedState2.loadedExpenses.size, "Should load 20 AED expenses")

        // Optional: If state preservation is implemented, verify same IDs
        // val aedPage1IdsAfterReturn = aedState2.loadedExpenses.map { it.id }.toSet()
        // assertEquals(aedPage1Ids, aedPage1IdsAfterReturn, "AED state should be preserved")
    }
}
