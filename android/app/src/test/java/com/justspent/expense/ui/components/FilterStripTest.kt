package com.justspent.expense.ui.components

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import com.justspent.expense.utils.DateFilter
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.time.LocalDate

/**
 * Unit tests for FilterStrip composable using Robolectric.
 * These tests run on the JVM and contribute to JaCoCo code coverage.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33], manifest = Config.NONE)
class FilterStripTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    // MARK: - Basic Rendering Tests

    @Test
    fun filterStrip_rendersAllPresetFilters() {
        // Given
        var selectedFilter: DateFilter = DateFilter.All

        // When
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = selectedFilter,
                onFilterSelected = { selectedFilter = it }
            )
        }

        // Then - All preset filters should be visible
        composeTestRule.onNodeWithTag("filter_chip_all").assertIsDisplayed()
        composeTestRule.onNodeWithTag("filter_chip_today").assertIsDisplayed()
        composeTestRule.onNodeWithTag("filter_chip_week").assertIsDisplayed()
        composeTestRule.onNodeWithTag("filter_chip_month").assertIsDisplayed()
        composeTestRule.onNodeWithTag("filter_chip_custom").assertIsDisplayed()
    }

    @Test
    fun filterStrip_showsFilterStripTestTag() {
        // Given/When
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.All,
                onFilterSelected = {}
            )
        }

        // Then
        composeTestRule.onNodeWithTag("filter_strip").assertIsDisplayed()
    }

    // MARK: - Selection State Tests

    @Test
    fun filterStrip_allFilter_isSelectedByDefault() {
        // Given/When
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.All,
                onFilterSelected = {}
            )
        }

        // Then - All filter should be selected
        composeTestRule.onNodeWithTag("filter_chip_all").assertIsSelected()
    }

    @Test
    fun filterStrip_todayFilter_isSelectedWhenPassed() {
        // Given/When
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.Today,
                onFilterSelected = {}
            )
        }

        // Then - Today filter should be selected
        composeTestRule.onNodeWithTag("filter_chip_today").assertIsSelected()
        composeTestRule.onNodeWithTag("filter_chip_all").assertIsNotSelected()
    }

    @Test
    fun filterStrip_weekFilter_isSelectedWhenPassed() {
        // Given/When
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.Week,
                onFilterSelected = {}
            )
        }

        // Then - Week filter should be selected
        composeTestRule.onNodeWithTag("filter_chip_week").assertIsSelected()
    }

    @Test
    fun filterStrip_monthFilter_isSelectedWhenPassed() {
        // Given/When
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.Month,
                onFilterSelected = {}
            )
        }

        // Then - Month filter should be selected
        composeTestRule.onNodeWithTag("filter_chip_month").assertIsSelected()
    }

    @Test
    fun filterStrip_customFilter_isSelectedWhenPassed() {
        // Given
        val customFilter = DateFilter.Custom(
            start = LocalDate.of(2025, 1, 1),
            end = LocalDate.of(2025, 1, 15)
        )

        // When
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = customFilter,
                onFilterSelected = {}
            )
        }

        // Then - Custom filter should be selected
        composeTestRule.onNodeWithTag("filter_chip_custom").assertIsSelected()
    }

    // MARK: - Click Interaction Tests

    @Test
    fun filterStrip_clickingTodayFilter_callsOnFilterSelected() {
        // Given
        var selectedFilter: DateFilter = DateFilter.All

        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = selectedFilter,
                onFilterSelected = { selectedFilter = it }
            )
        }

        // When
        composeTestRule.onNodeWithTag("filter_chip_today").performClick()

        // Then
        assert(selectedFilter == DateFilter.Today) { "Expected Today filter to be selected" }
    }

    @Test
    fun filterStrip_clickingWeekFilter_callsOnFilterSelected() {
        // Given
        var selectedFilter: DateFilter = DateFilter.All

        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = selectedFilter,
                onFilterSelected = { selectedFilter = it }
            )
        }

        // When
        composeTestRule.onNodeWithTag("filter_chip_week").performClick()

        // Then
        assert(selectedFilter == DateFilter.Week) { "Expected Week filter to be selected" }
    }

    @Test
    fun filterStrip_clickingMonthFilter_callsOnFilterSelected() {
        // Given
        var selectedFilter: DateFilter = DateFilter.All

        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = selectedFilter,
                onFilterSelected = { selectedFilter = it }
            )
        }

        // When
        composeTestRule.onNodeWithTag("filter_chip_month").performClick()

        // Then
        assert(selectedFilter == DateFilter.Month) { "Expected Month filter to be selected" }
    }

    @Test
    fun filterStrip_clickingAllFilter_callsOnFilterSelected() {
        // Given
        var selectedFilter: DateFilter = DateFilter.Today

        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = selectedFilter,
                onFilterSelected = { selectedFilter = it }
            )
        }

        // When
        composeTestRule.onNodeWithTag("filter_chip_all").performClick()

        // Then
        assert(selectedFilter == DateFilter.All) { "Expected All filter to be selected" }
    }

    // MARK: - Custom Filter Display Tests

    @Test
    fun filterStrip_customFilter_showsDateRangeInLabel() {
        // Given
        val customFilter = DateFilter.Custom(
            start = LocalDate.of(2025, 1, 15),
            end = LocalDate.of(2025, 1, 20)
        )

        // When
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = customFilter,
                onFilterSelected = {}
            )
        }

        // Then - Custom chip should show date range
        composeTestRule.onNodeWithText("Jan 15 - Jan 20", substring = true).assertIsDisplayed()
    }

    @Test
    fun filterStrip_nonCustomFilter_showsCustomLabel() {
        // Given/When
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.All,
                onFilterSelected = {}
            )
        }

        // Then - Custom chip should show "Custom" text
        composeTestRule.onNodeWithText("Custom").assertIsDisplayed()
    }

    // MARK: - Accessibility Tests

    @Test
    fun filterStrip_allFilterHasContentDescription() {
        // Given/When
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.All,
                onFilterSelected = {}
            )
        }

        // Then
        composeTestRule.onNodeWithContentDescription("All filter").assertIsDisplayed()
    }

    @Test
    fun filterStrip_todayFilterHasContentDescription() {
        // Given/When
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.All,
                onFilterSelected = {}
            )
        }

        // Then
        composeTestRule.onNodeWithContentDescription("Today filter").assertIsDisplayed()
    }

    @Test
    fun filterStrip_customFilterHasContentDescription() {
        // Given/When
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.All,
                onFilterSelected = {}
            )
        }

        // Then
        composeTestRule.onNodeWithContentDescription("Custom date range filter").assertIsDisplayed()
    }

    // MARK: - Custom Dialog Tests

    @Test
    fun filterStrip_clickingCustomFilter_opensDialog() {
        // Given
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.All,
                onFilterSelected = {}
            )
        }

        // When
        composeTestRule.onNodeWithTag("filter_chip_custom").performClick()

        // Then - Dialog elements should be visible
        composeTestRule.onNodeWithText("Custom Date Range").assertIsDisplayed()
        composeTestRule.onNodeWithText("Start Date").assertIsDisplayed()
        composeTestRule.onNodeWithText("End Date").assertIsDisplayed()
    }

    @Test
    fun filterStrip_customDialog_hasCancelButton() {
        // Given
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.All,
                onFilterSelected = {}
            )
        }

        // When
        composeTestRule.onNodeWithTag("filter_chip_custom").performClick()

        // Then
        composeTestRule.onNodeWithTag("cancel_custom_filter_button").assertIsDisplayed()
    }

    @Test
    fun filterStrip_customDialog_hasApplyButton() {
        // Given
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.All,
                onFilterSelected = {}
            )
        }

        // When
        composeTestRule.onNodeWithTag("filter_chip_custom").performClick()

        // Then
        composeTestRule.onNodeWithTag("apply_custom_filter_button").assertIsDisplayed()
    }

    @Test
    fun filterStrip_customDialog_cancelDismissesDialog() {
        // Given
        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = DateFilter.All,
                onFilterSelected = {}
            )
        }
        composeTestRule.onNodeWithTag("filter_chip_custom").performClick()

        // When
        composeTestRule.onNodeWithTag("cancel_custom_filter_button").performClick()

        // Then - Dialog should be dismissed
        composeTestRule.onNodeWithText("Custom Date Range").assertDoesNotExist()
    }

    @Test
    fun filterStrip_customDialog_applyWithValidRange_callsCallback() {
        // Given
        var selectedFilter: DateFilter = DateFilter.All

        composeTestRule.setContent {
            FilterStrip(
                selectedFilter = selectedFilter,
                onFilterSelected = { selectedFilter = it }
            )
        }
        composeTestRule.onNodeWithTag("filter_chip_custom").performClick()

        // When - Apply default valid range
        composeTestRule.onNodeWithTag("apply_custom_filter_button").performClick()

        // Then - Filter should be updated to Custom
        assert(selectedFilter is DateFilter.Custom) { "Expected Custom filter to be selected" }
    }
}
