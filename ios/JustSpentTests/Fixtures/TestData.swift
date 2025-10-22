//
//  TestData.swift
//  JustSpentTests
//
//  Created by Claude Code on 2025-10-20.
//  Test data fixtures for multi-currency testing
//

import Foundation
import CoreData
@testable import JustSpent

/// Test data fixtures for multi-currency functionality testing
struct TestData {

    // MARK: - Mock Core Data Stack

    /// In-memory Core Data stack for testing
    static var mockPersistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "JustSpent")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { (description, error) in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }

        return container
    }()

    /// Managed object context for testing
    static var context: NSManagedObjectContext {
        return mockPersistentContainer.viewContext
    }

    // MARK: - Sample Expenses

    /// Creates sample expenses in multiple currencies
    static func createSampleExpenses(in context: NSManagedObjectContext) -> [Expense] {
        var expenses: [Expense] = []

        // AED expenses
        expenses.append(createExpense(
            amount: 150.00,
            currency: "AED",
            category: "Grocery",
            merchant: "Carrefour",
            date: Date().addingTimeInterval(-86400 * 2),
            in: context
        ))

        expenses.append(createExpense(
            amount: 50.00,
            currency: "AED",
            category: "Food & Dining",
            merchant: "Tim Hortons",
            date: Date().addingTimeInterval(-86400),
            in: context
        ))

        expenses.append(createExpense(
            amount: 200.00,
            currency: "AED",
            category: "Transportation",
            merchant: "ENOC",
            date: Date(),
            in: context
        ))

        // USD expenses
        expenses.append(createExpense(
            amount: 25.99,
            currency: "USD",
            category: "Shopping",
            merchant: "Amazon",
            date: Date().addingTimeInterval(-86400 * 3),
            in: context
        ))

        expenses.append(createExpense(
            amount: 5.50,
            currency: "USD",
            category: "Food & Dining",
            merchant: "Starbucks",
            date: Date().addingTimeInterval(-3600),
            in: context
        ))

        // EUR expenses
        expenses.append(createExpense(
            amount: 45.00,
            currency: "EUR",
            category: "Entertainment",
            merchant: "Cinema",
            date: Date().addingTimeInterval(-86400 * 5),
            in: context
        ))

        return expenses
    }

    /// Creates a single expense
    static func createExpense(
        amount: Double,
        currency: String,
        category: String,
        merchant: String? = nil,
        date: Date = Date(),
        voiceTranscript: String? = nil,
        in context: NSManagedObjectContext
    ) -> Expense {
        let expense = Expense(context: context)
        expense.id = UUID()
        expense.amount = NSDecimalNumber(value: amount)
        expense.currency = currency
        expense.category = category
        expense.merchant = merchant
        expense.transactionDate = date
        expense.createdAt = date
        expense.updatedAt = date
        expense.source = AppConstants.ExpenseSource.manual
        expense.voiceTranscript = voiceTranscript
        expense.status = AppConstants.ExpenseStatus.active

        return expense
    }

    // MARK: - Voice Command Test Data

    /// Sample voice commands with currency mentions
    static let voiceCommands: [VoiceCommandTestCase] = [
        // USD variations
        VoiceCommandTestCase(
            input: "I just spent 50 dollars on groceries",
            expectedAmount: 50.0,
            expectedCurrency: "USD",
            expectedCategory: "Grocery"
        ),
        VoiceCommandTestCase(
            input: "I spent $25.50 at Starbucks",
            expectedAmount: 25.50,
            expectedCurrency: "USD",
            expectedCategory: "Food & Dining",
            expectedMerchant: "Starbucks"
        ),

        // AED variations
        VoiceCommandTestCase(
            input: "I just spent 150 dirhams on groceries",
            expectedAmount: 150.0,
            expectedCurrency: "AED",
            expectedCategory: "Grocery"
        ),
        VoiceCommandTestCase(
            input: "50 AED for food",
            expectedAmount: 50.0,
            expectedCurrency: "AED",
            expectedCategory: "Food & Dining"
        ),

        // EUR variations
        VoiceCommandTestCase(
            input: "I spent 45 euros on entertainment",
            expectedAmount: 45.0,
            expectedCurrency: "EUR",
            expectedCategory: "Entertainment"
        ),
        VoiceCommandTestCase(
            input: "€30 for shopping",
            expectedAmount: 30.0,
            expectedCurrency: "EUR",
            expectedCategory: "Shopping"
        ),

        // GBP variations
        VoiceCommandTestCase(
            input: "I spent 20 pounds on transport",
            expectedAmount: 20.0,
            expectedCurrency: "GBP",
            expectedCategory: "Transportation"
        ),
        VoiceCommandTestCase(
            input: "£15.50 at the grocery store",
            expectedAmount: 15.50,
            expectedCurrency: "GBP",
            expectedCategory: "Grocery"
        ),

        // INR variations
        VoiceCommandTestCase(
            input: "I spent 500 rupees on groceries",
            expectedAmount: 500.0,
            expectedCurrency: "INR",
            expectedCategory: "Grocery"
        ),

        // SAR variations
        VoiceCommandTestCase(
            input: "I spent 100 riyals on shopping",
            expectedAmount: 100.0,
            expectedCurrency: "SAR",
            expectedCategory: "Shopping"
        ),

        // No currency (should use default)
        VoiceCommandTestCase(
            input: "I spent 75 on groceries",
            expectedAmount: 75.0,
            expectedCurrency: nil, // Will use default
            expectedCategory: "Grocery"
        )
    ]

    // MARK: - Currency Formatting Test Data

    /// Test cases for currency formatting
    static let formattingTestCases: [CurrencyFormattingTestCase] = [
        // AED
        CurrencyFormattingTestCase(
            amount: Decimal(150.50),
            currency: .aed,
            expectedWithSymbol: "د.إ 150.50",
            expectedCompact: "د.إ 150.50"
        ),

        // USD
        CurrencyFormattingTestCase(
            amount: Decimal(1234.56),
            currency: .usd,
            expectedWithSymbol: "$1,234.56",
            expectedCompact: "$1,234.56"
        ),

        // EUR
        CurrencyFormattingTestCase(
            amount: Decimal(999.99),
            currency: .eur,
            expectedWithSymbol: "€999.99",
            expectedCompact: "€999.99"
        ),

        // GBP
        CurrencyFormattingTestCase(
            amount: Decimal(50.00),
            currency: .gbp,
            expectedWithSymbol: "£50.00",
            expectedCompact: "£50.00"
        ),

        // Zero amount
        CurrencyFormattingTestCase(
            amount: Decimal(0.00),
            currency: .aed,
            expectedWithSymbol: "د.إ 0.00",
            expectedCompact: "د.إ 0.00"
        ),

        // Large amount
        CurrencyFormattingTestCase(
            amount: Decimal(1000000.00),
            currency: .usd,
            expectedWithSymbol: "$1,000,000.00",
            expectedCompact: "$1,000,000.00"
        )
    ]
}

// MARK: - Test Case Structures

/// Voice command test case
struct VoiceCommandTestCase {
    let input: String
    let expectedAmount: Double
    let expectedCurrency: String?
    let expectedCategory: String
    let expectedMerchant: String?

    init(input: String, expectedAmount: Double, expectedCurrency: String?, expectedCategory: String, expectedMerchant: String? = nil) {
        self.input = input
        self.expectedAmount = expectedAmount
        self.expectedCurrency = expectedCurrency
        self.expectedCategory = expectedCategory
        self.expectedMerchant = expectedMerchant
    }
}

/// Currency formatting test case
struct CurrencyFormattingTestCase {
    let amount: Decimal
    let currency: Currency
    let expectedWithSymbol: String
    let expectedCompact: String
}
