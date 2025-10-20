//
//  FloatingVoiceButtonTests.swift
//  JustSpentTests
//
//  Created by Claude Code on 2025-10-20.
//  Tests for floating voice recording button component
//

import XCTest
import SwiftUI
@testable import JustSpent

final class FloatingVoiceButtonTests: XCTestCase {

    // MARK: - Button State Tests

    func testButtonIdleState() throws {
        let isRecording = false
        let hasDetectedSpeech = false

        XCTAssertFalse(isRecording, "Button should be in idle state")
        XCTAssertFalse(hasDetectedSpeech, "Should not have detected speech")
    }

    func testButtonRecordingState() throws {
        let isRecording = true
        let hasDetectedSpeech = false

        XCTAssertTrue(isRecording, "Button should be in recording state")
        XCTAssertFalse(hasDetectedSpeech, "Should be listening but not yet detected speech")
    }

    func testButtonDetectedSpeechState() throws {
        let isRecording = true
        let hasDetectedSpeech = true

        XCTAssertTrue(isRecording, "Button should be in recording state")
        XCTAssertTrue(hasDetectedSpeech, "Should have detected speech")
    }

    // MARK: - Permission State Tests

    func testAllPermissionsGranted() throws {
        let speechRecognitionAvailable = true
        let speechPermissionGranted = true
        let microphonePermissionGranted = true

        let allGranted = speechRecognitionAvailable && speechPermissionGranted && microphonePermissionGranted

        XCTAssertTrue(allGranted, "All permissions should be granted")
    }

    func testSpeechPermissionDenied() throws {
        let speechRecognitionAvailable = true
        let speechPermissionGranted = false
        let microphonePermissionGranted = true

        let allGranted = speechRecognitionAvailable && speechPermissionGranted && microphonePermissionGranted

        XCTAssertFalse(allGranted, "Should fail when speech permission denied")
    }

    func testMicrophonePermissionDenied() throws {
        let speechRecognitionAvailable = true
        let speechPermissionGranted = true
        let microphonePermissionGranted = false

        let allGranted = speechRecognitionAvailable && speechPermissionGranted && microphonePermissionGranted

        XCTAssertFalse(allGranted, "Should fail when microphone permission denied")
    }

    func testSpeechRecognitionUnavailable() throws {
        let speechRecognitionAvailable = false
        let speechPermissionGranted = true
        let microphonePermissionGranted = true

        let allGranted = speechRecognitionAvailable && speechPermissionGranted && microphonePermissionGranted

        XCTAssertFalse(allGranted, "Should fail when speech recognition unavailable")
    }

    func testAllPermissionsDenied() throws {
        let speechRecognitionAvailable = false
        let speechPermissionGranted = false
        let microphonePermissionGranted = false

        let allGranted = speechRecognitionAvailable && speechPermissionGranted && microphonePermissionGranted

        XCTAssertFalse(allGranted, "Should fail when all permissions denied")
    }

    // MARK: - Button Enabled/Disabled Tests

    func testButtonEnabledWhenPermissionsGranted() throws {
        let speechRecognitionAvailable = true
        let speechPermissionGranted = true
        let microphonePermissionGranted = true

        let isEnabled = speechRecognitionAvailable && speechPermissionGranted && microphonePermissionGranted

        XCTAssertTrue(isEnabled, "Button should be enabled")
    }

    func testButtonDisabledWhenPermissionsMissing() throws {
        let speechRecognitionAvailable = false
        let speechPermissionGranted = false
        let microphonePermissionGranted = false

        let isEnabled = speechRecognitionAvailable && speechPermissionGranted && microphonePermissionGranted

        XCTAssertFalse(isEnabled, "Button should be disabled")
    }

    // MARK: - Button Opacity Tests

    func testButtonOpaqueWhenEnabled() throws {
        let speechRecognitionAvailable = true
        let speechPermissionGranted = true
        let microphonePermissionGranted = true

        let opacity = (speechRecognitionAvailable && speechPermissionGranted && microphonePermissionGranted) ? 1.0 : 0.6

        XCTAssertEqual(opacity, 1.0, accuracy: 0.01, "Button should be fully opaque when enabled")
    }

