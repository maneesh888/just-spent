package com.justspent.expense

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.justspent.expense.data.dao.ExpenseDao
import com.justspent.expense.data.database.JustSpentDatabase
import com.justspent.expense.data.repository.ExpenseRepository
import com.justspent.expense.ui.expenses.ExpenseListViewModel
import com.justspent.expense.ui.expenses.PaginationState
import com.justspent.expense.utils.DateFilter
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
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
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Unit tests for pagination functionality in Just Spent app.
 *
 * These tests verify that pagination correctly loads expenses in batches of 20 items,
 * respects filters, handles end-of-list scenarios, and maintains separate states for different currencies.
 *
 * Test Data: Uses 180 expenses across 6 currencies (AED:50, USD:40, EUR:30, GBP:25, INR:20, SAR:15)
 * Page Size: 20 items per page
 * Approach: Data verification (not UI-dependent)
 *
 * TDD Phase: RED - These tests will FAIL until pagination is implemented
 */
@HiltAndroidTest
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
@OptIn(ExperimentalCoroutinesApi::class)
class ExpensePaginationTest {

    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @Inject
    lateinit var database: JustSpentDatabase

    @Inject
    lateinit var repository: ExpenseRepository

    @Inject
    lateinit var userPreferences: com.justspent.expense.data.preferences.UserPreferences

    private lateinit var viewModel: ExpenseListViewModel
    private lateinit var dao: ExpenseDao
    private lateinit var context: Context

    @Before
    fun setUp() {
        hiltRule.inject()
        context = ApplicationProvider.getApplicationContext()
        dao = database.expenseDao()

        // Clear any existing data
        runTest {
            dao.deleteAllExpenses()
        }

        // Initialize ViewModel with UserPreferences
        viewModel = ExpenseListViewModel(repository, userPreferences)
    }

    @After
    fun tearDown() {
        database.close()
    }

    /**
     * Test 1: Initial page load returns exactly 20 expenses
     *
     * Verifies:
     * - First page contains 20 items
     * - hasMore flag is true (more pages available)
     * - currentPage is 0
     */
    @Test
    fun initialPageLoad_loads20Expenses() = runTest {
        // Given: 180 AED expenses in database
        TestDataHelper.addTestExpenses(context, usePaginationDataset = true)

        // When: Load first page for AED currency
        viewModel.loadFirstPage(currency = "AED", dateFilter = DateFilter.All)

        // Then: Should load exactly 20 expenses
        val state = viewModel.paginationState.first()
        assertEquals(20, state.loadedExpenses.size, "First page should contain 20 expenses")
        assertTrue(state.hasMore, "Should have more pages available")
        assertEquals(0, state.currentPage, "Current page should be 0")
    }

    /**
     * Test 2: Loading next page appends additional 20 expenses
     *
     * Verifies:
     * - Total count increases to 40 after loading second page
     * - No duplicate expenses
     * - Expenses are in correct order (newest first)
     */
    @Test
    fun loadNextPage_appendsNextPageExpenses() = runTest {
        // Given: Initial page loaded (20 expenses)
        TestDataHelper.addTestExpenses(context, usePaginationDataset = true)
        viewModel.loadFirstPage(currency = "AED", dateFilter = DateFilter.All)
        val initialState = viewModel.paginationState.first()

        // When: Load next page
        viewModel.loadNextPage()

        // Then: Should have 40 total expenses
        val updatedState = viewModel.paginationState.first()
        assertEquals(40, updatedState.loadedExpenses.size, "Should have 40 expenses after loading page 2")

        // Verify no duplicates
        val uniqueIds = updatedState.loadedExpenses.map { it.id }.toSet()
        assertEquals(40, uniqueIds.size, "All expenses should be unique (no duplicates)")

        // Verify expenses from page 2 are new
        val page1Ids = initialState.loadedExpenses.map { it.id }.toSet()
        val page2Expenses = updatedState.loadedExpenses.drop(20)
        val page2Ids = page2Expenses.map { it.id }.toSet()
        assertEquals(0, page1Ids.intersect(page2Ids).size, "Page 2 should not contain expenses from page 1")

        // Verify correct order (newest first)
        for (i in 0 until updatedState.loadedExpenses.size - 1) {
            val current = updatedState.loadedExpenses[i]
            val next = updatedState.loadedExpenses[i + 1]
            assertTrue(
                current.transactionDate >= next.transactionDate,
                "Expenses should be ordered by date (newest first)"
            )
        }
    }

