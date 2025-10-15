import XCTest
import Speech
import AVFoundation
@testable import JustSpent

/**
 * Test Suite Configuration for Just Spent Voice Recording Features
 * 
 * This file provides test configuration, utilities, and documentation for the comprehensive
 * test suite covering the voice recording and permission management improvements implemented
 * in the last development iteration.
 *
 * Test Coverage Areas:
 * 1. Voice Recording Auto-Stop Functionality
 * 2. Permission Management Flow
 * 3. Floating Action Button UI Behavior
 * 4. Speech Recognition Edge Cases
 */

// MARK: - Test Configuration

class TestSuiteConfiguration {
    
    // MARK: - Test Constants
    
    struct TestConstants {
        // Voice Recording
        static let silenceThreshold: TimeInterval = 2.0
        static let minimumSpeechDuration: TimeInterval = 1.0
        static let voiceProcessingTimeout: TimeInterval = 10.0
        
        // Permission Testing
        static let permissionRequestTimeout: TimeInterval = 5.0
        static let settingsTransitionDelay: TimeInterval = 0.5
        
        // UI Testing
        static let floatingButtonIdentifier = "voice_recording_button"
        static let uiAnimationTimeout: TimeInterval = 2.0
        static let appLaunchTimeout: TimeInterval = 10.0
        
        // Performance Benchmarks
        static let maxVoiceProcessingTime: TimeInterval = 0.1 // 100ms
        static let maxSilenceDetectionTime: TimeInterval = 0.01 // 10ms
        static let maxUIUpdateTime: TimeInterval = 0.016 // 16ms for 60fps
    }
    
    struct TestData {
        // Valid expense inputs
        static let validExpenseInputs = [
            "I just spent 25 dollars on groceries",
            "Paid 50 dirhams for gas",
            "Cost me 15 dollars at Starbucks",
            "I spent 100 dollars shopping",
            "Paid 30 dollars for lunch"
        ]
        
        // Invalid/edge case inputs
        static let invalidInputs = [
            "", // Empty
            "   ", // Whitespace
            "Hello there", // No expense data
            "I bought something", // Vague
            "Spent money today" // No amount
        ]
        
        // Multi-currency inputs
        static let multiCurrencyInputs = [
            ("I spent 50 dollars", "USD", 50.0),
            ("Paid 100 dirhams", "AED", 100.0),
            ("Cost 75 euros", "EUR", 75.0),
            ("I spent 25 pounds", "GBP", 25.0)
        ]
        
        // Category test cases
        static let categoryTestCases = [
            ("coffee at Starbucks", "Food & Dining"),
            ("gas for car", "Transportation"),
            ("groceries at supermarket", "Grocery"),
            ("movie tickets", "Entertainment"),
            ("electricity bill", "Bills & Utilities")
        ]
    }
    
    // MARK: - Test Environment Setup
    
    static func setupTestEnvironment() {
        // Configure test environment
        UserDefaults.standard.set(true, forKey: "isTestEnvironment")
        
        // Set test-specific configurations
        UserDefaults.standard.set(TestConstants.silenceThreshold, forKey: "testSilenceThreshold")
        UserDefaults.standard.set(TestConstants.minimumSpeechDuration, forKey: "testMinimumSpeechDuration")
        
        // Disable analytics for testing
        UserDefaults.standard.set(false, forKey: "analyticsEnabled")
        
        print("🧪 Test environment configured")
    }
    
    static func tearDownTestEnvironment() {
        // Clean up test configurations
        UserDefaults.standard.removeObject(forKey: "isTestEnvironment")
        UserDefaults.standard.removeObject(forKey: "testSilenceThreshold")
        UserDefaults.standard.removeObject(forKey: "testMinimumSpeechDuration")
        UserDefaults.standard.removeObject(forKey: "analyticsEnabled")
        
        print("🧪 Test environment cleaned up")
    }
}

// MARK: - Test Utilities

class TestUtilities {
    
    // MARK: - Speech Recognition Mocking
    
    static func createMockSpeechResult(text: String, confidence: Float = 0.9) -> [String: Any] {
        return [
            "text": text,
            "confidence": confidence,
            "timestamp": Date().timeIntervalSince1970
        ]
    }
    
