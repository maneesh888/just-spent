package com.justspent.expense.utils

import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.time.LocalDate
import java.time.LocalDateTime
import kotlinx.datetime.LocalDateTime as KotlinxLocalDateTime

class DateFilterUtilsTest {

    private lateinit var referenceDate: LocalDate

    @Before
    fun setUp() {
        // Set reference date to a known date: January 15, 2025
        referenceDate = LocalDate.of(2025, 1, 15)
    }

    // MARK: - DateFilter Display Name Tests

    @Test
    fun `displayName returns correct values`() {
        assertEquals("All", DateFilter.All.displayName)
        assertEquals("Today", DateFilter.Today.displayName)
        assertEquals("Week", DateFilter.Week.displayName)
        assertEquals("Month", DateFilter.Month.displayName)
        assertEquals("Custom", DateFilter.Custom(LocalDate.now(), LocalDate.now()).displayName)
    }

    @Test
    fun `customRangeDisplayString returns formatted range`() {
        val startDate = LocalDate.of(2025, 1, 15)
        val endDate = LocalDate.of(2025, 1, 20)

        val filter = DateFilter.Custom(startDate, endDate)
        val displayString = filter.customRangeDisplayString

        assertNotNull(displayString)
        assertTrue(displayString!!.contains("Jan 15"))
        assertTrue(displayString.contains("Jan 20"))
    }

    @Test
    fun `customRangeDisplayString is null for non-custom filters`() {
        assertNull(DateFilter.All.customRangeDisplayString)
        assertNull(DateFilter.Today.customRangeDisplayString)
        assertNull(DateFilter.Week.customRangeDisplayString)
        assertNull(DateFilter.Month.customRangeDisplayString)
    }

    // MARK: - DateRange Tests

    @Test
    fun `dateRange for All filter returns null`() {
        val result = DateFilterUtils.dateRange(DateFilter.All, referenceDate)
        assertNull(result)
    }

    @Test
    fun `dateRange for Today filter returns current day`() {
        val result = DateFilterUtils.dateRange(DateFilter.Today, referenceDate)

        assertNotNull(result)
        val (start, end) = result!!

        // Start should be beginning of day (00:00:00)
        assertEquals(2025, start.year)
        assertEquals(1, start.monthValue)
        assertEquals(15, start.dayOfMonth)
        assertEquals(0, start.hour)
        assertEquals(0, start.minute)
        assertEquals(0, start.second)

        // End should be end of day (23:59:59)
        assertEquals(2025, end.year)
        assertEquals(1, end.monthValue)
        assertEquals(15, end.dayOfMonth)
        assertEquals(23, end.hour)
        assertEquals(59, end.minute)
    }

    @Test
    fun `dateRange for Week filter returns last 7 days`() {
        val result = DateFilterUtils.dateRange(DateFilter.Week, referenceDate)

        assertNotNull(result)
        val (start, end) = result!!

        // Start should be 6 days ago (Jan 9)
        assertEquals(2025, start.year)
        assertEquals(1, start.monthValue)
        assertEquals(9, start.dayOfMonth)

        // End should be end of reference day (Jan 15)
        assertEquals(2025, end.year)
        assertEquals(1, end.monthValue)
        assertEquals(15, end.dayOfMonth)
    }

    @Test
    fun `dateRange for Month filter returns current month`() {
        val result = DateFilterUtils.dateRange(DateFilter.Month, referenceDate)

        assertNotNull(result)
        val (start, end) = result!!

        // Start should be beginning of month (Jan 1)
        assertEquals(2025, start.year)
        assertEquals(1, start.monthValue)
        assertEquals(1, start.dayOfMonth)

        // End should be end of month (Jan 31)
        assertEquals(2025, end.year)
        assertEquals(1, end.monthValue)
        assertEquals(31, end.dayOfMonth)
    }

    @Test
    fun `dateRange for Custom filter returns specified range`() {
        val startDate = LocalDate.of(2025, 1, 15)
        val endDate = LocalDate.of(2025, 1, 25)
        val filter = DateFilter.Custom(startDate, endDate)

        val result = DateFilterUtils.dateRange(filter, referenceDate)

        assertNotNull(result)
        val (start, end) = result!!

        // Start should be beginning of start day
        assertEquals(2025, start.year)
        assertEquals(1, start.monthValue)
        assertEquals(15, start.dayOfMonth)
        assertEquals(0, start.hour)

        // End should be end of end day
        assertEquals(2025, end.year)
        assertEquals(1, end.monthValue)
        assertEquals(25, end.dayOfMonth)
    }

    // MARK: - Validation Tests

    @Test
    fun `validateCustomRange with valid range returns valid`() {
        val startDate = referenceDate.minusDays(7)
        val endDate = referenceDate

        val result = DateFilterUtils.validateCustomRange(startDate, endDate, referenceDate)

        assertTrue(result.isValid)
        assertTrue(result.errors.isEmpty())
    }

