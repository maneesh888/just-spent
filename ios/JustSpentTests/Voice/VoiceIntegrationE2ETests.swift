import XCTest
import Intents
@testable import JustSpent

// MARK: - ⚠️ DISABLED - Requires Intent Definition File
// This test file requires a JustSpent.intentdefinition file to be created with:
// - LogExpenseIntent custom intent
// - ViewExpensesIntent custom intent
// - ExpenseCategory enum
// - LogExpenseIntentHandler
// - ViewExpensesIntentHandler
// - SharedDataManager
// See: ios-siri-integration.md for setup instructions
//
// Additionally, this file uses:
// - ShortcutsManager which is also commented out pending intentdefinition
// - Hardcoded .voiceSiri on line 354 (should use AppConstants.ExpenseSource.voiceSiri)

/*
/**
 * End-to-end tests for iOS Siri voice integration
 * Tests the complete flow from Siri intent to expense logging
 */
class VoiceIntegrationE2ETests: XCTestCase {
    
    var intentHandler: LogExpenseIntentHandler!
    var sharedDataManager: SharedDataManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        intentHandler = LogExpenseIntentHandler()
        sharedDataManager = SharedDataManager.shared
        
        // Clean up any existing test data
        try cleanupTestData()
    }
    
    override func tearDownWithError() throws {
        try cleanupTestData()
        try super.tearDownWithError()
    }
    
    // MARK: - Basic Intent Handling Tests
    
    func testSimpleExpenseIntent_LogsSuccessfully() throws {
        // Arrange
        let intent = LogExpenseIntent()
        intent.amount = NSDecimalNumber(value: 50.0)
        intent.category = .foodDining
        intent.currency = "USD"
        intent.merchant = "Starbucks"
        
        let expectation = XCTestExpectation(description: "Intent processed")
        
        // Act
        intentHandler.handle(intent: intent) { response in
            // Assert
            XCTAssertEqual(response.code, .success)
            XCTAssertEqual(response.amount, NSDecimalNumber(value: 50.0))
            XCTAssertEqual(response.category, .foodDining)
            XCTAssertEqual(response.merchant, "Starbucks")
            XCTAssertNotNil(response.userActivity)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Verify data was saved
        let expenses = try sharedDataManager.fetchExpenses(category: "Food & Dining", timePeriod: nil)
        XCTAssertEqual(expenses.count, 1)
        XCTAssertEqual(expenses.first?.amount, NSDecimalNumber(value: 50.0))
        XCTAssertEqual(expenses.first?.merchant, "Starbucks")
    }
    
    func testInvalidAmountIntent_ReturnsFailure() throws {
        // Arrange
        let intent = LogExpenseIntent()
        intent.amount = NSDecimalNumber(value: -10.0) // Invalid negative amount
        intent.category = .foodDining
        
        let expectation = XCTestExpectation(description: "Intent processed")
        
        // Act
        intentHandler.handle(intent: intent) { response in
            // Assert
            XCTAssertEqual(response.code, .failure)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMissingAmountIntent_ReturnsFailure() throws {
        // Arrange
        let intent = LogExpenseIntent()
        intent.category = .foodDining
        // No amount set
        
        let expectation = XCTestExpectation(description: "Intent processed")
        
        // Act
        intentHandler.handle(intent: intent) { response in
            // Assert
            XCTAssertEqual(response.code, .failure)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Parameter Resolution Tests
    
    func testAmountResolution_ValidAmount_ReturnsSuccess() throws {
        // Arrange
        let intent = LogExpenseIntent()
        intent.amount = NSDecimalNumber(value: 25.50)
        
        let expectation = XCTestExpectation(description: "Amount resolved")
        
        // Act
        intentHandler.resolveAmount(for: intent) { result in
            // Assert
            switch result {
            case .success(let amount):
                XCTAssertEqual(amount, NSDecimalNumber(value: 25.50))
            default:
                XCTFail("Expected success result")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAmountResolution_InvalidAmount_ReturnsUnsupported() throws {
        // Arrange
        let intent = LogExpenseIntent()
        intent.amount = NSDecimalNumber(value: 1000000.0) // Exceeds maximum
        
        let expectation = XCTestExpectation(description: "Amount resolved")
        
        // Act
        intentHandler.resolveAmount(for: intent) { result in
            // Assert
            switch result {
            case .unsupported:
                break // Expected
            default:
                XCTFail("Expected unsupported result")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCategoryResolution_ValidCategory_ReturnsSuccess() throws {
        // Arrange
        let intent = LogExpenseIntent()
        intent.category = .grocery
        
        let expectation = XCTestExpectation(description: "Category resolved")
        
        // Act
        intentHandler.resolveCategory(for: intent) { result in
            // Assert
            switch result {
            case .success(let category):
                XCTAssertEqual(category, .grocery)
            default:
                XCTFail("Expected success result")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMerchantResolution_ValidMerchant_ReturnsSuccess() throws {
        // Arrange
        let intent = LogExpenseIntent()
        intent.merchant = "Apple Store"
        
        let expectation = XCTestExpectation(description: "Merchant resolved")
        
        // Act
        intentHandler.resolveMerchant(for: intent) { result in
            // Assert
            switch result {
            case .success(let merchant):
                XCTAssertEqual(merchant, "Apple Store")
            default:
                XCTFail("Expected success result")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMerchantResolution_TooLongMerchant_ReturnsUnsupported() throws {
        // Arrange
        let intent = LogExpenseIntent()
        intent.merchant = String(repeating: "a", count: 150) // Exceeds limit
        
        let expectation = XCTestExpectation(description: "Merchant resolved")
        
        // Act
        intentHandler.resolveMerchant(for: intent) { result in
            // Assert
            switch result {
            case .unsupported:
                break // Expected
            default:
                XCTFail("Expected unsupported result")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCurrencyResolution_SupportedCurrency_ReturnsSuccess() throws {
        // Arrange
        let intent = LogExpenseIntent()
        intent.currency = "AED"
        
        let expectation = XCTestExpectation(description: "Currency resolved")
        
        // Act
        intentHandler.resolveCurrency(for: intent) { result in
            // Assert
            switch result {
            case .success(let currency):
                XCTAssertEqual(currency, "AED")
            default:
                XCTFail("Expected success result")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCurrencyResolution_UnsupportedCurrency_ReturnsDefault() throws {
        // Arrange
        let intent = LogExpenseIntent()
        intent.currency = "XYZ" // Unsupported
        
        let expectation = XCTestExpectation(description: "Currency resolved")
        
        // Act
        intentHandler.resolveCurrency(for: intent) { result in
            // Assert
            switch result {
            case .success(let currency):
                XCTAssertEqual(currency, "USD") // Falls back to default
            default:
                XCTFail("Expected success result with default currency")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Multi-Currency Tests
    
    func testMultiCurrencySupport_AED() throws {
        let currencies = ["AED", "USD", "EUR", "GBP", "INR", "SAR"]
        
        for currency in currencies {
            // Arrange
            let intent = LogExpenseIntent()
            intent.amount = NSDecimalNumber(value: 100.0)
            intent.category = .grocery
            intent.currency = currency
            
            let expectation = XCTestExpectation(description: "Intent processed for \(currency)")
            
            // Act
            intentHandler.handle(intent: intent) { response in
                // Assert
                XCTAssertEqual(response.code, .success)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
        
        // Verify all currencies were saved
        let expenses = try sharedDataManager.fetchExpenses(category: nil, timePeriod: nil)
        XCTAssertEqual(expenses.count, currencies.count)
        
        let savedCurrencies = Set(expenses.compactMap { $0.currency })
        XCTAssertEqual(savedCurrencies, Set(currencies))
    }
    
    // MARK: - Category Mapping Tests
    
    func testCategoryMapping_AllCategories() throws {
        let categoryMappings: [(ExpenseCategory, String)] = [
            (.foodDining, "Food & Dining"),
            (.grocery, "Grocery"),
            (.transportation, "Transportation"),
            (.shopping, "Shopping"),
            (.entertainment, "Entertainment"),
            (.billsUtilities, "Bills & Utilities"),
            (.healthcare, "Healthcare"),
            (.education, "Education"),
            (.other, "Other")
        ]
        
        for (category, expectedString) in categoryMappings {
            // Arrange
            let intent = LogExpenseIntent()
            intent.amount = NSDecimalNumber(value: 10.0)
            intent.category = category
            
            let expectation = XCTestExpectation(description: "Category \(category) processed")
            
            // Act
            intentHandler.handle(intent: intent) { response in
                // Assert
                XCTAssertEqual(response.code, .success)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
            
            // Verify category was mapped correctly
            let expenses = try sharedDataManager.fetchExpenses(category: expectedString, timePeriod: nil)
            XCTAssertGreaterThan(expenses.count, 0, "No expenses found for category \(expectedString)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testIntentProcessingPerformance() throws {
        measure {
            let intent = LogExpenseIntent()
            intent.amount = NSDecimalNumber(value: 25.0)
            intent.category = .foodDining
            intent.currency = "USD"
            
            let expectation = XCTestExpectation(description: "Performance test")
            
            intentHandler.handle(intent: intent) { response in
                XCTAssertEqual(response.code, .success)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    // MARK: - View Expenses Intent Tests
    
    func testViewExpensesIntent_Success() throws {
        // First add some test data
        let expenseData = ExpenseData(
            amount: NSDecimalNumber(value: 50.0),
            currency: "USD",
            category: "Food & Dining",
            merchant: "Test Restaurant",
            notes: "Test expense",
            transactionDate: Date(),
            source: .voiceSiri,
            voiceTranscript: "Test command"
        )
        _ = try sharedDataManager.saveExpense(expenseData)
        
        // Arrange
        let viewIntent = ViewExpensesIntent()
        viewIntent.category = .foodDining
        viewIntent.timePeriod = "today"
        
        let viewHandler = ViewExpensesIntentHandler()
        let expectation = XCTestExpectation(description: "View intent processed")
        
        // Act
        viewHandler.handle(intent: viewIntent) { response in
            // Assert
            XCTAssertEqual(response.code, .success)
            XCTAssertNotNil(response.userActivity)
            
            if let userInfo = response.userActivity?.userInfo {
                XCTAssertEqual(userInfo["category"] as? String, "Food & Dining")
                XCTAssertEqual(userInfo["timePeriod"] as? String, "today")
                XCTAssertGreaterThan(userInfo["expenseCount"] as? Int ?? 0, 0)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Helper Methods
    
    private func cleanupTestData() throws {
        let context = sharedDataManager.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Expense.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try context.execute(deleteRequest)
        try context.save()
    }
}

// MARK: - Shortcuts Integration Tests

extension VoiceIntegrationE2ETests {
    
    func testShortcutDonation_Success() throws {
        // Arrange
        let shortcutsManager = ShortcutsManager.shared
        let amount = NSDecimalNumber(value: 25.0)
        let category = ExpenseCategory.foodDining
        let merchant = "Coffee Shop"
        
        // Act
        shortcutsManager.donateLogExpenseShortcut(
            amount: amount,
            category: category,
            merchant: merchant
        )
        
        // Wait for donation to complete
        let expectation = XCTestExpectation(description: "Shortcut donated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // Note: In a real test environment, you would verify the shortcut
        // was created, but iOS doesn't provide APIs to query shortcuts
        // This test mainly ensures no crashes occur during donation
    }
    
    func testVoiceTrainingPhrases_ReturnsValidPhrases() throws {
        // Arrange
        let shortcutsManager = ShortcutsManager.shared
        
        // Act
        let phrases = shortcutsManager.getVoiceTrainingPhrases()
        
        // Assert
        XCTAssertGreaterThan(phrases.count, 0)
        XCTAssertTrue(phrases.contains { $0.contains("spent") })
        XCTAssertTrue(phrases.contains { $0.contains("dollars") || $0.contains("AED") })
    }
    
    func testLocalizedPhrases_UAE() throws {
        // Arrange
        let shortcutsManager = ShortcutsManager.shared
        let uaeLocale = Locale(identifier: "en_AE")
        
        // Act
        let phrases = shortcutsManager.getLocalizedPhrases(for: uaeLocale)
        
        // Assert
        XCTAssertGreaterThan(phrases.count, 0)
        XCTAssertTrue(phrases.contains { $0.contains("AED") || $0.contains("dirhams") })
    }
}

// MARK: - Error Handling Tests

extension VoiceIntegrationE2ETests {
    
    func testCoreDataError_HandledGracefully() throws {
        // This test would require mocking Core Data to simulate failures
        // For now, we test that normal operations don't crash
        
        let intent = LogExpenseIntent()
        intent.amount = NSDecimalNumber(value: 10.0)
        intent.category = .other
        
        let expectation = XCTestExpectation(description: "Error handled")
        
        intentHandler.handle(intent: intent) { response in
            // Should not crash, even if there are underlying issues
            XCTAssertNotNil(response)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}
*/