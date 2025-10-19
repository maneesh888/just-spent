import Foundation
import SwiftUI
import Speech
import AVFoundation

/**
 * Auto-Recording Coordinator
 *
 * Orchestrates automatic voice recording when app opens or returns to foreground.
 * Works in conjunction with AppLifecycleManager to ensure proper conditions.
 *
 * Responsibilities:
 * - Verify permissions before auto-recording
 * - Delay recording to allow UI to settle (500ms)
 * - Prevent duplicate recording sessions
 * - Trigger voice recording through ContentView binding
 *
 * Architecture Pattern: Coordinator Pattern
 * - Coordinates between lifecycle, permissions, and recording systems
 * - Single Responsibility: Only handles auto-recording orchestration
 * - Dependency Injection: Receives dependencies through init
 */
@MainActor
class AutoRecordingCoordinator: ObservableObject {

    // MARK: - Published State

    /// Request to start recording (observed by ContentView)
    @Published var shouldStartRecording: Bool = false

    // MARK: - Dependencies

    private let lifecycleManager: AppLifecycleManager

    // MARK: - Configuration

    /// Delay before starting auto-recording (immediate for better UX)
    private let autoRecordingDelay: TimeInterval = 0.0

    // MARK: - Private State

    private var autoRecordingTask: Task<Void, Never>?
    private var isProcessingAutoRecord = false

    // MARK: - Lifecycle

    init(lifecycleManager: AppLifecycleManager) {
        self.lifecycleManager = lifecycleManager

        #if DEBUG
        print("🎤 AutoRecordingCoordinator initialized")
        #endif
    }

    deinit {
        autoRecordingTask?.cancel()
    }

    // MARK: - Public Interface

    /**
     * Attempt to trigger auto-recording
     * Called when app becomes active or returns to foreground
     *
     * - Parameter isRecordingActive: Current recording state from ContentView
     * - Parameter permissions: Current permission state
     */
    func triggerAutoRecordingIfNeeded(
        isRecordingActive: Bool,
        speechPermissionGranted: Bool,
        microphonePermissionGranted: Bool,
        speechRecognitionAvailable: Bool
    ) {
        #if DEBUG
        print("🎤 AutoRecordingCoordinator.triggerAutoRecordingIfNeeded() called")
        print("   - isProcessingAutoRecord: \(isProcessingAutoRecord)")
        print("   - isRecordingActive: \(isRecordingActive)")
        print("   - speechRecognitionAvailable: \(speechRecognitionAvailable)")
        print("   - speechPermissionGranted: \(speechPermissionGranted)")
        print("   - microphonePermissionGranted: \(microphonePermissionGranted)")
        #endif

        // Guard against concurrent auto-recording attempts
        guard !isProcessingAutoRecord else {
            #if DEBUG
            print("⏸️ Auto-recording already processing, skipping")
            #endif
            return
        }

        // Check lifecycle conditions
        guard lifecycleManager.shouldTriggerAutoRecording() else {
            // shouldTriggerAutoRecording() logs reasons internally
            return
        }

        // Check if already recording (manual or previous auto)
        guard !isRecordingActive else {
            #if DEBUG
            print("⏸️ Auto-recording skipped: already recording")
            #endif
            return
        }

        // Verify speech recognition is available
        guard speechRecognitionAvailable else {
            #if DEBUG
            print("⏸️ Auto-recording skipped: speech recognition unavailable")
            #endif
            return
        }

        // Verify all permissions granted
        guard speechPermissionGranted && microphonePermissionGranted else {
            #if DEBUG
            print("⏸️ Auto-recording skipped: permissions not granted")
            if !speechPermissionGranted { print("   - Speech recognition permission missing") }
            if !microphonePermissionGranted { print("   - Microphone permission missing") }
            #endif
            return
        }

        #if DEBUG
        print("✅ All auto-recording conditions met - starting with delay")
        #endif

        // All conditions met - trigger auto-recording with delay
        startAutoRecordingWithDelay()
    }

    /**
     * Cancel any pending auto-recording
     * Call this if user manually triggers recording or app goes to background
     */
    func cancelPendingAutoRecording() {
        autoRecordingTask?.cancel()
        autoRecordingTask = nil
        isProcessingAutoRecord = false

        #if DEBUG
        print("🚫 Pending auto-recording cancelled")
        #endif
    }

    /**
     * Notify coordinator that auto-recording has completed
     * Updates lifecycle manager state
     */
    func autoRecordingDidComplete() {
        lifecycleManager.stopAutoRecording()
        isProcessingAutoRecord = false

        #if DEBUG
        print("✅ Auto-recording completed")
        #endif
    }

    // MARK: - Private Methods

    private func startAutoRecordingWithDelay() {
        // Cancel any existing task
        autoRecordingTask?.cancel()

        isProcessingAutoRecord = true
        lifecycleManager.startAutoRecording()

        #if DEBUG
        print("⏳ Auto-recording scheduled (delay: \(autoRecordingDelay)s)")
        #endif

        autoRecordingTask = Task { @MainActor in
            do {
                // Wait for UI to settle
                try await Task.sleep(nanoseconds: UInt64(autoRecordingDelay * 1_000_000_000))

                // Check if still valid (not cancelled, app still active)
                guard !Task.isCancelled,
                      lifecycleManager.appState == .active else {
                    #if DEBUG
                    print("⏸️ Auto-recording cancelled before execution")
                    #endif
                    isProcessingAutoRecord = false
                    lifecycleManager.stopAutoRecording()
                    return
                }

                // Trigger recording via published property
                #if DEBUG
                print("🎙️ Triggering auto-recording now")
                #endif

                shouldStartRecording = true

                // Reset flag after brief delay to allow observation
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                shouldStartRecording = false

                // Note: autoRecordingDidComplete() will be called when recording finishes

            } catch {
                // Task was cancelled
                #if DEBUG
                print("⏸️ Auto-recording task cancelled")
                #endif
                isProcessingAutoRecord = false
                lifecycleManager.stopAutoRecording()
            }
        }
    }

    /**
     * Manual trigger for testing
     */
    #if DEBUG
    func forceAutoRecording() {
        shouldStartRecording = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            shouldStartRecording = false
        }
    }
    #endif
}

// MARK: - Permission State Helper

/**
 * Permission state check result
 * Used to determine if auto-recording should proceed
 */
struct PermissionState {
    let speechRecognitionGranted: Bool
    let microphoneGranted: Bool
    let speechRecognitionAvailable: Bool

    var allGranted: Bool {
        speechRecognitionGranted && microphoneGranted && speechRecognitionAvailable
    }

    static var current: PermissionState {
        let speechAuthStatus = SFSpeechRecognizer.authorizationStatus()
        let micPermission = AVAudioSession.sharedInstance().recordPermission
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

        return PermissionState(
            speechRecognitionGranted: speechAuthStatus == .authorized,
            microphoneGranted: micPermission == .granted,
            speechRecognitionAvailable: recognizer?.isAvailable ?? false
        )
    }
}
