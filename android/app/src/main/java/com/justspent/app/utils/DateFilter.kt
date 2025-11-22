package com.justspent.app.utils

import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.time.temporal.TemporalAdjusters
import kotlinx.datetime.LocalDateTime as KotlinxLocalDateTime

/**
 * Represents the available date filter options for expense lists
 */
sealed class DateFilter {
    /** No filter - show all expenses */
    data object All : DateFilter()

    /** Show only today's expenses */
    data object Today : DateFilter()

    /** Show expenses from the last 7 days (rolling) */
    data object Week : DateFilter()

    /** Show expenses from the current calendar month */
    data object Month : DateFilter()

    /** Show expenses within a custom date range */
    data class Custom(val start: LocalDate, val end: LocalDate) : DateFilter()

    /**
     * Display name for the filter
     */
    val displayName: String
        get() = when (this) {
            is All -> "All"
            is Today -> "Today"
            is Week -> "Week"
            is Month -> "Month"
            is Custom -> "Custom"
        }

    /**
     * Returns the formatted date range string for custom filter
     */
    val customRangeDisplayString: String?
        get() = when (this) {
            is Custom -> {
                val formatter = DateTimeFormatter.ofPattern("MMM d")
                "${start.format(formatter)} - ${end.format(formatter)}"
            }
            else -> null
        }
}

/**
 * Utility class for date filter calculations
 */
object DateFilterUtils {

    /**
     * Returns the date range for a given filter
     *
     * @param filter The date filter to get range for
     * @param referenceDate The reference date (defaults to today)
     * @return A pair of (startDateTime, endDateTime) or null for All filter
     */
    fun dateRange(
        filter: DateFilter,
        referenceDate: LocalDate = LocalDate.now()
    ): Pair<LocalDateTime, LocalDateTime>? {
        return when (filter) {
            is DateFilter.All -> null

            is DateFilter.Today -> {
                val startOfDay = referenceDate.atStartOfDay()
                val endOfDay = referenceDate.atTime(LocalTime.MAX)
                startOfDay to endOfDay
            }

            is DateFilter.Week -> {
                // Last 7 days (rolling)
                val endOfDay = referenceDate.atTime(LocalTime.MAX)
                val startOfWeek = referenceDate.minusDays(6).atStartOfDay()
                startOfWeek to endOfDay
            }

            is DateFilter.Month -> {
                // Current calendar month
                val startOfMonth = referenceDate.with(TemporalAdjusters.firstDayOfMonth()).atStartOfDay()
                val endOfMonth = referenceDate.with(TemporalAdjusters.lastDayOfMonth()).atTime(LocalTime.MAX)
                startOfMonth to endOfMonth
            }

            is DateFilter.Custom -> {
                val startOfDay = filter.start.atStartOfDay()
                val endOfDay = filter.end.atTime(LocalTime.MAX)
                startOfDay to endOfDay
            }
        }
    }

    /**
     * Validates a custom date range
     *
     * @param startDate The start date
     * @param endDate The end date
     * @param referenceDate The reference date for "future" check (defaults to today)
     * @return A validation result with any error messages
     */
    fun validateCustomRange(
        startDate: LocalDate,
        endDate: LocalDate,
        referenceDate: LocalDate = LocalDate.now()
    ): DateRangeValidationResult {
        val errors = mutableListOf<String>()

        // Check if end date is before start date
        if (endDate.isBefore(startDate)) {
            errors.add("End date must be on or after start date")
        }

        // Check if dates are in the future
        val tomorrow = referenceDate.plusDays(1)
        if (startDate.isAfter(referenceDate) || startDate.isEqual(tomorrow)) {
            errors.add("Start date cannot be in the future")
        }
        if (endDate.isAfter(referenceDate) || endDate.isEqual(tomorrow)) {
            errors.add("End date cannot be in the future")
        }

        // Check if range is too large (more than 1 year)
        val daysDifference = java.time.temporal.ChronoUnit.DAYS.between(startDate, endDate)
        if (daysDifference > 365) {
            errors.add("Date range cannot exceed 1 year")
        }

        return DateRangeValidationResult(
            isValid = errors.isEmpty(),
            errors = errors
        )
    }

    /**
     * Checks if a date falls within the filter's range
     *
     * @param dateTime The date/time to check (java.time.LocalDateTime)
     * @param filter The filter to check against
     * @param referenceDate The reference date (defaults to today)
     * @return True if the date is within the filter's range
     */
    fun isDateInFilter(
        dateTime: LocalDateTime,
        filter: DateFilter,
        referenceDate: LocalDate = LocalDate.now()
    ): Boolean {
        val range = dateRange(filter, referenceDate) ?: return true // All filter includes all dates

        return !dateTime.isBefore(range.first) && !dateTime.isAfter(range.second)
    }

    /**
     * Checks if a date falls within the filter's range (kotlinx.datetime version)
     *
     * @param dateTime The date/time to check (kotlinx.datetime.LocalDateTime)
     * @param filter The filter to check against
     * @param referenceDate The reference date (defaults to today)
     * @return True if the date is within the filter's range
     */
    fun isDateInFilter(
        dateTime: KotlinxLocalDateTime,
        filter: DateFilter,
        referenceDate: LocalDate = LocalDate.now()
    ): Boolean {
        // Convert kotlinx.datetime.LocalDateTime to java.time.LocalDateTime
        val javaDateTime = LocalDateTime.of(
            dateTime.year,
            dateTime.monthNumber,
            dateTime.dayOfMonth,
            dateTime.hour,
            dateTime.minute,
            dateTime.second,
            dateTime.nanosecond
        )
        return isDateInFilter(javaDateTime, filter, referenceDate)
    }
}

/**
 * Result of date range validation
 */
data class DateRangeValidationResult(
    /** Whether the range is valid */
    val isValid: Boolean,
    /** List of validation errors (empty if valid) */
    val errors: List<String>
) {
    /** Convenience property for first error */
    val firstError: String?
        get() = errors.firstOrNull()
}
