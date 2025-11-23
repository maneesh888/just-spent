//
//  DateFilter.swift
//  JustSpent
//
//  Created by Claude Code on 2025.
//

import Foundation

/// Represents the available date filter options for expense lists
enum DateFilter: Equatable, Hashable {
    /// No filter - show all expenses
    case all
    /// Show only today's expenses
    case today
    /// Show expenses from the last 7 days (rolling)
    case week
    /// Show expenses from the current calendar month
    case month
    /// Show expenses within a custom date range
    case custom(start: Date, end: Date)

    /// Display name for the filter
    var displayName: String {
        switch self {
        case .all:
            return "All"
        case .today:
            return "Today"
        case .week:
            return "Week"
        case .month:
            return "Month"
        case .custom:
            return "Custom"
        }
    }

    /// Accessibility label for VoiceOver
    var accessibilityLabel: String {
        switch self {
        case .all:
            return "Show all expenses"
        case .today:
            return "Show today's expenses"
        case .week:
            return "Show this week's expenses"
        case .month:
            return "Show this month's expenses"
        case .custom(let start, let end):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Custom range from \(formatter.string(from: start)) to \(formatter.string(from: end))"
        }
    }

    /// Returns the formatted date range string for custom filter
    var customRangeDisplayString: String? {
        guard case .custom(let start, let end) = self else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    // MARK: - Equatable

    static func == (lhs: DateFilter, rhs: DateFilter) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all), (.today, .today), (.week, .week), (.month, .month):
            return true
        case (.custom(let lStart, let lEnd), .custom(let rStart, let rEnd)):
            return Calendar.current.isDate(lStart, inSameDayAs: rStart) &&
                   Calendar.current.isDate(lEnd, inSameDayAs: rEnd)
        default:
            return false
        }
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        switch self {
        case .all:
            hasher.combine(0)
        case .today:
            hasher.combine(1)
        case .week:
            hasher.combine(2)
        case .month:
            hasher.combine(3)
        case .custom(let start, let end):
            hasher.combine(4)
            hasher.combine(start)
            hasher.combine(end)
        }
    }
}

/// Utility class for date filter calculations
class DateFilterUtils {

    /// Shared instance
    static let shared = DateFilterUtils()

    /// Calendar for date calculations
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Returns the date range for a given filter
    /// - Parameters:
    ///   - filter: The date filter to get range for
    ///   - referenceDate: The reference date (defaults to now)
    /// - Returns: A tuple of (startDate, endDate) or nil for .all filter
    func dateRange(for filter: DateFilter, referenceDate: Date = Date()) -> (start: Date, end: Date)? {
        switch filter {
        case .all:
            return nil

        case .today:
            let startOfDay = calendar.startOfDay(for: referenceDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
            return (startOfDay, endOfDay)

        case .week:
            // Last 7 days (rolling)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: referenceDate))!.addingTimeInterval(-1)
            let startOfWeek = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: referenceDate))!
            return (startOfWeek, endOfDay)

        case .month:
            // Current calendar month
            let components = calendar.dateComponents([.year, .month], from: referenceDate)
            let startOfMonth = calendar.date(from: components)!
            var endComponents = DateComponents()
            endComponents.month = 1
            endComponents.second = -1
            let endOfMonth = calendar.date(byAdding: endComponents, to: startOfMonth)!
            return (startOfMonth, endOfMonth)

        case .custom(let start, let end):
            let startOfDay = calendar.startOfDay(for: start)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: end))!.addingTimeInterval(-1)
            return (startOfDay, endOfDay)
        }
    }

    /// Validates a custom date range
    /// - Parameters:
    ///   - startDate: The start date
    ///   - endDate: The end date
    ///   - referenceDate: The reference date for "future" check (defaults to now)
    /// - Returns: A validation result with any error messages
    func validateCustomRange(startDate: Date, endDate: Date, referenceDate: Date = Date()) -> DateRangeValidationResult {
        var errors: [String] = []

        // Check if end date is before start date
        if endDate < startDate {
            errors.append("End date must be on or after start date")
        }

        // Check if dates are in the future
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: referenceDate))!
        if calendar.startOfDay(for: startDate) >= tomorrow {
            errors.append("Start date cannot be in the future")
        }
        if calendar.startOfDay(for: endDate) >= tomorrow {
            errors.append("End date cannot be in the future")
        }

        // Check if range is too large (more than 1 year)
        let daysDifference = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        if daysDifference > 365 {
            errors.append("Date range cannot exceed 1 year")
        }

        return DateRangeValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    /// Checks if a date falls within the filter's range
    /// - Parameters:
    ///   - date: The date to check
    ///   - filter: The filter to check against
    ///   - referenceDate: The reference date (defaults to now)
    /// - Returns: True if the date is within the filter's range
    func isDate(_ date: Date, inFilter filter: DateFilter, referenceDate: Date = Date()) -> Bool {
        guard let range = dateRange(for: filter, referenceDate: referenceDate) else {
            return true // .all filter includes all dates
        }
        return date >= range.start && date <= range.end
    }

    /// Creates an NSPredicate for filtering expenses by date
    /// - Parameters:
    ///   - filter: The date filter
    ///   - dateKeyPath: The key path for the date field (default: "transactionDate")
    ///   - referenceDate: The reference date (defaults to now)
    /// - Returns: An NSPredicate or nil for .all filter
    func predicate(for filter: DateFilter, dateKeyPath: String = "transactionDate", referenceDate: Date = Date()) -> NSPredicate? {
        guard let range = dateRange(for: filter, referenceDate: referenceDate) else {
            return nil
        }
        return NSPredicate(format: "%K >= %@ AND %K <= %@",
                          dateKeyPath, range.start as NSDate,
                          dateKeyPath, range.end as NSDate)
    }
}

/// Result of date range validation
struct DateRangeValidationResult {
    /// Whether the range is valid
    let isValid: Bool
    /// List of validation errors (empty if valid)
    let errors: [String]

    /// Convenience property for first error
    var firstError: String? {
        errors.first
    }
}