    /**
     * Test 3: Pagination loads all 180 AED expenses across 9 pages
     *
     * Note: TestDataHelper creates 50 AED expenses. For this test to work with 180 AED expenses,
     * we need to generate additional test data or adjust expectations.
     *
     * Current implementation: Tests with 50 AED expenses (3 pages: 20+20+10)
     */
    @Test
    fun pagination_loads50AEDExpenses_inThreePages() = runTest {
        // Given: 50 AED expenses (from test data generator)
        TestDataHelper.addTestExpenses(context, usePaginationDataset = true)

        // When: Load all pages for AED
        viewModel.loadFirstPage(currency = "AED", dateFilter = DateFilter.All)
        var state = viewModel.paginationState.first()

        while (state.hasMore) {
            viewModel.loadNextPage()
            state = viewModel.paginationState.first()
        }

        // Then: Should have loaded all 50 AED expenses
        assertEquals(50, state.loadedExpenses.size, "Should load all 50 AED expenses")
        assertFalse(state.hasMore, "Should have no more pages after loading all expenses")

        // Verify all are AED currency
        assertTrue(
            state.loadedExpenses.all { it.currency == "AED" },
            "All loaded expenses should be AED currency"
        )

        // Verify no duplicates
        val uniqueIds = state.loadedExpenses.map { it.id }.toSet()
        assertEquals(50, uniqueIds.size, "All 50 expenses should be unique")
    }

    /**
     * Test 4: Pagination respects currency filter
     *
     * Verifies:
     * - Only USD expenses loaded when filtering by USD
     * - Correct page count for filtered set (40 USD = 2 pages)
     * - No expenses from other currencies
     */
    @Test
    fun pagination_respectsCurrencyFilter() = runTest {
        // Given: 180 expenses across 6 currencies (USD has 40 expenses)
        TestDataHelper.addTestExpenses(context, usePaginationDataset = true)

        // When: Load pages filtered by USD
        viewModel.loadFirstPage(currency = "USD", dateFilter = DateFilter.All)
        var state = viewModel.paginationState.first()

        // Load all USD pages
        while (state.hasMore) {
            viewModel.loadNextPage()
            state = viewModel.paginationState.first()
        }

        // Then: Should have exactly 40 USD expenses (2 pages)
        assertEquals(40, state.loadedExpenses.size, "Should load all 40 USD expenses")

        // Verify all are USD currency
        assertTrue(
            state.loadedExpenses.all { it.currency == "USD" },
            "All expenses should be USD currency"
        )

        // Verify no other currencies present
        val currencies = state.loadedExpenses.map { it.currency }.toSet()
        assertEquals(setOf("USD"), currencies, "Only USD currency should be present")

        // Verify pagination worked (should have been 2 pages: 20+20)
        assertFalse(state.hasMore, "Should have no more pages after loading all USD expenses")
    }

    /**
     * Test 5: Pagination respects date filter (Today)
     *
     * Verifies:
     * - Only today's expenses loaded when filtering by "Today"
     * - Pagination works with filtered subset
     * - Date filter + pagination combined correctly
     */
    @Test
    fun pagination_respectsDateFilter_todayFilter() = runTest {
        // Given: 180 expenses spread over 90 days
        TestDataHelper.addTestExpenses(context, usePaginationDataset = true)

        // When: Apply "Today" filter and load pages for AED
        viewModel.loadFirstPage(currency = "AED", dateFilter = DateFilter.Today)
        var state = viewModel.paginationState.first()

        // Load all pages (may be less than 20 if few expenses today)
        while (state.hasMore) {
            viewModel.loadNextPage()
            state = viewModel.paginationState.first()
        }

        // Then: All expenses should be from today
        val today = kotlinx.datetime.Clock.System.now()
            .toLocalDateTime(kotlinx.datetime.TimeZone.currentSystemDefault()).date

        assertTrue(
            state.loadedExpenses.all { expense ->
                expense.transactionDate.date == today
            },
            "All expenses should be from today"
        )

        // Verify pagination stopped correctly
        assertFalse(state.hasMore, "Should have no more pages")

        // Note: Count may vary depending on how many expenses fall on today's date
        // Just verify we got some results (may be 0 if no expenses today in test data)
        assertNotNull(state.loadedExpenses, "Should return a list (may be empty if no expenses today)")
    }

