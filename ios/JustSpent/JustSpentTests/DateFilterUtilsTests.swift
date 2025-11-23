//
//  DateFilterUtilsTests.swift
//  JustSpentTests
//
//  Created by Claude Code on 2025.
//

import XCTest
@testable import JustSpent

final class DateFilterUtilsTests: XCTestCase {

    var sut: DateFilterUtils!
    var calendar: Calendar!
    var referenceDate: Date!

    override func setUpWithError() throws {
        try super.setUpWithError()
        calendar = Calendar.current
        sut = DateFilterUtils(calendar: calendar)

        // Set reference date to a known date: January 15, 2025 at noon
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        components.hour = 12
        components.minute = 0
        components.second = 0
        referenceDate = calendar.date(from: components)!
    }

    override func tearDownWithError() throws {
        sut = nil
        calendar = nil
        referenceDate = nil
        try super.tearDownWithError()
    }

    // MARK: - DateFilter Enum Tests

    func testDateFilter_displayName_returnsCorrectValues() {
        XCTAssertEqual(DateFilter.all.displayName, "All")
        XCTAssertEqual(DateFilter.today.displayName, "Today")
        XCTAssertEqual(DateFilter.week.displayName, "Week")
        XCTAssertEqual(DateFilter.month.displayName, "Month")
        XCTAssertEqual(DateFilter.custom(start: Date(), end: Date()).displayName, "Custom")
    }

    func testDateFilter_equatable_sameFiltersAreEqual() {
        XCTAssertEqual(DateFilter.all, DateFilter.all)
        XCTAssertEqual(DateFilter.today, DateFilter.today)
        XCTAssertEqual(DateFilter.week, DateFilter.week)
        XCTAssertEqual(DateFilter.month, DateFilter.month)
    }

    func testDateFilter_equatable_differentFiltersAreNotEqual() {
        XCTAssertNotEqual(DateFilter.all, DateFilter.today)
        XCTAssertNotEqual(DateFilter.week, DateFilter.month)
    }

    func testDateFilter_equatable_customWithSameDatesAreEqual() {
        let date1 = referenceDate!
        let date2 = referenceDate!.addingTimeInterval(3600) // Same day, different time
        let filter1 = DateFilter.custom(start: date1, end: date1)
        let filter2 = DateFilter.custom(start: date2, end: date2)

        XCTAssertEqual(filter1, filter2, "Custom filters with same day should be equal")
    }

    func testDateFilter_equatable_customWithDifferentDatesAreNotEqual() {
        let date1 = referenceDate!
        let date2 = calendar.date(byAdding: .day, value: 1, to: date1)!
        let filter1 = DateFilter.custom(start: date1, end: date1)
        let filter2 = DateFilter.custom(start: date2, end: date2)

        XCTAssertNotEqual(filter1, filter2, "Custom filters with different days should not be equal")
    }

    func testDateFilter_customRangeDisplayString_returnsFormattedRange() {
        let startDate = referenceDate! // Jan 15
        let endDate = calendar.date(byAdding: .day, value: 5, to: startDate)! // Jan 20

        let filter = DateFilter.custom(start: startDate, end: endDate)
        let displayString = filter.customRangeDisplayString

        XCTAssertNotNil(displayString)
        XCTAssertTrue(displayString!.contains("Jan 15"))
        XCTAssertTrue(displayString!.contains("Jan 20"))
    }

    func testDateFilter_customRangeDisplayString_nilForNonCustomFilters() {
        XCTAssertNil(DateFilter.all.customRangeDisplayString)
        XCTAssertNil(DateFilter.today.customRangeDisplayString)
        XCTAssertNil(DateFilter.week.customRangeDisplayString)
        XCTAssertNil(DateFilter.month.customRangeDisplayString)
    }

    // MARK: - DateRange Tests

    func testDateRange_allFilter_returnsNil() {
        let result = sut.dateRange(for: .all, referenceDate: referenceDate)
        XCTAssertNil(result, ".all filter should return nil range")
    }

    func testDateRange_todayFilter_returnsCurrentDay() {
        let result = sut.dateRange(for: .today, referenceDate: referenceDate)

        XCTAssertNotNil(result)
        let (start, end) = result!

        // Start should be beginning of day (00:00:00)
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: start)
        XCTAssertEqual(startComponents.year, 2025)
        XCTAssertEqual(startComponents.month, 1)
        XCTAssertEqual(startComponents.day, 15)
        XCTAssertEqual(startComponents.hour, 0)
        XCTAssertEqual(startComponents.minute, 0)
        XCTAssertEqual(startComponents.second, 0)

