//
//  CurrencyExpenseListViewTests.swift
//  JustSpentTests
//
//  Created by Claude Code on 2025-10-20.
//  Tests for currency-filtered expense list view
//

import XCTest
import CoreData
import SwiftUI
@testable import JustSpent

final class CurrencyExpenseListViewTests: XCTestCase {

    var context: NSManagedObjectContext!
    var testExpenses: [Expense]!

    override func setUpWithError() throws {
        try super.setUpWithError()
        context = TestData.context
        testExpenses = TestData.createSampleExpenses(in: context)
        try context.save()
    }

    override func tearDownWithError() throws {
        // Clean up test data
        for expense in testExpenses {
            context.delete(expense)
        }
        try context.save()

        context = nil
        testExpenses = nil
        try super.tearDownWithError()
    }

    // MARK: - Currency Filtering Tests

    func testFilterExpensesByAED() throws {
        let aedExpenses = testExpenses.filter { $0.currency == "AED" }
        XCTAssertEqual(aedExpenses.count, 3, "Should have 3 AED expenses")

        // Verify all are actually AED
        for expense in aedExpenses {
            XCTAssertEqual(expense.currency, "AED", "All filtered expenses should be AED")
        }
    }

    func testFilterExpensesByUSD() throws {
        let usdExpenses = testExpenses.filter { $0.currency == "USD" }
        XCTAssertEqual(usdExpenses.count, 2, "Should have 2 USD expenses")

        // Verify all are actually USD
        for expense in usdExpenses {
            XCTAssertEqual(expense.currency, "USD", "All filtered expenses should be USD")
        }
    }

    func testFilterExpensesByEUR() throws {
        let eurExpenses = testExpenses.filter { $0.currency == "EUR" }
        XCTAssertEqual(eurExpenses.count, 1, "Should have 1 EUR expense")

        // Verify it is EUR
        XCTAssertEqual(eurExpenses.first?.currency, "EUR", "Filtered expense should be EUR")
    }

    func testFilterByNonExistentCurrency() throws {
        let jpyExpenses = testExpenses.filter { $0.currency == "JPY" }
        XCTAssertEqual(jpyExpenses.count, 0, "Should have 0 JPY expenses")
    }

    // MARK: - Total Calculation Tests

    func testCalculateTotalForAED() throws {
        let aedExpenses = testExpenses.filter { $0.currency == "AED" }
        let total = aedExpenses.reduce(0.0) { sum, expense in
            sum + (expense.amount?.doubleValue ?? 0)
        }

        // AED: 150 + 50 + 200 = 400
        XCTAssertEqual(total, 400.00, accuracy: 0.01, "AED total should be 400.00")
    }

    func testCalculateTotalForUSD() throws {
        let usdExpenses = testExpenses.filter { $0.currency == "USD" }
        let total = usdExpenses.reduce(0.0) { sum, expense in
            sum + (expense.amount?.doubleValue ?? 0)
        }

        // USD: 25.99 + 5.50 = 31.49
        XCTAssertEqual(total, 31.49, accuracy: 0.01, "USD total should be 31.49")
    }

    func testCalculateTotalForEUR() throws {
        let eurExpenses = testExpenses.filter { $0.currency == "EUR" }
        let total = eurExpenses.reduce(0.0) { sum, expense in
            sum + (expense.amount?.doubleValue ?? 0)
        }

        // EUR: 45.00
        XCTAssertEqual(total, 45.00, accuracy: 0.01, "EUR total should be 45.00")
    }

    func testCalculateTotalForEmptyCurrency() throws {
        let jpyExpenses = testExpenses.filter { $0.currency == "JPY" }
        let total = jpyExpenses.reduce(0.0) { sum, expense in
            sum + (expense.amount?.doubleValue ?? 0)
        }

        XCTAssertEqual(total, 0.00, accuracy: 0.01, "Total should be 0.00 for empty currency")
    }

    // MARK: - Sorting Tests

    func testExpensesSortedByDateDescending() throws {
        let aedExpenses = testExpenses
            .filter { $0.currency == "AED" }
            .sorted { ($0.transactionDate ?? Date()) > ($1.transactionDate ?? Date()) }

        XCTAssertGreaterThanOrEqual(
            aedExpenses.first?.transactionDate ?? Date(),
            aedExpenses.last?.transactionDate ?? Date(),
            "First expense should be more recent than last"
        )
    }

    // MARK: - Empty State Tests

    func testEmptyStateWhenNoCurrencyExpenses() throws {
        // Create a new context with no EUR expenses initially
        let emptyContext = TestData.context

        // Create only AED expenses
        let aedExpense = TestData.createExpense(
            amount: 100.0,
            currency: "AED",
            category: "Test",
            in: emptyContext
        )
        try emptyContext.save()

        // Filter for EUR (should be empty)
        let eurExpenses = [aedExpense].filter { $0.currency == "EUR" }

        XCTAssertTrue(eurExpenses.isEmpty, "EUR expenses should be empty")

        // Cleanup
        emptyContext.delete(aedExpense)
        try emptyContext.save()
    }