    static func simulateVoiceInput(_ input: String, completion: @escaping (String) -> Void) {
        // Simulate speech recognition delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion(input)
        }
    }
    
    // MARK: - Permission Testing Utilities
    
    static func getCurrentPermissionStates() -> (speech: SFSpeechRecognizerAuthorizationStatus, microphone: AVAudioSession.RecordPermission) {
        return (
            SFSpeechRecognizer.authorizationStatus(),
            AVAudioSession.sharedInstance().recordPermission
        )
    }
    
    static func isVoiceFeatureAvailable() -> Bool {
        let (speechStatus, micStatus) = getCurrentPermissionStates()
        let recognizerAvailable = SFSpeechRecognizer()?.isAvailable ?? false
        
        return speechStatus == .authorized && micStatus == .granted && recognizerAvailable
    }
    
    // MARK: - UI Testing Utilities
    
    static func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5.0) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    static func tapElementSafely(_ element: XCUIElement) -> Bool {
        guard element.exists && element.isHittable else { return false }
        element.tap()
        return true
    }
    
    static func dismissAnyActiveAlerts(in app: XCUIApplication) {
        let alert = app.alerts.firstMatch
        if alert.exists {
            let cancelButton = alert.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            } else {
                alert.buttons.firstMatch.tap()
            }
        }
    }
    
    // MARK: - Performance Testing Utilities
    
    static func measureExecutionTime<T>(operation: () -> T) -> (result: T, executionTime: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = operation()
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        return (result, executionTime)
    }
    
    static func performanceTest<T>(
        operation: () -> T,
        maxExecutionTime: TimeInterval,
        operationName: String
    ) -> Bool {
        let (_, executionTime) = measureExecutionTime(operation: operation)
        let passed = executionTime <= maxExecutionTime
        
        print("⏱️ \(operationName): \(String(format: "%.3f", executionTime))s (max: \(maxExecutionTime)s) - \(passed ? "PASS" : "FAIL")")
        
        return passed
    }
}

// MARK: - Mock Objects for Testing

class MockSpeechRecognizer {
    var isAvailable = true
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    var mockResults: [String] = []
    var currentResultIndex = 0
    
    func simulateRecognition() -> String? {
        guard currentResultIndex < mockResults.count else { return nil }
        let result = mockResults[currentResultIndex]
        currentResultIndex += 1
        return result
    }
    
    func reset() {
        currentResultIndex = 0
    }
    
    func addMockResult(_ text: String) {
        mockResults.append(text)
    }
}

class MockAudioEngine {
    var isRunning = false
    var mockInputLevel: Float = 0.0
    var simulateError: Error?
    
    func simulateStart() throws {
        if let error = simulateError {
            throw error
        }
        isRunning = true
    }
    
    func simulateStop() {
        isRunning = false
    }
    
    func simulateAudioInput(level: Float) {
        mockInputLevel = level
    }
}

class MockPermissionManager {
    var speechPermissionGranted = false
    var microphonePermissionGranted = false
    var speechRecognitionAvailable = true
    
    func simulatePermissionRequest(
        speech: Bool,
        microphone: Bool,
        completion: @escaping (Bool, Bool) -> Void
    ) {
        // Simulate permission request delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.speechPermissionGranted = speech
            self.microphonePermissionGranted = microphone
            completion(speech, microphone)
        }
    }
    
    func reset() {
        speechPermissionGranted = false
        microphonePermissionGranted = false
        speechRecognitionAvailable = true
    }
}

// MARK: - Test Result Documentation

class TestResultCollector {
    static let shared = TestResultCollector()
    
    private var testResults: [TestResult] = []
    
    struct TestResult {
        let testName: String
        let passed: Bool
        let executionTime: TimeInterval
        let details: String?
        let timestamp: Date
    }
    
    func recordResult(
        testName: String,
        passed: Bool,
        executionTime: TimeInterval = 0,
        details: String? = nil
    ) {
        let result = TestResult(
            testName: testName,
            passed: passed,
            executionTime: executionTime,
            details: details,
            timestamp: Date()
        )
        testResults.append(result)
    }
    
    func generateSummaryReport() -> String {
        let totalTests = testResults.count
        let passedTests = testResults.filter { $0.passed }.count
        let failedTests = totalTests - passedTests
        let passRate = totalTests > 0 ? Double(passedTests) / Double(totalTests) * 100 : 0
        
        var report = """
        
        📊 Voice Recording Test Suite Summary Report
        ==========================================
        
        Total Tests: \(totalTests)
        Passed: \(passedTests) ✅
        Failed: \(failedTests) ❌
        Pass Rate: \(String(format: "%.1f", passRate))%
        
        Test Categories:
        """
        
        let categories = [
            "VoiceRecording": testResults.filter { $0.testName.contains("VoiceRecording") },
            "Permission": testResults.filter { $0.testName.contains("Permission") },
            "FloatingButton": testResults.filter { $0.testName.contains("FloatingButton") },
            "SpeechRecognition": testResults.filter { $0.testName.contains("SpeechRecognition") }
        ]
        
        for (category, tests) in categories {
            let categoryPassed = tests.filter { $0.passed }.count
            let categoryTotal = tests.count
            let categoryRate = categoryTotal > 0 ? Double(categoryPassed) / Double(categoryTotal) * 100 : 0
            
            report += "\n- \(category): \(categoryPassed)/\(categoryTotal) (\(String(format: "%.1f", categoryRate))%)"
        }
        
        if failedTests > 0 {
            report += "\n\nFailed Tests:"
            let failed = testResults.filter { !$0.passed }
            for test in failed {
                report += "\n❌ \(test.testName)"
                if let details = test.details {
                    report += " - \(details)"
                }
            }
        }
        
        report += "\n\nGenerated: \(Date())\n"
        
        return report
    }
    