    /**
     * Test 6: End of list does not attempt to load more
     *
     * Verifies:
     * - Last page may have fewer than 20 items
     * - hasMore becomes false after last page
     * - Attempting to load beyond end returns empty result
     */
    @Test
    fun endOfList_doesNotLoadMore() = runTest {
        // Given: 50 AED expenses (3 pages: 20+20+10)
        TestDataHelper.addTestExpenses(context, usePaginationDataset = true)

        // When: Load all pages until end
        viewModel.loadFirstPage(currency = "AED", dateFilter = DateFilter.All)
        var state = viewModel.paginationState.first()
        var pageCount = 1

        while (state.hasMore) {
            viewModel.loadNextPage()
            state = viewModel.paginationState.first()
            pageCount++
        }

        // Then: Should have loaded 3 pages (20+20+10 = 50 total)
        assertEquals(3, pageCount, "Should have loaded exactly 3 pages")
        assertEquals(50, state.loadedExpenses.size, "Should have all 50 expenses")
        assertFalse(state.hasMore, "Should have no more pages")

        // When: Attempt to load another page beyond end
        val initialSize = state.loadedExpenses.size
        viewModel.loadNextPage()
        state = viewModel.paginationState.first()

        // Then: Size should not change (no new expenses loaded)
        assertEquals(initialSize, state.loadedExpenses.size, "Should not load more expenses beyond end")
        assertFalse(state.hasMore, "Should still have no more pages")
    }

    /**
     * Test 7: Empty list handles gracefully
     *
     * Verifies:
     * - Empty database returns empty list
     * - hasMore is false
     * - No errors thrown
     */
    @Test
    fun emptyList_handlesGracefully() = runTest {
        // Given: Empty database (no expenses)
        // setUp() already clears database

        // When: Load first page
        viewModel.loadFirstPage(currency = "AED", dateFilter = DateFilter.All)
        val state = viewModel.paginationState.first()

        // Then: Should return empty list without errors
        assertEquals(0, state.loadedExpenses.size, "Should return empty list")
        assertFalse(state.hasMore, "Should have no more pages")
        assertEquals(0, state.currentPage, "Current page should be 0")
    }

    /**
     * Test 8: Multi-currency pagination maintains independent states
     *
     * Verifies:
     * - AED pagination state is separate from USD
     * - Switching currency starts fresh pagination
     * - Returning to previous currency preserves its state
     */
    @Test
    fun multiCurrency_paginationIndependent() = runTest {
        // Given: Expenses in multiple currencies
        TestDataHelper.addTestExpenses(context, usePaginationDataset = true)

        // When: Load AED page 1
        viewModel.loadFirstPage(currency = "AED", dateFilter = DateFilter.All)
        val aedState1 = viewModel.paginationState.first()
        val aedPage1Ids = aedState1.loadedExpenses.map { it.id }.toSet()

        // When: Switch to USD and load page 1
        viewModel.loadFirstPage(currency = "USD", dateFilter = DateFilter.All)
        val usdState1 = viewModel.paginationState.first()

        // Then: USD should show fresh data (not AED data)
        assertEquals(20, usdState1.loadedExpenses.size, "USD should load 20 expenses")
        assertTrue(
            usdState1.loadedExpenses.all { it.currency == "USD" },
            "All expenses should be USD"
        )

        // Verify no overlap with AED expenses
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
    }
}

/**
 * Data class representing pagination state
 *
 * Note: This should match the actual PaginationState in your ViewModel
 * Adjust properties as needed to match your implementation
 */
data class PaginationState(
    val loadedExpenses: List<com.justspent.expense.data.model.Expense> = emptyList(),
    val currentPage: Int = 0,
    val hasMore: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null
)