    @Test
    fun `validateCustomRange with same day range returns valid`() {
        val result = DateFilterUtils.validateCustomRange(referenceDate, referenceDate, referenceDate)

        assertTrue(result.isValid)
        assertTrue(result.errors.isEmpty())
    }

    @Test
    fun `validateCustomRange with end before start returns invalid`() {
        val startDate = referenceDate
        val endDate = referenceDate.minusDays(5)

        val result = DateFilterUtils.validateCustomRange(startDate, endDate, referenceDate)

        assertFalse(result.isValid)
        assertTrue(result.errors.any { it.contains("End date must be on or after start date") })
    }

    @Test
    fun `validateCustomRange with start in future returns invalid`() {
        val startDate = referenceDate.plusDays(5)
        val endDate = referenceDate.plusDays(10)

        val result = DateFilterUtils.validateCustomRange(startDate, endDate, referenceDate)

        assertFalse(result.isValid)
        assertTrue(result.errors.any { it.contains("Start date cannot be in the future") })
    }

    @Test
    fun `validateCustomRange with end in future returns invalid`() {
        val startDate = referenceDate.minusDays(5)
        val endDate = referenceDate.plusDays(5)

        val result = DateFilterUtils.validateCustomRange(startDate, endDate, referenceDate)

        assertFalse(result.isValid)
        assertTrue(result.errors.any { it.contains("End date cannot be in the future") })
    }

    @Test
    fun `validateCustomRange exceeding one year returns invalid`() {
        val startDate = referenceDate.minusDays(400)
        val endDate = referenceDate

        val result = DateFilterUtils.validateCustomRange(startDate, endDate, referenceDate)

        assertFalse(result.isValid)
        assertTrue(result.errors.any { it.contains("Date range cannot exceed 1 year") })
    }

    @Test
    fun `validateCustomRange with multiple errors returns all errors`() {
        val startDate = referenceDate.plusDays(10)
        val endDate = referenceDate.plusDays(5)

        val result = DateFilterUtils.validateCustomRange(startDate, endDate, referenceDate)

        assertFalse(result.isValid)
        assertTrue(result.errors.size >= 2)
    }

    // MARK: - isDateInFilter Tests

    @Test
    fun `isDateInFilter for All filter always returns true`() {
        val pastDate = referenceDate.minusYears(1).atStartOfDay()
        val futureDate = referenceDate.plusYears(1).atStartOfDay()
        val currentDate = referenceDate.atStartOfDay()

        assertTrue(DateFilterUtils.isDateInFilter(pastDate, DateFilter.All, referenceDate))
        assertTrue(DateFilterUtils.isDateInFilter(currentDate, DateFilter.All, referenceDate))
        assertTrue(DateFilterUtils.isDateInFilter(futureDate, DateFilter.All, referenceDate))
    }

    @Test
    fun `isDateInFilter for Today filter returns true for today`() {
        val todayMorning = referenceDate.atStartOfDay()
        val todayEvening = referenceDate.atTime(23, 59, 0)

        assertTrue(DateFilterUtils.isDateInFilter(todayMorning, DateFilter.Today, referenceDate))
        assertTrue(DateFilterUtils.isDateInFilter(todayEvening, DateFilter.Today, referenceDate))
    }

    @Test
    fun `isDateInFilter for Today filter returns false for yesterday`() {
        val yesterday = referenceDate.minusDays(1).atStartOfDay()

        assertFalse(DateFilterUtils.isDateInFilter(yesterday, DateFilter.Today, referenceDate))
    }

    @Test
    fun `isDateInFilter for Week filter returns true for last 7 days`() {
        val sixDaysAgo = referenceDate.minusDays(6).atStartOfDay()
        val threeDaysAgo = referenceDate.minusDays(3).atStartOfDay()
        val today = referenceDate.atStartOfDay()

        assertTrue(DateFilterUtils.isDateInFilter(sixDaysAgo, DateFilter.Week, referenceDate))
        assertTrue(DateFilterUtils.isDateInFilter(threeDaysAgo, DateFilter.Week, referenceDate))
        assertTrue(DateFilterUtils.isDateInFilter(today, DateFilter.Week, referenceDate))
    }

    @Test
    fun `isDateInFilter for Week filter returns false for older dates`() {
        val eightDaysAgo = referenceDate.minusDays(8).atStartOfDay()

        assertFalse(DateFilterUtils.isDateInFilter(eightDaysAgo, DateFilter.Week, referenceDate))
    }

