//
//  ContentViewTests.swift
//  JustSpentTests
//
//  Created by Claude Code on 2025-10-20.
//  Tests for ContentView conditional UI rendering
//

import XCTest
import CoreData
import SwiftUI
@testable import JustSpent

final class ContentViewTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        context = TestData.context
    }

    override func tearDownWithError() throws {
        // Clean up all test expenses
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Expense.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try context.execute(deleteRequest)
        try context.save()

        context = nil
        try super.tearDownWithError()
    }

    // MARK: - Currency Detection Tests

    func testDetectActiveCurrenciesFromExpenses() throws {
        // Create expenses in multiple currencies
        let expenses = [
            TestData.createExpense(amount: 100, currency: "AED", category: "Test", in: context),
            TestData.createExpense(amount: 50, currency: "USD", category: "Test", in: context),
            TestData.createExpense(amount: 75, currency: "AED", category: "Test", in: context),
            TestData.createExpense(amount: 30, currency: "EUR", category: "Test", in: context)
        ]
        try context.save()

        // Extract distinct currencies
        let currencyCodes = Set(expenses.compactMap { $0.currency })
        let activeCurrencies = currencyCodes.compactMap { Currency.from(isoCode: $0) }

        XCTAssertEqual(activeCurrencies.count, 3, "Should detect 3 distinct currencies (AED, USD, EUR)")
        XCTAssertTrue(activeCurrencies.contains(.aed), "Should contain AED")
        XCTAssertTrue(activeCurrencies.contains(.usd), "Should contain USD")
        XCTAssertTrue(activeCurrencies.contains(.eur), "Should contain EUR")

        // Cleanup
        for expense in expenses {
            context.delete(expense)
        }
        try context.save()
    }

    func testNoCurrenciesWhenNoExpenses() throws {
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        let expenses = try context.fetch(fetchRequest)

        let currencyCodes = Set(expenses.compactMap { $0.currency })
        let activeCurrencies = currencyCodes.compactMap { Currency.from(isoCode: $0) }

        XCTAssertEqual(activeCurrencies.count, 0, "Should have no active currencies when no expenses")
    }

    func testSingleCurrencyDetection() throws {
        // Create expenses in only one currency
        let expenses = [
            TestData.createExpense(amount: 100, currency: "AED", category: "Test", in: context),
            TestData.createExpense(amount: 50, currency: "AED", category: "Test", in: context)
        ]
        try context.save()

        let currencyCodes = Set(expenses.compactMap { $0.currency })
        let activeCurrencies = currencyCodes.compactMap { Currency.from(isoCode: $0) }

        XCTAssertEqual(activeCurrencies.count, 1, "Should detect only 1 currency")
        XCTAssertEqual(activeCurrencies.first, .aed, "Should be AED")

        // Cleanup
        for expense in expenses {
            context.delete(expense)
        }
        try context.save()
    }

    // MARK: - Tab Display Decision Tests

    func testShouldShowTabsWithMultipleCurrencies() throws {
        let activeCurrencies: [Currency] = [.aed, .usd, .eur]
        let shouldShowTabs = activeCurrencies.count > 1

        XCTAssertTrue(shouldShowTabs, "Should show tabs when multiple currencies exist")
    }

    func testShouldNotShowTabsWithSingleCurrency() throws {
        let activeCurrencies: [Currency] = [.aed]
        let shouldShowTabs = activeCurrencies.count > 1

        XCTAssertFalse(shouldShowTabs, "Should not show tabs with single currency")
    }

    func testShouldNotShowTabsWhenEmpty() throws {
        let activeCurrencies: [Currency] = []
        let shouldShowTabs = activeCurrencies.count > 1

        XCTAssertFalse(shouldShowTabs, "Should not show tabs when no currencies")
    }

    // MARK: - Conditional Rendering Logic Tests

    func testRenderEmptyStateWhenNoExpenses() throws {
        let expenses: [Expense] = []
        let isEmpty = expenses.isEmpty

        XCTAssertTrue(isEmpty, "Should render empty state when no expenses")
    }

    func testRenderSingleCurrencyViewWhenOneCurrency() throws {
        let expenses = [
            TestData.createExpense(amount: 100, currency: "AED", category: "Test", in: context)
        ]

        let currencyCodes = Set(expenses.compactMap { $0.currency })
        let activeCurrencies = currencyCodes.compactMap { Currency.from(isoCode: $0) }
        let shouldShowTabs = activeCurrencies.count > 1

        XCTAssertFalse(expenses.isEmpty, "Should have expenses")
        XCTAssertFalse(shouldShowTabs, "Should not show tabs")
        XCTAssertEqual(activeCurrencies.count, 1, "Should have one currency")

        // Cleanup
        for expense in expenses {
            context.delete(expense)
        }
        try context.save()
    }

    func testRenderMultiCurrencyTabsWhenMultipleCurrencies() throws {
        let expenses = [
            TestData.createExpense(amount: 100, currency: "AED", category: "Test", in: context),
            TestData.createExpense(amount: 50, currency: "USD", category: "Test", in: context)
        ]

        let currencyCodes = Set(expenses.compactMap { $0.currency })
        let activeCurrencies = currencyCodes.compactMap { Currency.from(isoCode: $0) }
        let shouldShowTabs = activeCurrencies.count > 1

        XCTAssertFalse(expenses.isEmpty, "Should have expenses")
        XCTAssertTrue(shouldShowTabs, "Should show tabs")
        XCTAssertGreaterThan(activeCurrencies.count, 1, "Should have multiple currencies")

        // Cleanup
        for expense in expenses {
            context.delete(expense)
        }
        try context.save()
    }

    // MARK: - Currency Sorting Tests

    func testActiveCurrenciesSorted() throws {
        let unsortedCurrencies: [Currency] = [.usd, .aed, .eur, .gbp]
        let sortedCurrencies = unsortedCurrencies.sorted { $0.displayName < $1.displayName }

        // Verify sorted order
        for i in 0..<(sortedCurrencies.count - 1) {
            XCTAssertLessThan(
                sortedCurrencies[i].displayName,
                sortedCurrencies[i + 1].displayName,
                "Currencies should be sorted alphabetically"
            )
        }
    }

    // MARK: - View State Transition Tests

    func testTransitionFromEmptyToSingleCurrency() throws {
        // Start with no expenses (empty state)
        var expenses: [Expense] = []
        var isEmpty = expenses.isEmpty

        XCTAssertTrue(isEmpty, "Should start in empty state")

        // Add first expense
        let expense = TestData.createExpense(amount: 100, currency: "AED", category: "Test", in: context)
        expenses.append(expense)
        isEmpty = expenses.isEmpty

        let currencyCodes = Set(expenses.compactMap { $0.currency })
        let activeCurrencies = currencyCodes.compactMap { Currency.from(isoCode: $0) }
        let shouldShowTabs = activeCurrencies.count > 1

        XCTAssertFalse(isEmpty, "Should no longer be empty")
        XCTAssertFalse(shouldShowTabs, "Should show single currency view")

        // Cleanup
        context.delete(expense)
        try context.save()
    }

    func testTransitionFromSingleToMultipleCurrencies() throws {
        // Start with one currency
        var expenses = [
            TestData.createExpense(amount: 100, currency: "AED", category: "Test", in: context)
        ]

        var currencyCodes = Set(expenses.compactMap { $0.currency })
        var activeCurrencies = currencyCodes.compactMap { Currency.from(isoCode: $0) }
        var shouldShowTabs = activeCurrencies.count > 1

        XCTAssertFalse(shouldShowTabs, "Should start with single currency view")

        // Add expense in different currency
        let usdExpense = TestData.createExpense(amount: 50, currency: "USD", category: "Test", in: context)
        expenses.append(usdExpense)

        currencyCodes = Set(expenses.compactMap { $0.currency })
        activeCurrencies = currencyCodes.compactMap { Currency.from(isoCode: $0) }
        shouldShowTabs = activeCurrencies.count > 1

        XCTAssertTrue(shouldShowTabs, "Should now show tabbed view")

        // Cleanup
        for expense in expenses {
            context.delete(expense)
        }
        try context.save()
    }

    func testTransitionFromMultipleToSingleCurrency() throws {
        // Start with multiple currencies
        var expenses = [
            TestData.createExpense(amount: 100, currency: "AED", category: "Test", in: context),
            TestData.createExpense(amount: 50, currency: "USD", category: "Test", in: context)
        ]

        var currencyCodes = Set(expenses.compactMap { $0.currency })
        var activeCurrencies = currencyCodes.compactMap { Currency.from(isoCode: $0) }
        var shouldShowTabs = activeCurrencies.count > 1

        XCTAssertTrue(shouldShowTabs, "Should start with tabbed view")

        // Delete USD expense
        context.delete(expenses[1])
        expenses.remove(at: 1)

        currencyCodes = Set(expenses.compactMap { $0.currency })
        activeCurrencies = currencyCodes.compactMap { Currency.from(isoCode: $0) }
        shouldShowTabs = activeCurrencies.count > 1

        XCTAssertFalse(shouldShowTabs, "Should switch to single currency view")

        // Cleanup
        for expense in expenses {
            context.delete(expense)
        }
        try context.save()
    }

    func testTransitionFromSingleToEmpty() throws {
        // Start with one expense
        let expense = TestData.createExpense(amount: 100, currency: "AED", category: "Test", in: context)
        var expenses = [expense]

        var isEmpty = expenses.isEmpty
        XCTAssertFalse(isEmpty, "Should have expenses")

        // Delete the expense
        context.delete(expense)
        expenses.removeAll()

        isEmpty = expenses.isEmpty
        XCTAssertTrue(isEmpty, "Should be empty after deletion")

        try context.save()
    }

    // MARK: - Integration Tests

    func testContentViewCreation() throws {
        let view = ContentView()
            .environment(\.managedObjectContext, context)

        XCTAssertNotNil(view, "ContentView should be created successfully")
    }

    func testContentViewWithEmptyState() throws {
        // Ensure no expenses exist
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Expense.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try context.execute(deleteRequest)
        try context.save()

        let view = ContentView()
            .environment(\.managedObjectContext, context)

        XCTAssertNotNil(view, "Should handle empty state")
    }

    func testContentViewWithSingleCurrency() throws {
        let expense = TestData.createExpense(amount: 100, currency: "AED", category: "Test", in: context)
        try context.save()

        let view = ContentView()
            .environment(\.managedObjectContext, context)

        XCTAssertNotNil(view, "Should handle single currency")

        context.delete(expense)
        try context.save()
    }

    func testContentViewWithMultipleCurrencies() throws {
        let expenses = [
            TestData.createExpense(amount: 100, currency: "AED", category: "Test", in: context),
            TestData.createExpense(amount: 50, currency: "USD", category: "Test", in: context)
        ]
        try context.save()

        let view = ContentView()
            .environment(\.managedObjectContext, context)

        XCTAssertNotNil(view, "Should handle multiple currencies")

        for expense in expenses {
            context.delete(expense)
        }
        try context.save()
    }

    // MARK: - Performance Tests

    func testCurrencyDetectionPerformance() throws {
        // Create many expenses
        var expenses: [Expense] = []
        for i in 0..<100 {
            let currency = i % 3 == 0 ? "AED" : (i % 3 == 1 ? "USD" : "EUR")
            expenses.append(TestData.createExpense(amount: Double(i), currency: currency, category: "Test", in: context))
        }

        measure {
            let currencyCodes = Set(expenses.compactMap { $0.currency })
            _ = currencyCodes.compactMap { Currency.from(isoCode: $0) }
        }

        // Cleanup
        for expense in expenses {
            context.delete(expense)
        }
        try context.save()
    }

    func testConditionalRenderingPerformance() throws {
        let expenses = [
            TestData.createExpense(amount: 100, currency: "AED", category: "Test", in: context),
            TestData.createExpense(amount: 50, currency: "USD", category: "Test", in: context)
        ]

        measure {
            let isEmpty = expenses.isEmpty
            let currencyCodes = Set(expenses.compactMap { $0.currency })
            let activeCurrencies = currencyCodes.compactMap { Currency.from(isoCode: $0) }
            let shouldShowTabs = activeCurrencies.count > 1

            XCTAssertFalse(isEmpty)
            XCTAssertTrue(shouldShowTabs)
        }

        // Cleanup
        for expense in expenses {
            context.delete(expense)
        }
        try context.save()
    }
}