    // MARK: - Formatting Tests

    func testFormattedTotalForAED() throws {
        let amount = Decimal(400.00)
        let formatted = CurrencyFormatter.shared.format(
            amount: amount,
            currency: .aed,
            showSymbol: true,
            showCode: false
        )

        XCTAssertTrue(formatted.contains("د.إ"), "Should contain AED symbol")
        XCTAssertTrue(formatted.contains("400"), "Should contain amount 400")
    }

    func testFormattedTotalForUSD() throws {
        let amount = Decimal(31.49)
        let formatted = CurrencyFormatter.shared.format(
            amount: amount,
            currency: .usd,
            showSymbol: true,
            showCode: false
        )

        XCTAssertTrue(formatted.contains("$"), "Should contain USD symbol")
        XCTAssertTrue(formatted.contains("31"), "Should contain amount")
    }

    // MARK: - Expense Deletion Tests

    func testDeleteExpenseFromList() throws {
        let aedExpenses = testExpenses.filter { $0.currency == "AED" }
        let initialCount = aedExpenses.count

        // Delete first AED expense
        if let expenseToDelete = aedExpenses.first {
            context.delete(expenseToDelete)
            try context.save()
        }

        // Fetch again
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "currency == %@", "AED")
        let remainingExpenses = try context.fetch(fetchRequest)

        XCTAssertEqual(remainingExpenses.count, initialCount - 1, "Should have one less AED expense after deletion")
    }

    // MARK: - Core Data Predicate Tests

    func testNSPredicateForCurrencyFilter() throws {
        let predicate = NSPredicate(format: "currency == %@", "AED")
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        fetchRequest.predicate = predicate

        let results = try context.fetch(fetchRequest)

        XCTAssertGreaterThan(results.count, 0, "Should fetch AED expenses")

        // Verify all results match predicate
        for expense in results {
            XCTAssertEqual(expense.currency, "AED", "All fetched expenses should be AED")
        }
    }

    func testFetchRequestWithSortDescriptor() throws {
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "currency == %@", "AED")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Expense.transactionDate, ascending: false)]

        let results = try context.fetch(fetchRequest)

        XCTAssertGreaterThan(results.count, 0, "Should fetch AED expenses")

        // Verify sorted by date descending
        if results.count > 1 {
            for i in 0..<(results.count - 1) {
                let current = results[i].transactionDate ?? Date()
                let next = results[i + 1].transactionDate ?? Date()
                XCTAssertGreaterThanOrEqual(current, next, "Should be sorted by date descending")
            }
        }
    }

    // MARK: - Performance Tests

    func testFilteringPerformance() throws {
        // Create many more expenses for performance testing
        var manyExpenses: [Expense] = []
        for i in 0..<100 {
            let expense = TestData.createExpense(
                amount: Double(i) * 10.0,
                currency: i % 2 == 0 ? "AED" : "USD",
                category: "Test",
                in: context
            )
            manyExpenses.append(expense)
        }
        try context.save()

        measure {
            let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "currency == %@", "AED")
            _ = try? context.fetch(fetchRequest)
        }

        // Cleanup
        for expense in manyExpenses {
            context.delete(expense)
        }
        try context.save()
    }

    func testTotalCalculationPerformance() throws {
        // Create many expenses
        var manyExpenses: [Expense] = []
        for i in 0..<100 {
            let expense = TestData.createExpense(
                amount: Double(i) * 10.0,
                currency: "AED",
                category: "Test",
                in: context
            )
            manyExpenses.append(expense)
        }

        measure {
            let total = manyExpenses.reduce(0.0) { sum, expense in
                sum + (expense.amount?.doubleValue ?? 0)
            }
            XCTAssertGreaterThan(total, 0, "Total should be calculated")
        }

        // Cleanup
        for expense in manyExpenses {
            context.delete(expense)
        }
        try context.save()
    }

    // MARK: - Integration Tests

    func testCurrencyExpenseListViewCreation() throws {
        // Test view initialization doesn't crash
        let view = CurrencyExpenseListView(currency: .aed)
            .environment(\.managedObjectContext, context)

        XCTAssertNotNil(view, "View should be created successfully")
    }

    func testMultipleCurrencyViews() throws {
        // Test creating views for all supported currencies
        let currencies: [Currency] = [.aed, .usd, .eur, .gbp, .inr, .sar]

        for currency in currencies {
            let view = CurrencyExpenseListView(currency: currency)
                .environment(\.managedObjectContext, context)

            XCTAssertNotNil(view, "View should be created for \(currency.rawValue)")
        }
    }
}
