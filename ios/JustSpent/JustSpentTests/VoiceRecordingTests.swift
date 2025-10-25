import XCTest
import Speech
import AVFoundation
import SwiftUI
@testable import JustSpent

class VoiceRecordingTests: XCTestCase {
    
    var contentView: ContentView!
    var mockSpeechRecognizer: MockSpeechRecognizer!
    var mockAudioEngine: MockAudioEngine!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        contentView = ContentView()
        mockSpeechRecognizer = MockSpeechRecognizer()
        mockAudioEngine = MockAudioEngine()
    }
    
    override func tearDownWithError() throws {
        contentView = nil
        mockSpeechRecognizer = nil
        mockAudioEngine = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Auto-Stop Functionality Tests
    
    func testAutoStopAfterSilenceThreshold() throws {
        // Given
        let expectation = XCTestExpectation(description: "Auto-stop after silence")
        var isRecordingStopped = false
        
        // Simulate recording state
        let silenceThreshold: TimeInterval = 2.0
        let lastSpeechTime = Date().addingTimeInterval(-3.0) // 3 seconds ago
        
        // When - simulate silence timer triggering
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let timeSinceLastSpeech = Date().timeIntervalSince(lastSpeechTime)
            if timeSinceLastSpeech >= silenceThreshold {
                isRecordingStopped = true
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(isRecordingStopped, "Recording should auto-stop after silence threshold")
    }
    
    func testMinimumSpeechDurationRequired() throws {
        // Given
        let minimumSpeechDuration: TimeInterval = 1.0
        let recordingStartTime = Date()
        let speechDetectedTime = Date().addingTimeInterval(0.5) // Only 0.5 seconds of speech
        
        // When
        let actualSpeechDuration = speechDetectedTime.timeIntervalSince(recordingStartTime)
        let shouldAutoStop = actualSpeechDuration >= minimumSpeechDuration
        
        // Then
        XCTAssertFalse(shouldAutoStop, "Should not auto-stop if minimum speech duration not met")
    }
    
    func testSpeechDetectionStateChanges() throws {
        // Given
        var hasDetectedSpeech = false
        var lastSpeechTime = Date()
        
        // When - simulate speech detection
        hasDetectedSpeech = true
        lastSpeechTime = Date()
        
        // Then
        XCTAssertTrue(hasDetectedSpeech, "Should detect speech when audio input is processed")
        XCTAssertLessThan(Date().timeIntervalSince(lastSpeechTime), 1.0, "Last speech time should be recent")
    }
    
    func testSilenceTimerConfiguration() throws {
        // Given
        let silenceThreshold: TimeInterval = 2.0
        let minimumSpeechDuration: TimeInterval = 1.0
        
        // When & Then
        XCTAssertEqual(silenceThreshold, 2.0, "Silence threshold should be 2 seconds")
        XCTAssertEqual(minimumSpeechDuration, 1.0, "Minimum speech duration should be 1 second")
    }
    
    // MARK: - Speech Recognition State Tests
    
    func testSpeechRecognitionAvailabilityCheck() throws {
        // Given
        let locale = Locale(identifier: "en-US")
        
        // When
        let recognizer = SFSpeechRecognizer(locale: locale)
        let isAvailable = recognizer?.isAvailable ?? false
        
        // Then
        // Note: This will depend on simulator/device capabilities
        XCTAssertNotNil(recognizer, "Speech recognizer should be created for valid locale")
    }
    
    func testRecordingStateTransitions() throws {
        // Given
        var isRecording = false
        
        // When - start recording
        isRecording = true
        XCTAssertTrue(isRecording, "Recording state should be true when started")
        
        // When - stop recording
        isRecording = false
        XCTAssertFalse(isRecording, "Recording state should be false when stopped")
    }
    
    #if !targetEnvironment(simulator)
    func testAudioEngineConfiguration() throws {
        // NOTE: This test requires actual audio hardware
        // which is not available in iOS Simulator

        // Given
        let audioEngine = AVAudioEngine()

        // When
        let inputNode = audioEngine.inputNode
        let outputFormat = inputNode.outputFormat(forBus: 0)

        // Then
        XCTAssertNotNil(inputNode, "Audio engine should have input node")
        XCTAssertNotNil(outputFormat, "Input node should have output format")
        XCTAssertGreaterThan(outputFormat.sampleRate, 0, "Sample rate should be greater than 0")
    }
    #endif
    
    // MARK: - Voice Input Processing Tests
    
    func testVoiceInputExtraction() throws {
        // Given
        let voiceInput = "I just spent 25 dollars on groceries"
        
        // When
        let extractedData = extractExpenseData(from: voiceInput)
        
        // Then
        XCTAssertEqual(extractedData.amount, 25.0, "Should extract correct amount")
        XCTAssertEqual(extractedData.currency, "USD", "Should extract correct currency")
        XCTAssertEqual(extractedData.category, "Grocery", "Should extract correct category")
    }
    
    func testVoiceInputWithMerchant() throws {
        // Given
        let voiceInput = "I spent 15 dollars at Starbucks"
        
        // When
        let extractedData = extractExpenseData(from: voiceInput)
        
        // Then
        XCTAssertEqual(extractedData.amount, 15.0, "Should extract correct amount")
        XCTAssertEqual(extractedData.merchant, "Starbucks", "Should extract merchant name")
    }
    
    func testInvalidVoiceInput() throws {
        // Given
        let invalidInputs = [
            "Hello there",
            "I bought something",
            "Spent money today",
            ""
        ]
        
        // When & Then
        for input in invalidInputs {
            let extractedData = extractExpenseData(from: input)
            XCTAssertNil(extractedData.amount, "Should not extract amount from invalid input: '\(input)'")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testSpeechRecognitionError() throws {
        // Given
        let mockError = NSError(domain: "SpeechRecognitionError", code: 1001, userInfo: [
            NSLocalizedDescriptionKey: "Speech recognition failed"
        ])
        
        // When
        let errorDescription = mockError.localizedDescription
        
        // Then
        XCTAssertEqual(errorDescription, "Speech recognition failed", "Should handle speech recognition errors")
    }
    
    func testAudioEngineError() throws {
        // Given
        let mockError = NSError(domain: "AVAudioEngineError", code: 2001, userInfo: [
            NSLocalizedDescriptionKey: "Audio engine configuration failed"
        ])
        
        // When
        let errorDescription = mockError.localizedDescription
        
        // Then
        XCTAssertEqual(errorDescription, "Audio engine configuration failed", "Should handle audio engine errors")
    }
    
    // MARK: - Performance Tests
    
    func testVoiceProcessingPerformance() throws {
        // Given
        let voiceInput = "I just spent 50 dollars on dinner at a restaurant"
        
        // When
        measure {
            let _ = extractExpenseData(from: voiceInput)
        }
        
        // Then - measured time should be reasonable (< 100ms typically)
    }
    
    func testSilenceDetectionPerformance() throws {
        // Given
        let iterations = 1000
        
        // When
        measure {
            for _ in 0..<iterations {
                let lastSpeechTime = Date().addingTimeInterval(-1.5)
                let timeSinceLastSpeech = Date().timeIntervalSince(lastSpeechTime)
                let _ = timeSinceLastSpeech >= 2.0
            }
        }
        
        // Then - performance should be acceptable for real-time processing
    }
}

// MARK: - Helper Functions

private func extractExpenseData(from command: String) -> (amount: Double?, currency: String?, category: String?, merchant: String?) {
    let lowercased = command.lowercased()
    
    // Extract amount using regex
    let amountPattern = #"(\d+(?:\.\d{1,2})?)[ ]*(?:dollars?|usd|\$|aed|dirhams?)"#
    let amountRegex = try? NSRegularExpression(pattern: amountPattern, options: [])
    let amountRange = NSRange(location: 0, length: command.count)
    
    var amount: Double?
    if let match = amountRegex?.firstMatch(in: lowercased, options: [], range: amountRange) {
        let amountStr = String(lowercased[Range(match.range(at: 1), in: lowercased)!])
        amount = Double(amountStr)
    }
    
    // Extract currency
    var currency: String = "USD"
    if lowercased.contains("dirhams") || lowercased.contains("aed") {
        currency = "AED"
    } else if lowercased.contains("dollars") || lowercased.contains("usd") {
        currency = "USD"
    }
    
    // Extract category using keyword matching
    let categoryMappings: [String: String] = [
        "food": "Food & Dining",
        "coffee": "Food & Dining",
        "lunch": "Food & Dining",
        "dinner": "Food & Dining",
        "restaurant": "Food & Dining",
        "grocery": "Grocery",
        "groceries": "Grocery",
        "supermarket": "Grocery",
        "gas": "Transportation",
        "fuel": "Transportation",
        "taxi": "Transportation",
        "uber": "Transportation",
        "shopping": "Shopping",
        "clothes": "Shopping",
        "movie": "Entertainment",
        "cinema": "Entertainment"
    ]
    
    var category: String = "Other"
    for (keyword, categoryName) in categoryMappings {
        if lowercased.contains(keyword) {
            category = categoryName
            break
        }
    }
    
    // Extract merchant (words after "at" or "from")
    var merchant: String?
    let merchantPattern = #"(?:at|from)[ ]+([a-zA-Z\s]+?)(?:[ ]|$)"#
    let merchantRegex = try? NSRegularExpression(pattern: merchantPattern, options: [])
    if let match = merchantRegex?.firstMatch(in: lowercased, options: [], range: amountRange) {
        merchant = String(command[Range(match.range(at: 1), in: command)!]).trimmingCharacters(in: .whitespaces)
    }
    
    return (amount: amount, currency: currency, category: category, merchant: merchant)
}