    @Test
    fun `isDateInFilter for Month filter returns true for current month`() {
        val firstOfMonth = LocalDate.of(2025, 1, 1).atStartOfDay()
        val lastOfMonth = LocalDate.of(2025, 1, 31).atStartOfDay()
        val midMonth = referenceDate.atStartOfDay()

        assertTrue(DateFilterUtils.isDateInFilter(firstOfMonth, DateFilter.Month, referenceDate))
        assertTrue(DateFilterUtils.isDateInFilter(lastOfMonth, DateFilter.Month, referenceDate))
        assertTrue(DateFilterUtils.isDateInFilter(midMonth, DateFilter.Month, referenceDate))
    }

    @Test
    fun `isDateInFilter for Month filter returns false for previous month`() {
        val lastMonth = LocalDate.of(2024, 12, 31).atStartOfDay()

        assertFalse(DateFilterUtils.isDateInFilter(lastMonth, DateFilter.Month, referenceDate))
    }

    @Test
    fun `isDateInFilter for Custom filter returns true for dates in range`() {
        val startDate = referenceDate.minusDays(10) // Jan 5
        val endDate = referenceDate.minusDays(5) // Jan 10
        val filter = DateFilter.Custom(startDate, endDate)

        val dateInRange = referenceDate.minusDays(7).atStartOfDay() // Jan 8

        assertTrue(DateFilterUtils.isDateInFilter(dateInRange, filter, referenceDate))
        assertTrue(DateFilterUtils.isDateInFilter(startDate.atStartOfDay(), filter, referenceDate))
        assertTrue(DateFilterUtils.isDateInFilter(endDate.atStartOfDay(), filter, referenceDate))
    }

    @Test
    fun `isDateInFilter for Custom filter returns false for dates out of range`() {
        val startDate = referenceDate.minusDays(10) // Jan 5
        val endDate = referenceDate.minusDays(5) // Jan 10
        val filter = DateFilter.Custom(startDate, endDate)

        val beforeRange = referenceDate.minusDays(15).atStartOfDay() // Dec 31
        val afterRange = referenceDate.atStartOfDay() // Jan 15

        assertFalse(DateFilterUtils.isDateInFilter(beforeRange, filter, referenceDate))
        assertFalse(DateFilterUtils.isDateInFilter(afterRange, filter, referenceDate))
    }

    // MARK: - Edge Case Tests

    @Test
    fun `dateRange for Month filter handles February`() {
        // February 15, 2025
        val febDate = LocalDate.of(2025, 2, 15)

        val result = DateFilterUtils.dateRange(DateFilter.Month, febDate)

        assertNotNull(result)
        val (_, end) = result!!
        assertEquals(2, end.monthValue)
        assertEquals(28, end.dayOfMonth) // 2025 is not a leap year
    }

    @Test
    fun `dateRange for Month filter handles leap year`() {
        // February 15, 2024 (leap year)
        val febDate = LocalDate.of(2024, 2, 15)

        val result = DateFilterUtils.dateRange(DateFilter.Month, febDate)

        assertNotNull(result)
        val (_, end) = result!!
        assertEquals(2, end.monthValue)
        assertEquals(29, end.dayOfMonth) // Leap year
    }

    @Test
    fun `dateRange for Week filter crosses month boundary`() {
        // January 3, 2025
        val earlyJan = LocalDate.of(2025, 1, 3)

        val result = DateFilterUtils.dateRange(DateFilter.Week, earlyJan)

        assertNotNull(result)
        val (start, _) = result!!
        assertEquals(2024, start.year)
        assertEquals(12, start.monthValue)
        assertEquals(28, start.dayOfMonth) // Dec 28, 2024
    }

    // MARK: - kotlinx.datetime.LocalDateTime Tests

    @Test
    fun `isDateInFilter with kotlinx LocalDateTime for All filter always returns true`() {
        val pastDate = KotlinxLocalDateTime(2024, 1, 15, 0, 0, 0)
        val futureDate = KotlinxLocalDateTime(2026, 1, 15, 0, 0, 0)
        val currentDate = KotlinxLocalDateTime(2025, 1, 15, 12, 0, 0)

        assertTrue(DateFilterUtils.isDateInFilter(pastDate, DateFilter.All, referenceDate))
        assertTrue(DateFilterUtils.isDateInFilter(currentDate, DateFilter.All, referenceDate))
        assertTrue(DateFilterUtils.isDateInFilter(futureDate, DateFilter.All, referenceDate))
    }

    @Test
    fun `isDateInFilter with kotlinx LocalDateTime for Today filter returns true for today`() {
        val todayMorning = KotlinxLocalDateTime(2025, 1, 15, 0, 0, 0)
        val todayEvening = KotlinxLocalDateTime(2025, 1, 15, 23, 59, 0)

        assertTrue(DateFilterUtils.isDateInFilter(todayMorning, DateFilter.Today, referenceDate))
        assertTrue(DateFilterUtils.isDateInFilter(todayEvening, DateFilter.Today, referenceDate))
    }