    func reset() {
        testResults.removeAll()
    }
}

// MARK: - Test Suite Base Class

class VoiceRecordingTestBase: XCTestCase {
    
    var mockSpeechRecognizer: MockSpeechRecognizer!
    var mockAudioEngine: MockAudioEngine!
    var mockPermissionManager: MockPermissionManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Setup test environment
        TestSuiteConfiguration.setupTestEnvironment()
        
        // Initialize mock objects
        mockSpeechRecognizer = MockSpeechRecognizer()
        mockAudioEngine = MockAudioEngine()
        mockPermissionManager = MockPermissionManager()
        
        // Reset test result collector for each test class
        TestResultCollector.shared.reset()
        
        print("🧪 Test setup completed for \(String(describing: type(of: self)))")
    }
    
    override func tearDownWithError() throws {
        // Generate test report
        let report = TestResultCollector.shared.generateSummaryReport()
        print(report)
        
        // Cleanup
        TestSuiteConfiguration.tearDownTestEnvironment()
        
        mockSpeechRecognizer = nil
        mockAudioEngine = nil
        mockPermissionManager = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - Common Test Utilities
    
    func recordTestResult(
        _ result: Bool,
        executionTime: TimeInterval = 0,
        details: String? = nil,
        function: String = #function
    ) {
        TestResultCollector.shared.recordResult(
            testName: "\(String(describing: type(of: self))).\(function)",
            passed: result,
            executionTime: executionTime,
            details: details
        )
    }
    
    func assertWithRecording<T: Equatable>(
        _ expression: T,
        equals expected: T,
        details: String? = nil,
        function: String = #function
    ) {
        let result = expression == expected
        XCTAssertEqual(expression, expected, details ?? "")
        recordTestResult(result, details: details, function: function)
    }
    
    func assertTrueWithRecording(
        _ expression: Bool,
        details: String? = nil,
        function: String = #function
    ) {
        XCTAssertTrue(expression, details ?? "")
        recordTestResult(expression, details: details, function: function)
    }
}

// MARK: - Test Documentation

/**
 * # Voice Recording Test Suite Documentation
 *
 * This comprehensive test suite covers all aspects of the voice recording and permission
 * management features implemented in the Just Spent app.
 *
 * ## Test Coverage Overview
 *
 * ### 1. VoiceRecordingTests.swift
 * - ✅ Auto-stop functionality with silence detection
 * - ✅ Speech recognition state management
 * - ✅ Voice input processing and data extraction
 * - ✅ Error handling for speech recognition failures
 * - ✅ Performance benchmarks for voice processing
 *
 * ### 2. PermissionManagementTests.swift
 * - ✅ Speech and microphone permission state handling
 * - ✅ Permission request flow and callbacks
 * - ✅ App lifecycle integration (launch, foreground)
 * - ✅ Settings app integration and return handling
 * - ✅ Permission alert content and user guidance
 *
 * ### 3. FloatingActionButtonUITests.swift
 * - ✅ Button visibility in all app states
 * - ✅ Positioning and layout verification
 * - ✅ Recording state transitions and visual feedback
 * - ✅ Auto-stop indicator behavior
 * - ✅ Permission-dependent button states
 * - ✅ Accessibility compliance
 *
 * ### 4. SpeechRecognitionEdgeCaseTests.swift
 * - ✅ Ambiguous amount and currency recognition
 * - ✅ Multi-language and mixed input handling
 * - ✅ Unusual phrasing and slang expressions
 * - ✅ Category ambiguity resolution
 * - ✅ Extreme values and edge cases
 * - ✅ Performance with large inputs
 * - ✅ Real-world speech recognition errors
 *
 * ## Running the Tests
 *
 * ### Unit Tests
 * ```bash
 * xcodebuild test -scheme JustSpent -destination 'platform=iOS Simulator,name=iPhone 14'
 * ```
 *
 * ### UI Tests
 * ```bash
 * xcodebuild test -scheme JustSpentUITests -destination 'platform=iOS Simulator,name=iPhone 14'
 * ```
 *
 * ### Specific Test Classes
 * ```bash
 * xcodebuild test -scheme JustSpent -destination 'platform=iOS Simulator,name=iPhone 14' -only-testing:JustSpentTests/VoiceRecordingTests
 * ```
 *
 * ## Performance Benchmarks
 *
 * - Voice processing: < 100ms
 * - Silence detection: < 10ms
 * - UI updates: < 16ms (60fps)
 * - Permission checks: < 500ms
 *
 * ## Test Environment Requirements
 *
 * - iOS 15.0+ simulator or device
 * - Microphone access (for device testing)
 * - Network connectivity (for speech recognition)
 * - Sufficient storage for test data
 *
 * ## Continuous Integration
 *
 * These tests are designed to run in CI environments with the following considerations:
 * - Mock objects for hardware dependencies
 * - Configurable timeouts for network operations
 * - Automated test result reporting
 * - Performance regression detection
 */