        // End should be end of day (23:59:59)
        let endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: end)
        XCTAssertEqual(endComponents.year, 2025)
        XCTAssertEqual(endComponents.month, 1)
        XCTAssertEqual(endComponents.day, 15)
        XCTAssertEqual(endComponents.hour, 23)
        XCTAssertEqual(endComponents.minute, 59)
        XCTAssertEqual(endComponents.second, 59)
    }

    func testDateRange_weekFilter_returnsLast7Days() {
        let result = sut.dateRange(for: .week, referenceDate: referenceDate)

        XCTAssertNotNil(result)
        let (start, end) = result!

        // Start should be 6 days ago (Jan 9)
        let startComponents = calendar.dateComponents([.year, .month, .day], from: start)
        XCTAssertEqual(startComponents.year, 2025)
        XCTAssertEqual(startComponents.month, 1)
        XCTAssertEqual(startComponents.day, 9)

        // End should be end of reference day (Jan 15)
        let endComponents = calendar.dateComponents([.year, .month, .day], from: end)
        XCTAssertEqual(endComponents.year, 2025)
        XCTAssertEqual(endComponents.month, 1)
        XCTAssertEqual(endComponents.day, 15)
    }

    func testDateRange_monthFilter_returnsCurrentMonth() {
        let result = sut.dateRange(for: .month, referenceDate: referenceDate)

        XCTAssertNotNil(result)
        let (start, end) = result!

        // Start should be beginning of month (Jan 1)
        let startComponents = calendar.dateComponents([.year, .month, .day], from: start)
        XCTAssertEqual(startComponents.year, 2025)
        XCTAssertEqual(startComponents.month, 1)
        XCTAssertEqual(startComponents.day, 1)

        // End should be end of month (Jan 31)
        let endComponents = calendar.dateComponents([.year, .month, .day], from: end)
        XCTAssertEqual(endComponents.year, 2025)
        XCTAssertEqual(endComponents.month, 1)
        XCTAssertEqual(endComponents.day, 31)
    }

    func testDateRange_customFilter_returnsSpecifiedRange() {
        let startDate = referenceDate!
        let endDate = calendar.date(byAdding: .day, value: 10, to: startDate)!
        let filter = DateFilter.custom(start: startDate, end: endDate)

        let result = sut.dateRange(for: filter, referenceDate: referenceDate)

        XCTAssertNotNil(result)
        let (start, end) = result!

        // Start should be beginning of start day
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour], from: start)
        XCTAssertEqual(startComponents.year, 2025)
        XCTAssertEqual(startComponents.month, 1)
        XCTAssertEqual(startComponents.day, 15)
        XCTAssertEqual(startComponents.hour, 0)

        // End should be end of end day
        let endComponents = calendar.dateComponents([.year, .month, .day], from: end)
        XCTAssertEqual(endComponents.year, 2025)
        XCTAssertEqual(endComponents.month, 1)
        XCTAssertEqual(endComponents.day, 25)
    }

    // MARK: - Validation Tests

    func testValidateCustomRange_validRange_returnsValid() {
        let startDate = calendar.date(byAdding: .day, value: -7, to: referenceDate)!
        let endDate = referenceDate!

        let result = sut.validateCustomRange(startDate: startDate, endDate: endDate, referenceDate: referenceDate)

        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
    }

    func testValidateCustomRange_sameDayRange_returnsValid() {
        let result = sut.validateCustomRange(startDate: referenceDate, endDate: referenceDate, referenceDate: referenceDate)

        XCTAssertTrue(result.isValid, "Same day range should be valid")
        XCTAssertTrue(result.errors.isEmpty)
    }

    func testValidateCustomRange_endBeforeStart_returnsInvalid() {
        let startDate = referenceDate!
        let endDate = calendar.date(byAdding: .day, value: -5, to: referenceDate)!

        let result = sut.validateCustomRange(startDate: startDate, endDate: endDate, referenceDate: referenceDate)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("End date must be on or after start date") })
    }

    func testValidateCustomRange_startInFuture_returnsInvalid() {
        let startDate = calendar.date(byAdding: .day, value: 5, to: referenceDate)!
        let endDate = calendar.date(byAdding: .day, value: 10, to: referenceDate)!

        let result = sut.validateCustomRange(startDate: startDate, endDate: endDate, referenceDate: referenceDate)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("Start date cannot be in the future") })
    }

    func testValidateCustomRange_endInFuture_returnsInvalid() {
        let startDate = calendar.date(byAdding: .day, value: -5, to: referenceDate)!
        let endDate = calendar.date(byAdding: .day, value: 5, to: referenceDate)!

        let result = sut.validateCustomRange(startDate: startDate, endDate: endDate, referenceDate: referenceDate)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("End date cannot be in the future") })
    }

    func testValidateCustomRange_rangeExceedsOneYear_returnsInvalid() {
        let startDate = calendar.date(byAdding: .day, value: -400, to: referenceDate)!
        let endDate = referenceDate!

        let result = sut.validateCustomRange(startDate: startDate, endDate: endDate, referenceDate: referenceDate)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("Date range cannot exceed 1 year") })
    }

    func testValidateCustomRange_multipleErrors_returnsAllErrors() {
        let startDate = calendar.date(byAdding: .day, value: 10, to: referenceDate)!
        let endDate = calendar.date(byAdding: .day, value: 5, to: referenceDate)!

        let result = sut.validateCustomRange(startDate: startDate, endDate: endDate, referenceDate: referenceDate)

        XCTAssertFalse(result.isValid)
        XCTAssertGreaterThanOrEqual(result.errors.count, 2, "Should have multiple errors")
    }

    // MARK: - isDate(inFilter:) Tests

    func testIsDate_allFilter_alwaysReturnsTrue() {
        let pastDate = calendar.date(byAdding: .year, value: -1, to: referenceDate)!
        let futureDate = calendar.date(byAdding: .year, value: 1, to: referenceDate)!

        XCTAssertTrue(sut.isDate(pastDate, inFilter: .all, referenceDate: referenceDate))
        XCTAssertTrue(sut.isDate(referenceDate, inFilter: .all, referenceDate: referenceDate))
        XCTAssertTrue(sut.isDate(futureDate, inFilter: .all, referenceDate: referenceDate))
    }

    func testIsDate_todayFilter_returnsTrueForToday() {
        let todayMorning = calendar.startOfDay(for: referenceDate)
        let todayEvening = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: referenceDate)!

        XCTAssertTrue(sut.isDate(todayMorning, inFilter: .today, referenceDate: referenceDate))
        XCTAssertTrue(sut.isDate(todayEvening, inFilter: .today, referenceDate: referenceDate))
    }

    func testIsDate_todayFilter_returnsFalseForYesterday() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDate)!

        XCTAssertFalse(sut.isDate(yesterday, inFilter: .today, referenceDate: referenceDate))
    }

    func testIsDate_weekFilter_returnsTrueForLast7Days() {
        let sixDaysAgo = calendar.date(byAdding: .day, value: -6, to: referenceDate)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: referenceDate)!

        XCTAssertTrue(sut.isDate(sixDaysAgo, inFilter: .week, referenceDate: referenceDate))
        XCTAssertTrue(sut.isDate(threeDaysAgo, inFilter: .week, referenceDate: referenceDate))
        XCTAssertTrue(sut.isDate(referenceDate, inFilter: .week, referenceDate: referenceDate))
    }

    func testIsDate_weekFilter_returnsFalseForOlderDates() {
        let eightDaysAgo = calendar.date(byAdding: .day, value: -8, to: referenceDate)!

        XCTAssertFalse(sut.isDate(eightDaysAgo, inFilter: .week, referenceDate: referenceDate))
    }

    func testIsDate_monthFilter_returnsTrueForCurrentMonth() {
        // Jan 1
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 1
        let firstOfMonth = calendar.date(from: components)!

        // Jan 31
        components.day = 31
        let lastOfMonth = calendar.date(from: components)!

        XCTAssertTrue(sut.isDate(firstOfMonth, inFilter: .month, referenceDate: referenceDate))
        XCTAssertTrue(sut.isDate(lastOfMonth, inFilter: .month, referenceDate: referenceDate))
        XCTAssertTrue(sut.isDate(referenceDate, inFilter: .month, referenceDate: referenceDate))
    }

    func testIsDate_monthFilter_returnsFalseForPreviousMonth() {
        // Dec 31, 2024
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 31
        let lastMonth = calendar.date(from: components)!

        XCTAssertFalse(sut.isDate(lastMonth, inFilter: .month, referenceDate: referenceDate))
    }

    func testIsDate_customFilter_returnsTrueForDatesInRange() {
        let startDate = calendar.date(byAdding: .day, value: -10, to: referenceDate)! // Jan 5
        let endDate = calendar.date(byAdding: .day, value: -5, to: referenceDate)! // Jan 10
        let filter = DateFilter.custom(start: startDate, end: endDate)

        let dateInRange = calendar.date(byAdding: .day, value: -7, to: referenceDate)! // Jan 8

        XCTAssertTrue(sut.isDate(dateInRange, inFilter: filter, referenceDate: referenceDate))
        XCTAssertTrue(sut.isDate(startDate, inFilter: filter, referenceDate: referenceDate))
        XCTAssertTrue(sut.isDate(endDate, inFilter: filter, referenceDate: referenceDate))
    }

    func testIsDate_customFilter_returnsFalseForDatesOutOfRange() {
        let startDate = calendar.date(byAdding: .day, value: -10, to: referenceDate)! // Jan 5
        let endDate = calendar.date(byAdding: .day, value: -5, to: referenceDate)! // Jan 10
        let filter = DateFilter.custom(start: startDate, end: endDate)

        let beforeRange = calendar.date(byAdding: .day, value: -15, to: referenceDate)! // Dec 31
        let afterRange = referenceDate! // Jan 15

        XCTAssertFalse(sut.isDate(beforeRange, inFilter: filter, referenceDate: referenceDate))
        XCTAssertFalse(sut.isDate(afterRange, inFilter: filter, referenceDate: referenceDate))
    }

    // MARK: - Predicate Tests

    func testPredicate_allFilter_returnsNil() {
        let result = sut.predicate(for: .all, referenceDate: referenceDate)
        XCTAssertNil(result)
    }

    func testPredicate_todayFilter_returnsValidPredicate() {
        let result = sut.predicate(for: .today, referenceDate: referenceDate)

        XCTAssertNotNil(result)
        XCTAssertTrue(result!.predicateFormat.contains("transactionDate"))
    }

    func testPredicate_customKeyPath_usesCorrectKeyPath() {
        let result = sut.predicate(for: .today, dateKeyPath: "createdAt", referenceDate: referenceDate)

        XCTAssertNotNil(result)
        XCTAssertTrue(result!.predicateFormat.contains("createdAt"))
    }

    // MARK: - Edge Case Tests

    func testDateRange_monthFilter_handlesFebruary() {
        // February 15, 2025
        var components = DateComponents()
        components.year = 2025
        components.month = 2
        components.day = 15
        let febDate = calendar.date(from: components)!

        let result = sut.dateRange(for: .month, referenceDate: febDate)

        XCTAssertNotNil(result)
        let endComponents = calendar.dateComponents([.month, .day], from: result!.end)
        XCTAssertEqual(endComponents.month, 2)
        XCTAssertEqual(endComponents.day, 28) // 2025 is not a leap year
    }

    func testDateRange_monthFilter_handlesLeapYear() {
        // February 15, 2024 (leap year)
        var components = DateComponents()
        components.year = 2024
        components.month = 2
        components.day = 15
        let febDate = calendar.date(from: components)!

        let result = sut.dateRange(for: .month, referenceDate: febDate)

        XCTAssertNotNil(result)
        let endComponents = calendar.dateComponents([.month, .day], from: result!.end)
        XCTAssertEqual(endComponents.month, 2)
        XCTAssertEqual(endComponents.day, 29) // Leap year
    }

    func testDateRange_weekFilter_crossesMonthBoundary() {
        // January 3, 2025
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 3
        let earlyJan = calendar.date(from: components)!

        let result = sut.dateRange(for: .week, referenceDate: earlyJan)

        XCTAssertNotNil(result)
        let startComponents = calendar.dateComponents([.year, .month, .day], from: result!.start)
        XCTAssertEqual(startComponents.year, 2024)
        XCTAssertEqual(startComponents.month, 12)
        XCTAssertEqual(startComponents.day, 28) // Dec 28, 2024
    }
}
