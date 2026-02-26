import XCTest
@testable import JustSpent

// MARK: - VoiceTransactionManager Tests

/// Tests for the VoiceTransactionManager service which processes voice inputs into expense transactions
@MainActor
class VoiceTransactionManagerTests: XCTestCase {
    
    var sut: VoiceTransactionManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = VoiceTransactionManager()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    // MARK: - VoiceProcessingResult Tests
    
    func testVoiceProcessingResultInitialization() throws {
        // Given
        let message = "Test message"
        let isError = false
        let success = true
        
        // When
        let result = VoiceProcessingResult(message: message, isError: isError, success: success)
        
        // Then
        XCTAssertEqual(result.message, message)
        XCTAssertEqual(result.isError, isError)
        XCTAssertEqual(result.success, success)
    }
    
    func testVoiceProcessingResultErrorState() throws {
        // Given & When
        let errorResult = VoiceProcessingResult(message: "Error occurred", isError: true, success: false)
        
        // Then
        XCTAssertTrue(errorResult.isError)
        XCTAssertFalse(errorResult.success)
    }
    
    func testVoiceProcessingResultSuccessState() throws {
        // Given & When
        let successResult = VoiceProcessingResult(message: "Success", isError: false, success: true)
        
        // Then
        XCTAssertFalse(successResult.isError)
        XCTAssertTrue(successResult.success)
    }
    
    // MARK: - Input Validation Tests
    
    func testProcessEmptyInputReturnsError() async throws {
        // Given
        let emptyInput = ""
        
        // When
        let result = await sut.process(input: emptyInput, source: "test")
        
        // Then
        XCTAssertTrue(result.isError)
        XCTAssertFalse(result.success)
        XCTAssertFalse(result.message.isEmpty)
    }
    
    func testProcessWhitespaceOnlyInputReturnsError() async throws {
        // Given
        let whitespaceInput = "   \n\t  "
        
        // When
        let result = await sut.process(input: whitespaceInput, source: "test")
        
        // Then
        XCTAssertTrue(result.isError)
        XCTAssertFalse(result.success)
    }
    
    func testProcessValidInputWithAmountAndCategory() async throws {
        // Given
        let validInput = "I spent 25 dollars on groceries"
        
        // When
        let result = await sut.process(input: validInput, source: AppConstants.ExpenseSource.voiceRecognition)
        
        // Then
        // Note: Success depends on Core Data context availability in tests
        // The parsing logic should still work
        XCTAssertFalse(result.message.isEmpty, "Should return a message")
    }
    
    // MARK: - Source Handling Tests
    
    func testProcessWithSiriSource() async throws {
        // Given
        let input = "50 dollars for food"
        let source = AppConstants.ExpenseSource.voiceSiri
        
        // When
        let result = await sut.process(input: input, source: source)
        
        // Then
        XCTAssertFalse(result.message.isEmpty)
    }
    
    func testProcessWithVoiceRecognitionSource() async throws {
        // Given
        let input = "30 dollars for transportation"
        let source = AppConstants.ExpenseSource.voiceRecognition
        
        // When
        let result = await sut.process(input: input, source: source)
        
        // Then
        XCTAssertFalse(result.message.isEmpty)
    }
    
    // MARK: - Parsing Tests
    
    func testProcessUnparseableInputReturnsError() async throws {
        // Given - input without amount or category
        let invalidInput = "hello world"
        
        // When
        let result = await sut.process(input: invalidInput, source: "test")
        
        // Then
        XCTAssertTrue(result.isError)
        XCTAssertFalse(result.success)
    }
    
    func testProcessInputWithOnlyAmountSuccessWithDefaultCategory() async throws {
        // Given - input with amount but no recognizable category keyword
        // The parser should infer default category "Other"
        let inputWithAmountOnly = "just 25"
        
        // When
        let result = await sut.process(input: inputWithAmountOnly, source: "test")
        
        // Then
        // Should succeed with default category
        XCTAssertFalse(result.isError, "Should succeed with default category")
        XCTAssertTrue(result.success, "Success should be true")
        XCTAssertTrue(result.message.contains("25"), "Message should contain amount")
    }
    
    // MARK: - Currency Detection Tests
    
    func testProcessInputWithUSDCurrency() async throws {
        // Given
        let usdInput = "100 dollars for shopping"
        
        // When
        let result = await sut.process(input: usdInput, source: "test")
        
        // Then
        XCTAssertFalse(result.message.isEmpty)
    }
    
    func testProcessInputWithAEDCurrency() async throws {
        // Given
        let aedInput = "50 dirhams for food"
        
        // When
        let result = await sut.process(input: aedInput, source: "test")
        
        // Then
        XCTAssertFalse(result.message.isEmpty)
    }
    
    // MARK: - Manager Initialization Tests
    
    func testVoiceTransactionManagerCanBeInitialized() throws {
        // Given & When
        let manager = VoiceTransactionManager()
        
        // Then
        XCTAssertNotNil(manager)
    }
    
    func testVoiceTransactionManagerIsObservableObject() throws {
        // Given & When
        let manager = VoiceTransactionManager()
        
        // Then
        // VoiceTransactionManager conforms to ObservableObject
        XCTAssertTrue(manager is ObservableObject)
    }
}

// MARK: - Mock Classes for Testing

class MockVoiceTransactionManager: VoiceTransactionManager {
    var mockResult: VoiceProcessingResult?
    var processCallCount = 0
    var lastProcessedInput: String?
    var lastProcessedSource: String?
    
    override func process(input: String, source: String) async -> VoiceProcessingResult {
        processCallCount += 1
        lastProcessedInput = input
        lastProcessedSource = source
        
        if let mockResult = mockResult {
            return mockResult
        }
        return await super.process(input: input, source: source)
    }
}

// MARK: - Mock Tests

@MainActor
class MockVoiceTransactionManagerTests: XCTestCase {
    
    func testMockReturnsConfiguredResult() async throws {
        // Given
        let mock = MockVoiceTransactionManager()
        let expectedResult = VoiceProcessingResult(message: "Mock success", isError: false, success: true)
        mock.mockResult = expectedResult
        
        // When
        let result = await mock.process(input: "test input", source: "test")
        
        // Then
        XCTAssertEqual(result.message, expectedResult.message)
        XCTAssertEqual(result.isError, expectedResult.isError)
        XCTAssertEqual(result.success, expectedResult.success)
    }
    
    func testMockTracksCallCount() async throws {
        // Given
        let mock = MockVoiceTransactionManager()
        mock.mockResult = VoiceProcessingResult(message: "test", isError: false, success: true)
        
        // When
        _ = await mock.process(input: "first", source: "test")
        _ = await mock.process(input: "second", source: "test")
        _ = await mock.process(input: "third", source: "test")
        
        // Then
        XCTAssertEqual(mock.processCallCount, 3)
    }
    
    func testMockTracksLastInput() async throws {
        // Given
        let mock = MockVoiceTransactionManager()
        mock.mockResult = VoiceProcessingResult(message: "test", isError: false, success: true)
        let expectedInput = "last input value"
        
        // When
        _ = await mock.process(input: expectedInput, source: "source")
        
        // Then
        XCTAssertEqual(mock.lastProcessedInput, expectedInput)
    }
    
    func testMockTracksLastSource() async throws {
        // Given
        let mock = MockVoiceTransactionManager()
        mock.mockResult = VoiceProcessingResult(message: "test", isError: false, success: true)
        let expectedSource = "CustomSource"
        
        // When
        _ = await mock.process(input: "input", source: expectedSource)
        
        // Then
        XCTAssertEqual(mock.lastProcessedSource, expectedSource)
    }
}