    @Test
    fun `isDateInFilter with kotlinx LocalDateTime for Today filter returns false for yesterday`() {
        val yesterday = KotlinxLocalDateTime(2025, 1, 14, 12, 0, 0)

        assertFalse(DateFilterUtils.isDateInFilter(yesterday, DateFilter.Today, referenceDate))
    }

    @Test
    fun `isDateInFilter with kotlinx LocalDateTime for Week filter returns true for last 7 days`() {
        val sixDaysAgo = KotlinxLocalDateTime(2025, 1, 9, 0, 0, 0)
        val threeDaysAgo = KotlinxLocalDateTime(2025, 1, 12, 12, 0, 0)
        val today = KotlinxLocalDateTime(2025, 1, 15, 18, 30, 0)

        assertTrue(DateFilterUtils.isDateInFilter(sixDaysAgo, DateFilter.Week, referenceDate))
        assertTrue(DateFilterUtils.isDateInFilter(threeDaysAgo, DateFilter.Week, referenceDate))
        assertTrue(DateFilterUtils.isDateInFilter(today, DateFilter.Week, referenceDate))
    }

    @Test
    fun `isDateInFilter with kotlinx LocalDateTime for Week filter returns false for older dates`() {
        val eightDaysAgo = KotlinxLocalDateTime(2025, 1, 7, 12, 0, 0)

        assertFalse(DateFilterUtils.isDateInFilter(eightDaysAgo, DateFilter.Week, referenceDate))
    }

    @Test
    fun `isDateInFilter with kotlinx LocalDateTime for Month filter returns true for current month`() {
        val firstOfMonth = KotlinxLocalDateTime(2025, 1, 1, 0, 0, 0)
        val lastOfMonth = KotlinxLocalDateTime(2025, 1, 31, 23, 59, 59)
        val midMonth = KotlinxLocalDateTime(2025, 1, 15, 12, 0, 0)

        assertTrue(DateFilterUtils.isDateInFilter(firstOfMonth, DateFilter.Month, referenceDate))
        assertTrue(DateFilterUtils.isDateInFilter(lastOfMonth, DateFilter.Month, referenceDate))
        assertTrue(DateFilterUtils.isDateInFilter(midMonth, DateFilter.Month, referenceDate))
    }

    @Test
    fun `isDateInFilter with kotlinx LocalDateTime for Month filter returns false for previous month`() {
        val lastMonth = KotlinxLocalDateTime(2024, 12, 31, 12, 0, 0)

        assertFalse(DateFilterUtils.isDateInFilter(lastMonth, DateFilter.Month, referenceDate))
    }

    @Test
    fun `isDateInFilter with kotlinx LocalDateTime for Custom filter returns true for dates in range`() {
        val startDate = referenceDate.minusDays(10) // Jan 5
        val endDate = referenceDate.minusDays(5) // Jan 10
        val filter = DateFilter.Custom(startDate, endDate)

        val dateInRange = KotlinxLocalDateTime(2025, 1, 8, 12, 0, 0) // Jan 8

        assertTrue(DateFilterUtils.isDateInFilter(dateInRange, filter, referenceDate))
    }

    @Test
    fun `isDateInFilter with kotlinx LocalDateTime for Custom filter returns false for dates out of range`() {
        val startDate = referenceDate.minusDays(10) // Jan 5
        val endDate = referenceDate.minusDays(5) // Jan 10
        val filter = DateFilter.Custom(startDate, endDate)

        val beforeRange = KotlinxLocalDateTime(2024, 12, 31, 12, 0, 0) // Dec 31
        val afterRange = KotlinxLocalDateTime(2025, 1, 15, 12, 0, 0) // Jan 15

        assertFalse(DateFilterUtils.isDateInFilter(beforeRange, filter, referenceDate))
        assertFalse(DateFilterUtils.isDateInFilter(afterRange, filter, referenceDate))
    }

    @Test
    fun `isDateInFilter with kotlinx LocalDateTime preserves nanoseconds during conversion`() {
        // Test that nanoseconds are properly converted
        val dateWithNanos = KotlinxLocalDateTime(2025, 1, 15, 12, 30, 45, 123456789)

        // Should not throw and should return true for Today filter
        assertTrue(DateFilterUtils.isDateInFilter(dateWithNanos, DateFilter.Today, referenceDate))
    }

    // MARK: - DateRangeValidationResult Tests

    @Test
    fun `DateRangeValidationResult firstError returns first error or null`() {
        val validResult = DateRangeValidationResult(isValid = true, errors = emptyList())
        assertNull(validResult.firstError)

        val invalidResult = DateRangeValidationResult(
            isValid = false,
            errors = listOf("First error", "Second error")
        )
        assertEquals("First error", invalidResult.firstError)
    }
}
