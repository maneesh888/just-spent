package com.justspent.expense.ui.components

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import com.justspent.expense.utils.DateFilter
import org.junit.Rule
import org.junit.Test
import java.time.LocalDate

/**
 * UI tests for the FilterStrip component
 */
class FilterStripUITest {

    @get:Rule
    val composeTestRule = createComposeRule()

    // MARK: - Display Tests

    @Test
    fun filterStrip_displaysAllPresetFilters() {
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.All,
                onFilterSelected = {}
            )
        }

        // Verify all preset filter chips are displayed
        composeTestRule.onNodeWithTag("filter_chip_all").assertIsDisplayed()
        composeTestRule.onNodeWithTag("filter_chip_today").assertIsDisplayed()
        composeTestRule.onNodeWithTag("filter_chip_week").assertIsDisplayed()
        composeTestRule.onNodeWithTag("filter_chip_month").assertIsDisplayed()
        composeTestRule.onNodeWithTag("filter_chip_custom").assertIsDisplayed()
    }

    @Test
    fun filterStrip_hasCorrectTestTag() {
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.All,
                onFilterSelected = {}
            )
        }

        composeTestRule.onNodeWithTag("filter_strip").assertIsDisplayed()
    }

    // MARK: - Selection Tests

    @Test
    fun filterStrip_allFilterSelectedByDefault() {
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.All,
                onFilterSelected = {}
            )
        }

        composeTestRule.onNodeWithTag("filter_chip_all").assertIsSelected()
        composeTestRule.onNodeWithTag("filter_chip_today").assertIsNotSelected()
        composeTestRule.onNodeWithTag("filter_chip_week").assertIsNotSelected()
        composeTestRule.onNodeWithTag("filter_chip_month").assertIsNotSelected()
        composeTestRule.onNodeWithTag("filter_chip_custom").assertIsNotSelected()
    }

    @Test
    fun filterStrip_todayFilterCanBeSelected() {
        var selectedFilter by mutableStateOf<DateFilter>(DateFilter.All)

        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = selectedFilter,
                onFilterSelected = { selectedFilter = it }
            )
        }

        // Click on Today filter
        composeTestRule.onNodeWithTag("filter_chip_today").performClick()

        // Verify selection changed
        assert(selectedFilter == DateFilter.Today) { "Expected Today filter to be selected" }
    }

    @Test
    fun filterStrip_weekFilterCanBeSelected() {
        var selectedFilter by mutableStateOf<DateFilter>(DateFilter.All)

        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = selectedFilter,
                onFilterSelected = { selectedFilter = it }
            )
        }

        composeTestRule.onNodeWithTag("filter_chip_week").performClick()

        assert(selectedFilter == DateFilter.Week) { "Expected Week filter to be selected" }
    }

    @Test
    fun filterStrip_monthFilterCanBeSelected() {
        var selectedFilter by mutableStateOf<DateFilter>(DateFilter.All)

        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = selectedFilter,
                onFilterSelected = { selectedFilter = it }
            )
        }

        composeTestRule.onNodeWithTag("filter_chip_month").performClick()

        assert(selectedFilter == DateFilter.Month) { "Expected Month filter to be selected" }
    }

    @Test
    fun filterStrip_canSwitchBetweenFilters() {
        var selectedFilter by mutableStateOf<DateFilter>(DateFilter.All)

        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = selectedFilter,
                onFilterSelected = { selectedFilter = it }
            )
        }

        // Select Today
        composeTestRule.onNodeWithTag("filter_chip_today").performClick()
        assert(selectedFilter == DateFilter.Today)

        // Switch to Week
        composeTestRule.onNodeWithTag("filter_chip_week").performClick()
        assert(selectedFilter == DateFilter.Week)

        // Switch back to All
        composeTestRule.onNodeWithTag("filter_chip_all").performClick()
        assert(selectedFilter == DateFilter.All)
    }

    // MARK: - Visual State Tests

    @Test
    fun filterStrip_showsCorrectSelectionState_whenTodaySelected() {
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.Today,
                onFilterSelected = {}
            )
        }

        composeTestRule.onNodeWithTag("filter_chip_all").assertIsNotSelected()
        composeTestRule.onNodeWithTag("filter_chip_today").assertIsSelected()
        composeTestRule.onNodeWithTag("filter_chip_week").assertIsNotSelected()
        composeTestRule.onNodeWithTag("filter_chip_month").assertIsNotSelected()
    }

    @Test
    fun filterStrip_showsCorrectSelectionState_whenWeekSelected() {
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.Week,
                onFilterSelected = {}
            )
        }

        composeTestRule.onNodeWithTag("filter_chip_all").assertIsNotSelected()
        composeTestRule.onNodeWithTag("filter_chip_today").assertIsNotSelected()
        composeTestRule.onNodeWithTag("filter_chip_week").assertIsSelected()
        composeTestRule.onNodeWithTag("filter_chip_month").assertIsNotSelected()
    }

    @Test
    fun filterStrip_showsCorrectSelectionState_whenMonthSelected() {
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.Month,
                onFilterSelected = {}
            )
        }

        composeTestRule.onNodeWithTag("filter_chip_all").assertIsNotSelected()
        composeTestRule.onNodeWithTag("filter_chip_today").assertIsNotSelected()
        composeTestRule.onNodeWithTag("filter_chip_week").assertIsNotSelected()
        composeTestRule.onNodeWithTag("filter_chip_month").assertIsSelected()
    }

    @Test
    fun filterStrip_showsCorrectSelectionState_whenCustomSelected() {
        val customFilter = DateFilter.Custom(
            start = LocalDate.now().minusDays(7),
            end = LocalDate.now()
        )

        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = customFilter,
                onFilterSelected = {}
            )
        }

        composeTestRule.onNodeWithTag("filter_chip_all").assertIsNotSelected()
        composeTestRule.onNodeWithTag("filter_chip_custom").assertIsSelected()
    }

    // MARK: - Custom Dialog Tests

    @Test
    fun filterStrip_customChipClick_opensDialog() {
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.All,
                onFilterSelected = {}
            )
        }

        // Click on Custom filter
        composeTestRule.onNodeWithTag("filter_chip_custom").performClick()

        // Verify dialog appears
        composeTestRule.onNodeWithText("Custom Date Range").assertIsDisplayed()
        composeTestRule.onNodeWithTag("custom_start_date_button").assertIsDisplayed()
        composeTestRule.onNodeWithTag("custom_end_date_button").assertIsDisplayed()
    }

    @Test
    fun filterStrip_customDialog_canBeDismissed() {
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.All,
                onFilterSelected = {}
            )
        }

        // Open dialog
        composeTestRule.onNodeWithTag("filter_chip_custom").performClick()
        composeTestRule.onNodeWithText("Custom Date Range").assertIsDisplayed()

        // Click Cancel
        composeTestRule.onNodeWithTag("cancel_custom_filter_button").performClick()

        // Verify dialog is dismissed
        composeTestRule.onNodeWithText("Custom Date Range").assertDoesNotExist()
    }

    @Test
    fun filterStrip_customDialog_applyButton_appliesSelection() {
        var selectedFilter by mutableStateOf<DateFilter>(DateFilter.All)

        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = selectedFilter,
                onFilterSelected = { selectedFilter = it }
            )
        }

        // Open dialog
        composeTestRule.onNodeWithTag("filter_chip_custom").performClick()

        // Click Apply (with default dates)
        composeTestRule.onNodeWithTag("apply_custom_filter_button").performClick()

        // Verify custom filter was applied
        assert(selectedFilter is DateFilter.Custom) { "Expected Custom filter to be selected" }
    }

    // MARK: - Accessibility Tests

    @Test
    fun filterStrip_hasCorrectContentDescriptions() {
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.All,
                onFilterSelected = {}
            )
        }

        composeTestRule.onNodeWithContentDescription("All filter").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Today filter").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Week filter").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Month filter").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Custom date range filter").assertIsDisplayed()
    }

    // MARK: - Custom Label Display Tests

    @Test
    fun filterStrip_customFilter_showsDateRangeInLabel() {
        val startDate = LocalDate.of(2025, 1, 15)
        val endDate = LocalDate.of(2025, 1, 20)
        val customFilter = DateFilter.Custom(startDate, endDate)

        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = customFilter,
                onFilterSelected = {}
            )
        }

        // The custom chip should show the date range
        composeTestRule.onNodeWithTag("filter_chip_custom")
            .assertTextContains("Jan 15", substring = true)
    }
}