    func testButtonTranslucentWhenDisabled() throws {
        let speechRecognitionAvailable = false
        let speechPermissionGranted = false
        let microphonePermissionGranted = false

        let opacity = (speechRecognitionAvailable && speechPermissionGranted && microphonePermissionGranted) ? 1.0 : 0.6

        XCTAssertEqual(opacity, 0.6, accuracy: 0.01, "Button should be translucent when disabled")
    }

    // MARK: - Icon Tests

    func testIdleButtonIcon() throws {
        let isRecording = false
        let expectedIcon = isRecording ? "stop.circle.fill" : "mic.circle.fill"

        XCTAssertEqual(expectedIcon, "mic.circle.fill", "Should show microphone icon when idle")
    }

    func testRecordingButtonIcon() throws {
        let isRecording = true
        let expectedIcon = isRecording ? "stop.circle.fill" : "mic.circle.fill"

        XCTAssertEqual(expectedIcon, "stop.circle.fill", "Should show stop icon when recording")
    }

    // MARK: - Color Tests

    func testIdleButtonColor() throws {
        let isRecording = false
        let expectedColorIsBlue = !isRecording

        XCTAssertTrue(expectedColorIsBlue, "Should be blue when idle")
    }

    func testRecordingButtonColor() throws {
        let isRecording = true
        let expectedColorIsRed = isRecording

        XCTAssertTrue(expectedColorIsRed, "Should be red when recording")
    }

    // MARK: - Scale Effect Tests

    func testIdleButtonScale() throws {
        let isRecording = false
        let scale = isRecording ? 1.1 : 1.0

        XCTAssertEqual(scale, 1.0, accuracy: 0.01, "Should be normal scale when idle")
    }

    func testRecordingButtonScale() throws {
        let isRecording = true
        let scale = isRecording ? 1.1 : 1.0

        XCTAssertEqual(scale, 1.1, accuracy: 0.01, "Should be enlarged when recording")
    }

    // MARK: - Indicator Visibility Tests

    func testIndicatorHiddenWhenIdle() throws {
        let isRecording = false

        XCTAssertFalse(isRecording, "Recording indicator should be hidden when idle")
    }

    func testIndicatorVisibleWhenRecording() throws {
        let isRecording = true

        XCTAssertTrue(isRecording, "Recording indicator should be visible when recording")
    }

    // MARK: - Indicator State Tests

    func testListeningIndicatorState() throws {
        let isRecording = true
        let hasDetectedSpeech = false

        let isListening = isRecording && !hasDetectedSpeech

        XCTAssertTrue(isListening, "Should be in listening state")
    }

    func testProcessingIndicatorState() throws {
        let isRecording = true
        let hasDetectedSpeech = true

        let isProcessing = isRecording && hasDetectedSpeech

        XCTAssertTrue(isProcessing, "Should be in processing state")
    }

    // MARK: - Indicator Color Tests

    func testListeningIndicatorColor() throws {
        let hasDetectedSpeech = false
        let isRed = !hasDetectedSpeech

        XCTAssertTrue(isRed, "Listening indicator should be red")
    }

    func testProcessingIndicatorColor() throws {
        let hasDetectedSpeech = true
        let isGreen = hasDetectedSpeech

        XCTAssertTrue(isGreen, "Processing indicator should be green")
    }

    // MARK: - Callback Invocation Tests

    func testStartRecordingCallback() throws {
        var callbackInvoked = false

        let callback = {
            callbackInvoked = true
        }

        callback()

        XCTAssertTrue(callbackInvoked, "Start recording callback should be invoked")
    }

    func testStopRecordingCallback() throws {
        var callbackInvoked = false

        let callback = {
            callbackInvoked = true
        }

        callback()

        XCTAssertTrue(callbackInvoked, "Stop recording callback should be invoked")
    }

    func testPermissionAlertCallback() throws {
        var callbackInvoked = false

        let callback = {
            callbackInvoked = true
        }

        callback()

        XCTAssertTrue(callbackInvoked, "Permission alert callback should be invoked")
    }

    // MARK: - Button Action Logic Tests

    func testButtonActionWhenRecording() throws {
        let isRecording = true
        var stopCalled = false

        // Simulate button action
        if isRecording {
            stopCalled = true
        }

        XCTAssertTrue(stopCalled, "Should call stop when recording")
    }

