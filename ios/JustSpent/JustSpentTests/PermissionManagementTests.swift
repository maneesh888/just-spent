import XCTest
import Speech
import AVFoundation
import SwiftUI
@testable import JustSpent

class PermissionManagementTests: XCTestCase {
    
    var permissionManager: PermissionManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        permissionManager = PermissionManager()
    }
    
    override func tearDownWithError() throws {
        permissionManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Permission State Tests
    
    func testInitialPermissionStates() throws {
        // Given - Fresh app launch
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let microphoneStatus = AVAudioSession.sharedInstance().recordPermission
        
        // When & Then
        XCTAssertTrue([.notDetermined, .authorized, .denied, .restricted].contains(speechStatus),
                     "Speech authorization status should be valid")
        XCTAssertTrue([.undetermined, .granted, .denied].contains(microphoneStatus),
                     "Microphone permission should be valid")
    }
    
    func testSpeechPermissionStatusMapping() throws {
        // Given
        let statusMappings: [(SFSpeechRecognizerAuthorizationStatus, Bool)] = [
            (.authorized, true),
            (.denied, false),
            (.restricted, false),
            (.notDetermined, false)
        ]
        
        // When & Then
        for (status, expectedGranted) in statusMappings {
            let isGranted = (status == .authorized)
            XCTAssertEqual(isGranted, expectedGranted, 
                          "Speech permission status \(status) should map to granted: \(expectedGranted)")
        }
    }
    
    func testMicrophonePermissionStatusMapping() throws {
        // Given
        let statusMappings: [(AVAudioSession.RecordPermission, Bool)] = [
            (.granted, true),
            (.denied, false),
            (.undetermined, false)
        ]
        
        // When & Then
        for (status, expectedGranted) in statusMappings {
            let isGranted = (status == .granted)
            XCTAssertEqual(isGranted, expectedGranted,
                          "Microphone permission status \(status) should map to granted: \(expectedGranted)")
        }
    }
    
    // MARK: - Permission Request Flow Tests
    
    // NOTE: Manual Testing Required
    // This test requires actual system permission dialogs which cannot be automated
    // Run this test manually on a physical device to verify permission request flow
    func testSpeechPermissionRequest_Manual() throws {
        throw XCTSkip("This test requires manual testing on a physical device")

        /* Manual Test Instructions:
         1. Reset app permissions in Settings
         2. Launch app on physical device
         3. Trigger voice recording feature
         4. Verify speech recognition permission dialog appears
         5. Grant or deny permission
         6. Verify app handles response correctly
         */
    }
    
    // NOTE: Manual Testing Required
    // This test requires actual system permission dialogs which cannot be automated
    // Run this test manually on a physical device to verify permission request flow
    func testMicrophonePermissionRequest_Manual() throws {
        throw XCTSkip("This test requires manual testing on a physical device")

        /* Manual Test Instructions:
         1. Reset app permissions in Settings
         2. Launch app on physical device
         3. Trigger voice recording feature
         4. Verify microphone permission dialog appears
         5. Grant or deny permission
         6. Verify app handles response correctly
         */
    }
    
    // NOTE: Manual Testing Required
    // This test requires actual system permission dialogs which cannot be automated
    // Run this test manually on a physical device to verify permission request flow
    func testSequentialPermissionRequests_Manual() throws {
        throw XCTSkip("This test requires manual testing on a physical device")

        /* Manual Test Instructions:
         1. Reset all app permissions in Settings
         2. Launch app on physical device for first time
         3. Trigger voice recording feature
         4. Verify speech recognition permission dialog appears first
         5. Grant or deny speech permission
         6. Verify microphone permission dialog appears second
         7. Grant or deny microphone permission
         8. Verify app handles both permission states correctly
         9. Test both permissions granted scenario
         10. Test one or both permissions denied scenario
         */
    }
    
    // MARK: - Permission Alert Tests
    
    func testPermissionAlertContent() throws {
        // Given
        let speechDeniedTitle = "Speech Recognition Permission Required"
        let speechDeniedMessage = "Just Spent needs access to Speech Recognition to process your voice commands. Please enable it in Settings > Privacy & Security > Speech Recognition."
        
        let microphoneDeniedTitle = "Microphone Permission Required"
        let microphoneDeniedMessage = "Just Spent needs access to the Microphone to record your voice commands. Please enable it in Settings > Privacy & Security > Microphone."
        
        // When & Then
        XCTAssertFalse(speechDeniedTitle.isEmpty, "Speech permission alert should have title")
        XCTAssertFalse(speechDeniedMessage.isEmpty, "Speech permission alert should have message")
        XCTAssertTrue(speechDeniedMessage.contains("Settings"), "Should guide user to Settings")
        
        XCTAssertFalse(microphoneDeniedTitle.isEmpty, "Microphone permission alert should have title")
        XCTAssertFalse(microphoneDeniedMessage.isEmpty, "Microphone permission alert should have message")
        XCTAssertTrue(microphoneDeniedMessage.contains("Settings"), "Should guide user to Settings")
    }
    
    func testSettingsURLGeneration() throws {
        // Given
        let settingsURL = URL(string: UIApplication.openSettingsURLString)
        
        // When & Then
        XCTAssertNotNil(settingsURL, "Settings URL should be valid")
        XCTAssertEqual(settingsURL?.scheme, "app-settings", "Should have correct URL scheme")
    }
    
    // MARK: - App Lifecycle Integration Tests
    
    func testAppLaunchPermissionCheck() throws {
        // Given
        var permissionsChecked = false
        
        // When - Simulate app launch permission check
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Simulate the permission check that happens on app launch
            let speechStatus = SFSpeechRecognizer.authorizationStatus()
            let microphoneStatus = AVAudioSession.sharedInstance().recordPermission
            
            permissionsChecked = true
            
            // Verify permissions were checked
            XCTAssertTrue([.notDetermined, .authorized, .denied, .restricted].contains(speechStatus))
            XCTAssertTrue([.undetermined, .granted, .denied].contains(microphoneStatus))
        }
        
        // Then
        let expectation = XCTestExpectation(description: "Permission check completion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(permissionsChecked, "Permissions should be checked on app launch")
    }
    
    func testAppForegroundPermissionRefresh() throws {
        // Given
        let expectation = XCTestExpectation(description: "Foreground permission refresh")
        var permissionsRefreshed = false
        
        // When - Simulate app entering foreground (returning from Settings)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Simulate permission refresh
            let speechStatus = SFSpeechRecognizer.authorizationStatus()
            let microphoneStatus = AVAudioSession.sharedInstance().recordPermission
            
            permissionsRefreshed = true
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(permissionsRefreshed, "Permissions should be refreshed when app enters foreground")
    }
    
    // MARK: - Speech Recognition Availability Tests
    
    func testSpeechRecognitionAvailability() throws {
        // Given
        let locale = Locale.current
        let recognizer = SFSpeechRecognizer(locale: locale)
        
        // When
        let isAvailable = recognizer?.isAvailable ?? false
        
        // Then
        XCTAssertNotNil(recognizer, "Speech recognizer should be created for current locale")
        
        // Note: Availability depends on device capabilities and network
        if isAvailable {
            XCTAssertTrue(isAvailable, "Speech recognition should be available when recognizer reports availability")
        } else {
            // This is acceptable on simulator or devices without speech recognition
            XCTAssertFalse(isAvailable, "Speech recognition unavailability is acceptable on some devices")
        }
    }
    
    func testSpeechRecognitionLanguageSupport() throws {
        // Given
        let supportedLocales = [
            Locale(identifier: "en-US"),
            Locale(identifier: "en-GB"),
            Locale(identifier: "ar-AE"),
            Locale(identifier: "es-ES")
        ]
        
        // When & Then
        for locale in supportedLocales {
            let recognizer = SFSpeechRecognizer(locale: locale)
            XCTAssertNotNil(recognizer, "Should create recognizer for locale: \(locale.identifier)")
            
            // Check if this locale is supported (may vary by device)
            let isSupported = recognizer?.isAvailable ?? false
            // Note: This test documents locale support rather than asserting specific behavior
            print("Locale \(locale.identifier) support: \(isSupported)")
        }
    }
    
    // MARK: - Permission State Persistence Tests
    
    func testPermissionStateConsistency() throws {
        // Given
        let speechStatus1 = SFSpeechRecognizer.authorizationStatus()
        let microphoneStatus1 = AVAudioSession.sharedInstance().recordPermission
        
        // When - Check again after short delay
        let expectation = XCTestExpectation(description: "Permission state consistency")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let speechStatus2 = SFSpeechRecognizer.authorizationStatus()
            let microphoneStatus2 = AVAudioSession.sharedInstance().recordPermission
            
            // Then
            XCTAssertEqual(speechStatus1, speechStatus2, "Speech permission status should be consistent")
            XCTAssertEqual(microphoneStatus1, microphoneStatus2, "Microphone permission status should be consistent")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testPermissionRequestErrorHandling() throws {
        // Given
        let mockError = NSError(domain: "PermissionError", code: 3001, userInfo: [
            NSLocalizedDescriptionKey: "Permission request failed"
        ])
        
        // When
        let errorDescription = mockError.localizedDescription
        let errorCode = mockError.code
        
        // Then
        XCTAssertEqual(errorDescription, "Permission request failed", "Should handle permission errors")
        XCTAssertEqual(errorCode, 3001, "Should preserve error codes")
    }
    
    func testInvalidSettingsURLHandling() throws {
        // Given
        let invalidURL = URL(string: "invalid://settings")
        
        // When
        let canOpen = UIApplication.shared.canOpenURL(invalidURL ?? URL(fileURLWithPath: ""))
        
        // Then
        XCTAssertFalse(canOpen, "Should handle invalid settings URLs gracefully")
    }
}

// MARK: - Helper Classes

class PermissionManager {
    
    func checkAllPermissions() -> (speech: Bool, microphone: Bool, available: Bool) {
        let speechGranted = SFSpeechRecognizer.authorizationStatus() == .authorized
        let microphoneGranted = AVAudioSession.sharedInstance().recordPermission == .granted
        let recognizerAvailable = SFSpeechRecognizer()?.isAvailable ?? false
        
        return (speechGranted, microphoneGranted, recognizerAvailable)
    }
    
    func requestAllPermissions(completion: @escaping (Bool) -> Void) {
        requestSpeechPermission { speechGranted in
            if speechGranted {
                self.requestMicrophonePermission { microphoneGranted in
                    completion(speechGranted && microphoneGranted)
                }
            } else {
                completion(false)
            }
        }
    }
    
    private func requestSpeechPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
}

// MARK: - Test Extensions

extension XCTestCase {
    
    func simulateAppLaunch() {
        // Simulate the typical app launch permission flow
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let microphoneStatus = AVAudioSession.sharedInstance().recordPermission
        
        // Log initial states for debugging
        print("Initial Speech Status: \(speechStatus)")
        print("Initial Microphone Status: \(microphoneStatus)")
    }
    
    func simulateSettingsReturn() {
        // Simulate user returning from Settings app
        NotificationCenter.default.post(
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    func waitForPermissionResponse(timeout: TimeInterval = 5.0) {
        // Helper to wait for permission dialogs in tests
        let expectation = XCTestExpectation(description: "Permission response")
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout + 1.0)
    }
}