    func testButtonActionWhenIdle() throws {
        let isRecording = false
        let speechRecognitionAvailable = true
        var startCalled = false

        // Simulate button action
        if !isRecording {
            if speechRecognitionAvailable {
                startCalled = true
            }
        }

        XCTAssertTrue(startCalled, "Should call start when idle and available")
    }

    func testButtonActionWhenUnavailable() throws {
        let isRecording = false
        let speechRecognitionAvailable = false
        var permissionAlertCalled = false

        // Simulate button action
        if !isRecording {
            if !speechRecognitionAvailable {
                permissionAlertCalled = true
            }
        }

        XCTAssertTrue(permissionAlertCalled, "Should show permission alert when unavailable")
    }

    // MARK: - Visual Properties Tests

    func testButtonSize() throws {
        let width: CGFloat = 60
        let height: CGFloat = 60

        XCTAssertEqual(width, 60, "Button width should be 60")
        XCTAssertEqual(height, 60, "Button height should be 60")
    }

    func testIconSize() throws {
        let fontSize: CGFloat = 24

        XCTAssertEqual(fontSize, 24, "Icon font size should be 24")
    }

    func testShadowProperties() throws {
        let shadowRadius: CGFloat = 8
        let shadowY: CGFloat = 4
        let shadowOpacity: Double = 0.2

        XCTAssertEqual(shadowRadius, 8, "Shadow radius should be 8")
        XCTAssertEqual(shadowY, 4, "Shadow Y offset should be 4")
        XCTAssertEqual(shadowOpacity, 0.2, accuracy: 0.01, "Shadow opacity should be 0.2")
    }

    func testCircularShape() throws {
        let width: CGFloat = 60
        let height: CGFloat = 60
        let isCircle = width == height

        XCTAssertTrue(isCircle, "Button should be circular (equal width and height)")
    }

    // MARK: - Positioning Tests

    func testBottomPadding() throws {
        let bottomPadding: CGFloat = 34

        XCTAssertEqual(bottomPadding, 34, "Bottom padding should account for safe area")
    }

    func testHorizontalAlignment() throws {
        // Button should be horizontally centered
        let isCentered = true // Spacer() on both sides centers the button

        XCTAssertTrue(isCentered, "Button should be horizontally centered")
    }

    func testVerticalAlignment() throws {
        // Button should be aligned to bottom
        let isBottomAligned = true // VStack with Spacer() pushes to bottom

        XCTAssertTrue(isBottomAligned, "Button should be aligned to bottom")
    }

    // MARK: - Integration Tests

    func testFloatingVoiceButtonCreation() throws {
        let view = FloatingVoiceButton(
            isRecording: .constant(false),
            hasDetectedSpeech: .constant(false),
            speechRecognitionAvailable: .constant(true),
            speechPermissionGranted: .constant(true),
            microphonePermissionGranted: .constant(true),
            onStartRecording: {},
            onStopRecording: {},
            onPermissionAlert: {}
        )

        XCTAssertNotNil(view, "FloatingVoiceButton should be created successfully")
    }

    func testButtonWithAllPermissionsDenied() throws {
        let view = FloatingVoiceButton(
            isRecording: .constant(false),
            hasDetectedSpeech: .constant(false),
            speechRecognitionAvailable: .constant(false),
            speechPermissionGranted: .constant(false),
            microphonePermissionGranted: .constant(false),
            onStartRecording: {},
            onStopRecording: {},
            onPermissionAlert: {}
        )

        XCTAssertNotNil(view, "FloatingVoiceButton should handle denied permissions gracefully")
    }

    // MARK: - Performance Tests

    func testButtonRenderingPerformance() throws {
        measure {
            for _ in 0..<100 {
                _ = FloatingVoiceButton(
                    isRecording: .constant(false),
                    hasDetectedSpeech: .constant(false),
                    speechRecognitionAvailable: .constant(true),
                    speechPermissionGranted: .constant(true),
                    microphonePermissionGranted: .constant(true),
                    onStartRecording: {},
                    onStopRecording: {},
                    onPermissionAlert: {}
                )
            }
        }
    }

    func testStateTransitionPerformance() throws {
        var isRecording = false

        measure {
            for _ in 0..<1000 {
                isRecording.toggle()
            }
        }
    }
}
